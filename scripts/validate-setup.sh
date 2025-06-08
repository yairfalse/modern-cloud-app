#!/bin/bash
set -euo pipefail

# Validation script for ModernBlog development environment

VALIDATION_PASSED=0
VALIDATION_FAILED=0

validate_tool() {
    local tool_name="$1"
    local command="$2"
    local version_flag="${3:---version}"
    
    if command -v "$command" &> /dev/null; then
        local version
        if [[ "$version_flag" == "none" ]]; then
            version="installed"
        else
            version=$($command $version_flag 2>&1 | head -1 || echo "unknown")
        fi
        echo "  ✓ $tool_name: $version"
        VALIDATION_PASSED=$((VALIDATION_PASSED + 1))
    else
        echo "  ✗ $tool_name: not found"
        VALIDATION_FAILED=$((VALIDATION_FAILED + 1))
    fi
}

validate_docker_service() {
    local service_name="$1"
    local port="$2"
    
    if curl -s --max-time 5 "http://localhost:$port" &> /dev/null || \
       nc -z localhost "$port" &> /dev/null; then
        echo "  ✓ $service_name (port $port): running"
        VALIDATION_PASSED=$((VALIDATION_PASSED + 1))
    else
        echo "  ✗ $service_name (port $port): not accessible"
        VALIDATION_FAILED=$((VALIDATION_FAILED + 1))
    fi
}

validate_kubernetes_resource() {
    local resource_type="$1"
    local resource_name="$2"
    local namespace="${3:-default}"
    
    if kubectl get "$resource_type" "$resource_name" -n "$namespace" &> /dev/null; then
        local status=$(kubectl get "$resource_type" "$resource_name" -n "$namespace" -o jsonpath='{.status.phase}' 2>/dev/null || echo "Ready")
        echo "  ✓ $resource_type/$resource_name: $status"
        VALIDATION_PASSED=$((VALIDATION_PASSED + 1))
    else
        echo "  ✗ $resource_type/$resource_name: not found"
        VALIDATION_FAILED=$((VALIDATION_FAILED + 1))
    fi
}

check_required_tools() {
    log_info "Checking required development tools..."
    
    validate_tool "Git" "git"
    validate_tool "Docker" "docker" "--version"
    validate_tool "Docker Compose" "docker-compose" "--version"
    validate_tool "kubectl" "kubectl" "version --client"
    validate_tool "Kind" "kind" "version"
    validate_tool "Helm" "helm" "version --short"
    validate_tool "Skaffold" "skaffold" "version"
    validate_tool "Terraform" "terraform" "version"
    validate_tool "Node.js" "node" "--version"
    validate_tool "npm" "npm" "--version"
    validate_tool "Go" "go" "version"
    
    echo ""
}

check_optional_tools() {
    log_info "Checking optional tools..."
    
    validate_tool "jq" "jq" "--version"
    validate_tool "yq" "yq" "--version"
    validate_tool "k9s" "k9s" "version"
    validate_tool "stern" "stern" "--version"
    validate_tool "kubectx" "kubectx" "--version"
    validate_tool "Lefthook" "lefthook" "version"
    validate_tool "Pre-commit" "pre-commit" "--version"
    
    echo ""
}

check_docker_daemon() {
    log_info "Checking Docker daemon..."
    
    if docker info &> /dev/null; then
        echo "  ✓ Docker daemon: running"
        local docker_version=$(docker version --format '{{.Server.Version}}')
        echo "  ✓ Docker version: $docker_version"
        VALIDATION_PASSED=$((VALIDATION_PASSED + 2))
    else
        echo "  ✗ Docker daemon: not running"
        echo "    Please start Docker Desktop and try again"
        VALIDATION_FAILED=$((VALIDATION_FAILED + 1))
        return 1
    fi
    
    echo ""
}

