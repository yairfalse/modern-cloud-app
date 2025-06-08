#!/bin/bash
set -euo pipefail

# Validation script for ModernBlog development environment
# Performs comprehensive health checks and smoke tests

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Counters
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNING_CHECKS=0

check_result() {
    local name=$1
    local status=$2
    local message=${3:-""}
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    case $status in
        "pass")
            echo -e "${GREEN}✓ $name${NC}"
            PASSED_CHECKS=$((PASSED_CHECKS + 1))
            ;;
        "fail")
            echo -e "${RED}✗ $name${NC}"
            if [[ -n "$message" ]]; then
                echo -e "  ${RED}$message${NC}"
            fi
            FAILED_CHECKS=$((FAILED_CHECKS + 1))
            ;;
        "warn")
            echo -e "${YELLOW}⚠ $name${NC}"
            if [[ -n "$message" ]]; then
                echo -e "  ${YELLOW}$message${NC}"
            fi
            WARNING_CHECKS=$((WARNING_CHECKS + 1))
            ;;
    esac
}

validate_system_requirements() {
    echo -e "${BLUE}=== System Requirements ===${NC}"
    
    # Check OS
    case "$OSTYPE" in
        darwin*)
            check_result "Operating System (macOS)" "pass"
            ;;
        linux*)
            check_result "Operating System (Linux)" "pass"
            ;;
        *)
            check_result "Operating System" "fail" "Unsupported OS: $OSTYPE"
            ;;
    esac
    
    # Check architecture
    local arch=$(uname -m)
    case $arch in
        x86_64|aarch64|arm64)
            check_result "Architecture ($arch)" "pass"
            ;;
        *)
            check_result "Architecture" "fail" "Unsupported architecture: $arch"
            ;;
    esac
    
    # Check memory
    local total_mem
    if [[ "$OSTYPE" == "darwin"* ]]; then
        total_mem=$(( $(sysctl -n hw.memsize) / 1024 / 1024 / 1024 ))
    else
        total_mem=$(( $(grep MemTotal /proc/meminfo | awk '{print $2}') / 1024 / 1024 ))
    fi
    
    if [[ $total_mem -ge 8 ]]; then
        check_result "Memory (${total_mem}GB)" "pass"
    elif [[ $total_mem -ge 4 ]]; then
        check_result "Memory (${total_mem}GB)" "warn" "Recommended: 8GB+"
    else
        check_result "Memory (${total_mem}GB)" "fail" "Minimum: 4GB"
    fi
    
    # Check disk space
    local available_space
    if [[ "$OSTYPE" == "darwin"* ]]; then
        available_space=$(df -g . | awk 'NR==2 {print $4}')
    else
        available_space=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')
    fi
    
    if [[ $available_space -ge 20 ]]; then
        check_result "Disk Space (${available_space}GB)" "pass"
    elif [[ $available_space -ge 10 ]]; then
        check_result "Disk Space (${available_space}GB)" "warn" "Recommended: 20GB+"
    else
        check_result "Disk Space (${available_space}GB)" "fail" "Minimum: 10GB"
    fi
    
    echo ""
}

validate_core_tools() {
    echo -e "${BLUE}=== Core Development Tools ===${NC}"
    
    # Git
    if command -v git &> /dev/null; then
        local git_version=$(git --version)
        check_result "Git ($git_version)" "pass"
    else
        check_result "Git" "fail" "Not installed"
    fi
    
    # Docker
    if command -v docker &> /dev/null; then
        if docker info &> /dev/null; then
            local docker_version=$(docker --version)
            check_result "Docker ($docker_version)" "pass"
        else
            check_result "Docker" "fail" "Not running"
        fi
    else
        check_result "Docker" "fail" "Not installed"
    fi
    
    # Go
    if command -v go &> /dev/null; then
        local go_version=$(go version | awk '{print $3}')
        check_result "Go ($go_version)" "pass"
    else
        check_result "Go" "fail" "Not installed"
    fi
    
    # Node.js
    if command -v node &> /dev/null; then
        local node_version=$(node --version)
        check_result "Node.js ($node_version)" "pass"
    else
        check_result "Node.js" "fail" "Not installed"
    fi
    
    # kubectl
    if command -v kubectl &> /dev/null; then
        local kubectl_version=$(kubectl version --client --short 2>/dev/null || kubectl version --client | head -n1)
        check_result "kubectl ($kubectl_version)" "pass"
    else
        check_result "kubectl" "fail" "Not installed"
    fi
    
    # Terraform
    if command -v terraform &> /dev/null; then
        local terraform_version=$(terraform version | head -n1)
        check_result "Terraform ($terraform_version)" "pass"
    else
        check_result "Terraform" "fail" "Not installed"
    fi
    
    echo ""
}

validate_k8s_tools() {
    echo -e "${BLUE}=== Kubernetes Tools ===${NC}"
    
    # Kind
    if command -v kind &> /dev/null; then
        local kind_version=$(kind version)
        check_result "Kind ($kind_version)" "pass"
    else
        check_result "Kind" "fail" "Not installed"
    fi
    
    # Skaffold
    if command -v skaffold &> /dev/null; then
        local skaffold_version=$(skaffold version)
        check_result "Skaffold ($skaffold_version)" "pass"
    else
        check_result "Skaffold" "fail" "Not installed"
    fi
    
    # Helm
    if command -v helm &> /dev/null; then
        local helm_version=$(helm version --short)
        check_result "Helm ($helm_version)" "pass"
    else
        check_result "Helm" "warn" "Not installed (optional)"
    fi
    
    echo ""
}

validate_development_tools() {
    echo -e "${BLUE}=== Development Tools ===${NC}"
    
    # Dagger
    if command -v dagger &> /dev/null; then
        local dagger_version=$(dagger version)
        check_result "Dagger ($dagger_version)" "pass"
    else
        check_result "Dagger" "fail" "Not installed"
    fi
    
    # golangci-lint
    if command -v golangci-lint &> /dev/null; then
        local golangci_version=$(golangci-lint version | head -n1)
        check_result "golangci-lint ($golangci_version)" "pass"
    else
        check_result "golangci-lint" "fail" "Not installed"
    fi
    
    # TFLint
    if command -v tflint &> /dev/null; then
        local tflint_version=$(tflint --version)
        check_result "TFLint ($tflint_version)" "pass"
    else
        check_result "TFLint" "fail" "Not installed"
    fi
    
    # Claude Code
    if command -v claude-code &> /dev/null; then
        local claude_version=$(claude-code --version 2>/dev/null || echo "version unknown")
        check_result "Claude Code ($claude_version)" "pass"
    else
        check_result "Claude Code" "fail" "Not installed"
    fi
    
    echo ""
}

validate_cluster() {
    echo -e "${BLUE}=== Kubernetes Cluster ===${NC}"
    
    # Check if cluster exists
    if kind get clusters 2>/dev/null | grep -q "modernblog-dev"; then
        check_result "Kind Cluster (modernblog-dev)" "pass"
        
        # Check cluster connectivity
        if kubectl cluster-info &> /dev/null; then
            check_result "Cluster Connectivity" "pass"
            
            # Check nodes
            local node_count=$(kubectl get nodes --no-headers | wc -l)
            check_result "Cluster Nodes ($node_count)" "pass"
            
            # Check system pods
            local system_pods_ready=$(kubectl get pods -n kube-system --no-headers | grep -c "Running\|Completed" || true)
            local total_system_pods=$(kubectl get pods -n kube-system --no-headers | wc -l || true)
            
            if [[ $system_pods_ready -eq $total_system_pods ]] && [[ $total_system_pods -gt 0 ]]; then
                check_result "System Pods ($system_pods_ready/$total_system_pods)" "pass"
            else
                check_result "System Pods ($system_pods_ready/$total_system_pods)" "warn" "Some pods not ready"
            fi
            
            # Check ingress controller
            if kubectl get pods -n ingress-nginx --no-headers 2>/dev/null | grep -q "Running"; then
                check_result "Ingress Controller" "pass"
            else
                check_result "Ingress Controller" "warn" "Not running"
            fi
            
        else
            check_result "Cluster Connectivity" "fail" "Cannot connect to cluster"
        fi
    else
        check_result "Kind Cluster" "fail" "Cluster not found"
    fi
    
    echo ""
}

validate_namespaces() {
    echo -e "${BLUE}=== Namespaces ===${NC}"
    
    if kubectl cluster-info &> /dev/null; then
        local namespaces=("modernblog-dev" "modernblog-staging" "monitoring")
        
        for ns in "${namespaces[@]}"; do
            if kubectl get namespace "$ns" &> /dev/null; then
                check_result "Namespace ($ns)" "pass"
            else
                check_result "Namespace ($ns)" "fail" "Not found"
            fi
        done
        
        # Check secrets
        if kubectl get secret modernblog-db-secret -n modernblog-dev &> /dev/null; then
            check_result "Database Secret" "pass"
        else
            check_result "Database Secret" "fail" "Not found"
        fi
        
        if kubectl get secret modernblog-redis-secret -n modernblog-dev &> /dev/null; then
            check_result "Redis Secret" "pass"
        else
            check_result "Redis Secret" "fail" "Not found"
        fi
    else
        check_result "Namespaces" "fail" "Cannot connect to cluster"
    fi
    
    echo ""
}