check_kubernetes_cluster() {
    log_info "Checking Kubernetes cluster..."
    
    # Check if cluster exists
    if kind get clusters 2>/dev/null | grep -q "modernblog-cluster"; then
        echo "  ✓ Kind cluster: modernblog-cluster exists"
        VALIDATION_PASSED=$((VALIDATION_PASSED + 1))
        
        # Check if cluster is accessible
        if kubectl cluster-info --context "kind-modernblog-cluster" &> /dev/null; then
            echo "  ✓ Cluster connectivity: accessible"
            VALIDATION_PASSED=$((VALIDATION_PASSED + 1))
            
            # Check nodes
            local node_count=$(kubectl get nodes --no-headers 2>/dev/null | wc -l)
            echo "  ✓ Cluster nodes: $node_count nodes"
            VALIDATION_PASSED=$((VALIDATION_PASSED + 1))
            
            # Check system pods
            local ready_pods=$(kubectl get pods -n kube-system --no-headers 2>/dev/null | grep -c "Running" || echo 0)
            local total_pods=$(kubectl get pods -n kube-system --no-headers 2>/dev/null | wc -l || echo 0)
            echo "  ✓ System pods: $ready_pods/$total_pods running"
            if [[ $ready_pods -eq $total_pods && $total_pods -gt 0 ]]; then
                VALIDATION_PASSED=$((VALIDATION_PASSED + 1))
            else
                VALIDATION_FAILED=$((VALIDATION_FAILED + 1))
            fi
            
        else
            echo "  ✗ Cluster connectivity: not accessible"
            VALIDATION_FAILED=$((VALIDATION_FAILED + 1))
        fi
    else
        echo "  ✗ Kind cluster: modernblog-cluster not found"
        echo "    Run 'make k8s-create-cluster' to create it"
        VALIDATION_FAILED=$((VALIDATION_FAILED + 1))
    fi
    
    echo ""
}

check_ingress_controller() {
    log_info "Checking ingress controller..."
    
    if kubectl get namespace ingress-nginx &> /dev/null; then
        echo "  ✓ Ingress namespace: exists"
        VALIDATION_PASSED=$((VALIDATION_PASSED + 1))
        
        # Check ingress controller pods
        local ingress_pods=$(kubectl get pods -n ingress-nginx --no-headers 2>/dev/null | grep -c "Running" || echo 0)
        if [[ $ingress_pods -gt 0 ]]; then
            echo "  ✓ Ingress controller: $ingress_pods pods running"
            VALIDATION_PASSED=$((VALIDATION_PASSED + 1))
        else
            echo "  ✗ Ingress controller: no pods running"
            VALIDATION_FAILED=$((VALIDATION_FAILED + 1))
        fi
    else
        echo "  ✗ Ingress namespace: not found"
        VALIDATION_FAILED=$((VALIDATION_FAILED + 1))
    fi
    
    echo ""
}

check_local_registry() {
    log_info "Checking local container registry..."
    
    if docker ps --format "table {{.Names}}" | grep -q "kind-registry"; then
        echo "  ✓ Local registry: running"
        VALIDATION_PASSED=$((VALIDATION_PASSED + 1))
        
        # Check registry accessibility
        if curl -s --max-time 5 http://localhost:5001/v2/ &> /dev/null; then
            echo "  ✓ Registry API: accessible on localhost:5001"
            VALIDATION_PASSED=$((VALIDATION_PASSED + 1))
        else
            echo "  ✗ Registry API: not accessible"
            VALIDATION_FAILED=$((VALIDATION_FAILED + 1))
        fi
    else
        echo "  ✗ Local registry: not running"
        VALIDATION_FAILED=$((VALIDATION_FAILED + 1))
    fi
    
    echo ""
}

check_docker_services() {
    log_info "Checking Docker Compose services..."
    
    # Check if docker-compose file exists
    if [[ -f "${SCRIPT_DIR}/dev/docker-compose.dev.yml" ]]; then
        echo "  ✓ Docker Compose file: exists"
        VALIDATION_PASSED=$((VALIDATION_PASSED + 1))
        
        # Check individual services
        validate_docker_service "PostgreSQL" "5432"
        validate_docker_service "Redis" "6379"
        validate_docker_service "MinIO" "9000"
        validate_docker_service "Prometheus" "9090"
        validate_docker_service "Grafana" "3000"
        validate_docker_service "pgAdmin" "5050"
    else
        echo "  ✗ Docker Compose file: not found"
        VALIDATION_FAILED=$((VALIDATION_FAILED + 1))
    fi
    
    echo ""
}

check_environment_files() {
    log_info "Checking environment configuration..."
    
    local files=(
        ".env"
        ".env.docker"
        "dev/kind-config.yaml"
        "dev/docker-compose.dev.yml"
        "Makefile"
        "Brewfile"
    )
    
    for file in "${files[@]}"; do
        if [[ -f "${SCRIPT_DIR}/$file" ]]; then
            echo "  ✓ $file: exists"
            VALIDATION_PASSED=$((VALIDATION_PASSED + 1))
        else
            echo "  ✗ $file: missing"
            VALIDATION_FAILED=$((VALIDATION_FAILED + 1))
        fi
    done
    
    echo ""
}

check_shell_configuration() {
    log_info "Checking shell configuration..."
    
    # Check shell type
    local shell_name=$(basename "$SHELL")
    echo "  ✓ Shell: $shell_name"
    VALIDATION_PASSED=$((VALIDATION_PASSED + 1))
    
    # Check shell RC file
    local shell_rc=""
    if [[ "$SHELL" == */bash ]]; then
        shell_rc="$HOME/.bashrc"
    elif [[ "$SHELL" == */zsh ]]; then
        shell_rc="$HOME/.zshrc"
    fi
    
    if [[ -n "$shell_rc" && -f "$shell_rc" ]]; then
        echo "  ✓ Shell RC: $shell_rc exists"
        VALIDATION_PASSED=$((VALIDATION_PASSED + 1))
        
        # Check for ModernBlog configuration
        if grep -q "ModernBlog Development Environment" "$shell_rc" 2>/dev/null; then
            echo "  ✓ ModernBlog config: found in shell RC"
            VALIDATION_PASSED=$((VALIDATION_PASSED + 1))
        else
            echo "  ✗ ModernBlog config: not found in shell RC"
            VALIDATION_FAILED=$((VALIDATION_FAILED + 1))
        fi
    else
        echo "  ✗ Shell RC: not found"
        VALIDATION_FAILED=$((VALIDATION_FAILED + 1))
    fi
    
    echo ""
}

check_vscode_configuration() {
    log_info "Checking VS Code configuration..."
    
    local vscode_dir="${SCRIPT_DIR}/.vscode"
    
    if [[ -d "$vscode_dir" ]]; then
        echo "  ✓ VS Code directory: exists"
        VALIDATION_PASSED=$((VALIDATION_PASSED + 1))
        
        local vscode_files=(
            "settings.json"
            "extensions.json"
            "launch.json"
            "tasks.json"
        )
        
        for file in "${vscode_files[@]}"; do
            if [[ -f "$vscode_dir/$file" ]]; then
                echo "  ✓ VS Code $file: exists"
                VALIDATION_PASSED=$((VALIDATION_PASSED + 1))
            else
                echo "  ✗ VS Code $file: missing"
                VALIDATION_FAILED=$((VALIDATION_FAILED + 1))
            fi
        done
    else
        echo "  ✗ VS Code directory: not found"
        VALIDATION_FAILED=$((VALIDATION_FAILED + 1))
    fi
    
    echo ""
}

check_git_configuration() {
    log_info "Checking Git configuration..."
    
    if git config --global user.name &> /dev/null; then
        local git_name=$(git config --global user.name)
        echo "  ✓ Git user.name: $git_name"
        VALIDATION_PASSED=$((VALIDATION_PASSED + 1))
    else
        echo "  ✗ Git user.name: not configured"
        VALIDATION_FAILED=$((VALIDATION_FAILED + 1))
    fi
    
    if git config --global user.email &> /dev/null; then
        local git_email=$(git config --global user.email)
        echo "  ✓ Git user.email: $git_email"
        VALIDATION_PASSED=$((VALIDATION_PASSED + 1))
    else
        echo "  ✗ Git user.email: not configured"
        VALIDATION_FAILED=$((VALIDATION_FAILED + 1))
    fi
    
    # Check for Git aliases
    if git config --global alias.st &> /dev/null; then
        echo "  ✓ Git aliases: configured"
        VALIDATION_PASSED=$((VALIDATION_PASSED + 1))
    else
        echo "  ✗ Git aliases: not configured"
        VALIDATION_FAILED=$((VALIDATION_FAILED + 1))
    fi
    
    echo ""
}