validate_dns() {
    echo -e "${BLUE}=== DNS Configuration ===${NC}"
    
    # Check /etc/hosts entries
    if grep -q "modernblog.local" /etc/hosts; then
        check_result "Local DNS (modernblog.local)" "pass"
    else
        check_result "Local DNS (modernblog.local)" "fail" "Not configured"
    fi
    
    # Test DNS resolution
    if nslookup modernblog.local &> /dev/null || host modernblog.local &> /dev/null; then
        check_result "DNS Resolution" "pass"
    else
        check_result "DNS Resolution" "warn" "May not resolve properly"
    fi
    
    echo ""
}

validate_git_config() {
    echo -e "${BLUE}=== Git Configuration ===${NC}"
    
    # Check git hooks
    if [[ -x ".git/hooks/pre-commit" ]]; then
        check_result "Pre-commit Hook" "pass"
    else
        check_result "Pre-commit Hook" "warn" "Not configured"
    fi
    
    if [[ -x ".git/hooks/pre-push" ]]; then
        check_result "Pre-push Hook" "pass"
    else
        check_result "Pre-push Hook" "warn" "Not configured"
    fi
    
    # Check user configuration
    if git config user.name &> /dev/null && git config user.email &> /dev/null; then
        check_result "Git User Config" "pass"
    else
        check_result "Git User Config" "warn" "Not fully configured"
    fi
    
    echo ""
}

validate_ide_config() {
    echo -e "${BLUE}=== IDE Configuration ===${NC}"
    
    # Check VS Code config
    if [[ -f ".vscode/settings.json" ]]; then
        check_result "VS Code Settings" "pass"
    else
        check_result "VS Code Settings" "warn" "Not found"
    fi
    
    if [[ -f ".vscode/extensions.json" ]]; then
        check_result "VS Code Extensions" "pass"
    else
        check_result "VS Code Extensions" "warn" "Not found"
    fi
    
    # Check EditorConfig
    if [[ -f ".editorconfig" ]]; then
        check_result "EditorConfig" "pass"
    else
        check_result "EditorConfig" "warn" "Not found"
    fi
    
    echo ""
}

run_smoke_tests() {
    echo -e "${BLUE}=== Smoke Tests ===${NC}"
    
    # Test Docker
    if docker run --rm hello-world &> /dev/null; then
        check_result "Docker Smoke Test" "pass"
    else
        check_result "Docker Smoke Test" "fail" "Cannot run containers"
    fi
    
    # Test kubectl
    if kubectl version --client &> /dev/null; then
        check_result "kubectl Smoke Test" "pass"
    else
        check_result "kubectl Smoke Test" "fail" "kubectl not working"
    fi
    
    # Test Go
    if echo 'package main; import "fmt"; func main() { fmt.Println("Hello") }' | go run -; then
        check_result "Go Smoke Test" "pass"
    else
        check_result "Go Smoke Test" "fail" "Go not working"
    fi
    
    # Test Terraform
    if terraform version &> /dev/null; then
        check_result "Terraform Smoke Test" "pass"
    else
        check_result "Terraform Smoke Test" "fail" "Terraform not working"
    fi
    
    echo ""
}

print_summary() {
    echo -e "${BLUE}=== Validation Summary ===${NC}"
    echo ""
    echo "Total Checks: $TOTAL_CHECKS"
    echo -e "${GREEN}Passed: $PASSED_CHECKS${NC}"
    echo -e "${YELLOW}Warnings: $WARNING_CHECKS${NC}"
    echo -e "${RED}Failed: $FAILED_CHECKS${NC}"
    echo ""
    
    local success_rate=$((PASSED_CHECKS * 100 / TOTAL_CHECKS))
    
    if [[ $FAILED_CHECKS -eq 0 ]]; then
        echo -e "${GREEN}✅ Development environment is ready!${NC}"
        echo -e "${GREEN}Success rate: ${success_rate}%${NC}"
    elif [[ $FAILED_CHECKS -le 2 ]]; then
        echo -e "${YELLOW}⚠️  Development environment has minor issues${NC}"
        echo -e "${YELLOW}Success rate: ${success_rate}%${NC}"
        echo -e "${YELLOW}Please fix the failed checks above${NC}"
    else
        echo -e "${RED}❌ Development environment has significant issues${NC}"
        echo -e "${RED}Success rate: ${success_rate}%${NC}"
        echo -e "${RED}Please run setup again or fix the issues manually${NC}"
        exit 1
    fi
    
    if [[ $WARNING_CHECKS -gt 0 ]]; then
        echo ""
        echo -e "${YELLOW}Note: Warnings indicate optional components or recommendations${NC}"
    fi
}

main() {
    echo -e "${BLUE}=== ModernBlog Development Environment Validation ===${NC}"
    echo ""
    
    validate_system_requirements
    validate_core_tools
    validate_k8s_tools
    validate_development_tools
    validate_cluster
    validate_namespaces
    validate_dns
    validate_git_config
    validate_ide_config
    run_smoke_tests
    
    print_summary
}

main "$@"