run_health_checks() {
    log_info "Running health checks..."
    
    # Test Docker connectivity
    if docker ps &> /dev/null; then
        echo "  ✓ Docker: responsive"
        VALIDATION_PASSED=$((VALIDATION_PASSED + 1))
    else
        echo "  ✗ Docker: not responsive"
        VALIDATION_FAILED=$((VALIDATION_FAILED + 1))
    fi
    
    # Test Kubernetes connectivity
    if kubectl version --client &> /dev/null; then
        echo "  ✓ kubectl: responsive"
        VALIDATION_PASSED=$((VALIDATION_PASSED + 1))
    else
        echo "  ✗ kubectl: not responsive"
        VALIDATION_FAILED=$((VALIDATION_FAILED + 1))
    fi
    
    # Test Kind cluster
    if kind get clusters 2>/dev/null | grep -q "modernblog-cluster"; then
        echo "  ✓ Kind cluster: accessible"
        VALIDATION_PASSED=$((VALIDATION_PASSED + 1))
    else
        echo "  ✗ Kind cluster: not accessible"
        VALIDATION_FAILED=$((VALIDATION_FAILED + 1))
    fi
    
    echo ""
}

generate_validation_report() {
    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    echo "                    VALIDATION SUMMARY"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""
    echo "✓ Passed: $VALIDATION_PASSED"
    echo "✗ Failed: $VALIDATION_FAILED"
    echo "Total:    $((VALIDATION_PASSED + VALIDATION_FAILED))"
    echo ""
    
    local success_rate=0
    if [[ $((VALIDATION_PASSED + VALIDATION_FAILED)) -gt 0 ]]; then
        success_rate=$((VALIDATION_PASSED * 100 / (VALIDATION_PASSED + VALIDATION_FAILED)))
    fi
    
    echo "Success Rate: $success_rate%"
    echo ""
    
    if [[ $VALIDATION_FAILED -eq 0 ]]; then
        log_success "🎉 All validations passed! Your development environment is ready."
        echo ""
        echo "Next steps:"
        echo "  1. Start development services: make dev"
        echo "  2. Deploy to Kubernetes: make k8s-deploy"
        echo "  3. Run tests: make test"
        echo "  4. Open VS Code: code ."
        echo ""
        return 0
    elif [[ $success_rate -ge 80 ]]; then
        log_warning "⚠️  Most validations passed, but some issues were found."
        echo ""
        echo "You can likely proceed with development, but consider fixing the failed validations."
        echo ""
        return 1
    else
        log_error "❌ Multiple validations failed. Please fix the issues before proceeding."
        echo ""
        echo "Common fixes:"
        echo "  - Restart Docker Desktop"
        echo "  - Run setup script again: ./setup.sh"
        echo "  - Check tool installations: make install"
        echo ""
        return 2
    fi
}

main() {
    log_info "Validating ModernBlog development environment..."
    echo ""
    
    check_required_tools
    check_optional_tools
    check_docker_daemon
    check_kubernetes_cluster
    check_ingress_controller
    check_local_registry
    check_docker_services
    check_environment_files
    check_shell_configuration
    check_vscode_configuration
    check_git_configuration
    run_health_checks
    
    generate_validation_report
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Import logging functions
    if [[ -f "${SCRIPT_DIR:-$(dirname "$0")/../}/setup.sh" ]]; then
        source "${SCRIPT_DIR:-$(dirname "$0")/../}/setup.sh"
    else
        # Fallback logging functions
        log_info() { echo "[INFO] $1"; }
        log_success() { echo "[SUCCESS] $1"; }
        log_warning() { echo "[WARNING] $1"; }
        log_error() { echo "[ERROR] $1" >&2; }
    fi
    
    main
fi