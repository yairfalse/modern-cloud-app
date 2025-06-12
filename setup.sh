#!/bin/bash

# Production-ready setup script with comprehensive error handling and logging

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Setup logging
LOG_FILE="setup-$(date +%Y-%m-%d).log"
TEMP_LOG="/tmp/modernblog-setup-$$"

# Initialize arrays for tracking
declare -a INSTALLED_TOOLS=()
declare -a FAILED_TOOLS=()
declare -a SKIPPED_TOOLS=()
declare -A TOOL_VERSIONS=()
declare -A TOOL_ERRORS=()

# Function to log messages
log() {
    local level=$1
    shift
    local message="$@"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    
    case $level in
        ERROR)
            echo -e "${RED}[ERROR] $message${NC}"
            ;;
        SUCCESS)
            echo -e "${GREEN}[OK] $message${NC}"
            ;;
        INFO)
            echo -e "${BLUE}[INFO] $message${NC}"
            ;;
        WARN)
            echo -e "${YELLOW}[WARN] $message${NC}"
            ;;
    esac
}

# Function to check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Function to get version of a tool
get_version() {
    local tool=$1
    local version="unknown"
    
    case $tool in
        go)
            version=$(go version 2>/dev/null | awk '{print $3}' || echo "unknown")
            ;;
        node)
            version=$(node --version 2>/dev/null || echo "unknown")
            ;;
        docker)
            version=$(docker --version 2>/dev/null | awk '{print $3}' | tr -d ',' || echo "unknown")
            ;;
        kubectl)
            version=$(kubectl version --client --short 2>/dev/null | awk '{print $3}' || echo "unknown")
            ;;
        kind)
            version=$(kind --version 2>/dev/null | awk '{print $3}' || echo "unknown")
            ;;
        skaffold)
            version=$(skaffold version 2>/dev/null || echo "unknown")
            ;;
        terraform)
            version=$(terraform version 2>/dev/null | head -n1 | awk '{print $2}' || echo "unknown")
            ;;
        claude)
            version=$(claude --version 2>/dev/null || echo "unknown")
            ;;
    esac
    
    echo "$version"
}

# Function to run command with error handling
run_with_log() {
    local cmd="$@"
    log INFO "Running: $cmd"
    
    if eval "$cmd" >> "$TEMP_LOG" 2>&1; then
        cat "$TEMP_LOG" >> "$LOG_FILE"
        rm -f "$TEMP_LOG"
        return 0
    else
        local exit_code=$?
        cat "$TEMP_LOG" >> "$LOG_FILE"
        rm -f "$TEMP_LOG"
        return $exit_code
    fi
}

# Main setup begins
echo -e "${GREEN}ModernBlog Production Setup${NC}"
echo "========================================="
echo -e "${BLUE}📝 Logging to $LOG_FILE${NC}"
echo ""

log INFO "ModernBlog setup started"
log INFO "OS: $OSTYPE"
log INFO "User: $(whoami)"
log INFO "Directory: $(pwd)"

# Check if we're in the right directory
if [[ ! -f "setup.sh" ]]; then
    log ERROR "Not in project root directory. Please run from the project root."
    exit 1
fi

# Pre-flight checks
echo -e "${BLUE}🔍 Checking existing installations...${NC}"
echo ""

REQUIRED_TOOLS=("go" "node" "docker" "kubectl" "kind" "skaffold" "terraform" "claude")

for tool in "${REQUIRED_TOOLS[@]}"; do
    if command_exists "$tool"; then
        version=$(get_version "$tool")
        TOOL_VERSIONS[$tool]="$version"
        log SUCCESS "$tool already installed (version: $version)"
        SKIPPED_TOOLS+=("$tool")
    else
        log WARN "$tool not found - will install"
    fi
done

echo ""
echo -e "${BLUE}📦 Installing missing components...${NC}"
echo ""

# Detect OS
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
else
    log ERROR "Unsupported OS: $OSTYPE"
    echo -e "${RED}Setup cannot continue on this OS${NC}"
    exit 1
fi

# Function to install tool with error handling
install_tool() {
    local tool=$1
    local install_cmd=$2
    
    if command_exists "$tool"; then
        log INFO "$tool already installed, skipping"
        return 0
    fi
    
    log INFO "Installing $tool..."
    
    if run_with_log "$install_cmd"; then
        if command_exists "$tool"; then
            version=$(get_version "$tool")
            TOOL_VERSIONS[$tool]="$version"
            INSTALLED_TOOLS+=("$tool")
            log SUCCESS "$tool installed successfully (version: $version)"
            return 0
        else
            TOOL_ERRORS[$tool]="Tool not found after installation"
            FAILED_TOOLS+=("$tool")
            log ERROR "$tool installation appeared to succeed but tool not found"
            return 1
        fi
    else
        TOOL_ERRORS[$tool]="Installation command failed"
        FAILED_TOOLS+=("$tool")
        log ERROR "Failed to install $tool"
        return 1
    fi
}

# macOS installation function
install_macos_tools() {
    # Check if Homebrew is installed
    if ! command_exists brew; then
        log INFO "Installing Homebrew..."
        if run_with_log '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'; then
            log SUCCESS "Homebrew installed successfully"
        else
            log ERROR "Failed to install Homebrew - some tools may not install correctly"
        fi
    fi
    
    # Install each tool individually to handle failures gracefully
    if command_exists brew; then
        install_tool "go" "brew install go"
        install_tool "node" "brew install node"
        install_tool "docker" "brew install --cask docker"
        install_tool "kubectl" "brew install kubectl"
        install_tool "kind" "brew install kind"
        install_tool "skaffold" "brew install skaffold"
        install_tool "terraform" "brew install terraform"
    else
        log ERROR "Homebrew not available, cannot install tools automatically"
    fi
    
    # Install Claude CLI via npm if node is available
    if command_exists node && command_exists npm; then
        install_tool "claude" "npm install -g claude-ai"
    else
        log WARN "Node/npm not available, cannot install Claude CLI"
        TOOL_ERRORS["claude"]="Node/npm required but not available"
        FAILED_TOOLS+=("claude")
    fi
}

# Linux installation function
install_linux_tools() {
    # Update package lists
    log INFO "Updating package lists..."
    run_with_log "sudo apt-get update"
    
    # Install Node.js
    if ! command_exists node; then
        log INFO "Installing Node.js..."
        if run_with_log "curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -" && \
           run_with_log "sudo apt-get install -y nodejs"; then
            if command_exists node; then
                version=$(get_version "node")
                TOOL_VERSIONS["node"]="$version"
                INSTALLED_TOOLS+=("node")
                log SUCCESS "Node.js installed successfully (version: $version)"
            fi
        else
            TOOL_ERRORS["node"]="Failed to install Node.js"
            FAILED_TOOLS+=("node")
            log ERROR "Failed to install Node.js"
        fi
    fi
    
    # Install Go
    if ! command_exists go; then
        log INFO "Installing Go..."
        GO_VERSION="1.21.0"
        if run_with_log "wget https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" && \
           run_with_log "sudo tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz" && \
           run_with_log "rm go${GO_VERSION}.linux-amd64.tar.gz"; then
            echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
            export PATH=$PATH:/usr/local/go/bin
            if command_exists go; then
                version=$(get_version "go")
                TOOL_VERSIONS["go"]="$version"
                INSTALLED_TOOLS+=("go")
                log SUCCESS "Go installed successfully (version: $version)"
            fi
        else
            TOOL_ERRORS["go"]="Failed to install Go"
            FAILED_TOOLS+=("go")
            log ERROR "Failed to install Go"
        fi
    fi
    
    # Install Docker
    if ! command_exists docker; then
        log INFO "Installing Docker..."
        if run_with_log "curl -fsSL https://get.docker.com -o get-docker.sh" && \
           run_with_log "sudo sh get-docker.sh" && \
           run_with_log "sudo usermod -aG docker $USER" && \
           run_with_log "rm get-docker.sh"; then
            if command_exists docker; then
                version=$(get_version "docker")
                TOOL_VERSIONS["docker"]="$version"
                INSTALLED_TOOLS+=("docker")
                log SUCCESS "Docker installed successfully (version: $version)"
                log WARN "You may need to log out and back in for Docker group changes to take effect"
            fi
        else
            TOOL_ERRORS["docker"]="Failed to install Docker"
            FAILED_TOOLS+=("docker")
            log ERROR "Failed to install Docker"
        fi
    fi
    
    # Install kubectl
    if ! command_exists kubectl; then
        log INFO "Installing kubectl..."
        if run_with_log "sudo mkdir -p /etc/apt/keyrings" && \
           run_with_log "curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg" && \
           run_with_log "echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list" && \
           run_with_log "sudo apt-get update" && \
           run_with_log "sudo apt-get install -y kubectl"; then
            if command_exists kubectl; then
                version=$(get_version "kubectl")
                TOOL_VERSIONS["kubectl"]="$version"
                INSTALLED_TOOLS+=("kubectl")
                log SUCCESS "kubectl installed successfully (version: $version)"
            fi
        else
            TOOL_ERRORS["kubectl"]="Failed to install kubectl"
            FAILED_TOOLS+=("kubectl")
            log ERROR "Failed to install kubectl"
        fi
    fi
    
    # Install kind
    if ! command_exists kind; then
        log INFO "Installing kind..."
        if run_with_log "curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64" && \
           run_with_log "chmod +x ./kind" && \
           run_with_log "sudo mv ./kind /usr/local/bin/kind"; then
            if command_exists kind; then
                version=$(get_version "kind")
                TOOL_VERSIONS["kind"]="$version"
                INSTALLED_TOOLS+=("kind")
                log SUCCESS "kind installed successfully (version: $version)"
            fi
        else
            TOOL_ERRORS["kind"]="Failed to install kind"
            FAILED_TOOLS+=("kind")
            log ERROR "Failed to install kind"
        fi
    fi
    
    # Install skaffold
    if ! command_exists skaffold; then
        log INFO "Installing skaffold..."
        if run_with_log "curl -Lo skaffold https://storage.googleapis.com/skaffold/releases/latest/skaffold-linux-amd64" && \
           run_with_log "chmod +x skaffold" && \
           run_with_log "sudo mv skaffold /usr/local/bin"; then
            if command_exists skaffold; then
                version=$(get_version "skaffold")
                TOOL_VERSIONS["skaffold"]="$version"
                INSTALLED_TOOLS+=("skaffold")
                log SUCCESS "skaffold installed successfully (version: $version)"
            fi
        else
            TOOL_ERRORS["skaffold"]="Failed to install skaffold"
            FAILED_TOOLS+=("skaffold")
            log ERROR "Failed to install skaffold"
        fi
    fi
    
    # Install Terraform
    if ! command_exists terraform; then
        log INFO "Installing Terraform..."
        if run_with_log "wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg" && \
           run_with_log "echo 'deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main' | sudo tee /etc/apt/sources.list.d/hashicorp.list" && \
           run_with_log "sudo apt update" && \
           run_with_log "sudo apt-get install terraform"; then
            if command_exists terraform; then
                version=$(get_version "terraform")
                TOOL_VERSIONS["terraform"]="$version"
                INSTALLED_TOOLS+=("terraform")
                log SUCCESS "Terraform installed successfully (version: $version)"
            fi
        else
            TOOL_ERRORS["terraform"]="Failed to install Terraform"
            FAILED_TOOLS+=("terraform")
            log ERROR "Failed to install Terraform"
        fi
    fi
    
    # Install Claude CLI via npm if node is available
    if command_exists node && command_exists npm; then
        install_tool "claude" "sudo npm install -g claude-ai"
    else
        log WARN "Node/npm not available, cannot install Claude CLI"
        TOOL_ERRORS["claude"]="Node/npm required but not available"
        FAILED_TOOLS+=("claude")
    fi
}

# Run OS-specific installation
if [[ "$OS" == "macos" ]]; then
    install_macos_tools
elif [[ "$OS" == "linux" ]]; then
    install_linux_tools
fi

echo ""
echo -e "${BLUE}🔧 Setting up Kubernetes cluster...${NC}"

# Setup Kind cluster (non-critical, continue on failure)
if command_exists kind && command_exists kubectl; then
    log INFO "Setting up Kind cluster..."
    if [[ -f "./scripts/setup-local-k8s.sh" ]]; then
        if run_with_log "./scripts/setup-local-k8s.sh"; then
            log SUCCESS "Kind cluster setup successfully"
            
            # Validate cluster
            if run_with_log "kubectl cluster-info"; then
                log SUCCESS "Kubernetes cluster is accessible"
            else
                log WARN "Kubernetes cluster created but not accessible"
            fi
        else
            log WARN "Failed to setup Kind cluster - you can set it up manually later"
        fi
    else
        log WARN "setup-local-k8s.sh script not found"
    fi
else
    log WARN "kind or kubectl not available - skipping Kubernetes setup"
fi

# Validate Docker
if command_exists docker; then
    if run_with_log "docker info"; then
        log SUCCESS "Docker daemon is running"
    else
        log WARN "Docker installed but daemon not running - you may need to start Docker"
    fi
fi

echo ""
echo -e "${GREEN}✅ Setup complete - check $LOG_FILE for details${NC}"
echo ""
echo "========================================="
echo -e "${BLUE}Installation Summary:${NC}"
echo ""

# Show summary
if [[ ${#SKIPPED_TOOLS[@]} -gt 0 ]]; then
    echo -e "${GREEN}Already Installed (${#SKIPPED_TOOLS[@]}):${NC}"
    for tool in "${SKIPPED_TOOLS[@]}"; do
        echo "  ✓ $tool (${TOOL_VERSIONS[$tool]:-unknown})"
    done
    echo ""
fi

if [[ ${#INSTALLED_TOOLS[@]} -gt 0 ]]; then
    echo -e "${GREEN}Newly Installed (${#INSTALLED_TOOLS[@]}):${NC}"
    for tool in "${INSTALLED_TOOLS[@]}"; do
        echo "  ✓ $tool (${TOOL_VERSIONS[$tool]:-unknown})"
    done
    echo ""
fi

if [[ ${#FAILED_TOOLS[@]} -gt 0 ]]; then
    echo -e "${RED}Failed to Install (${#FAILED_TOOLS[@]}):${NC}"
    for tool in "${FAILED_TOOLS[@]}"; do
        echo "  ✗ $tool - ${TOOL_ERRORS[$tool]:-Unknown error}"
    done
    echo ""
    log WARN "Some tools failed to install but setup continued"
fi

# Provide next steps
echo "========================================="
echo -e "${BLUE}Next Steps:${NC}"
echo ""

if command_exists docker && ! docker info &>/dev/null; then
    echo "  1. Start Docker Desktop (if on macOS) or Docker daemon"
fi

if [[ ${#FAILED_TOOLS[@]} -gt 0 ]]; then
    echo "  2. Review $LOG_FILE for installation errors"
    echo "  3. Manually install failed tools if needed"
fi

echo "  • cd to frontend/ or backend/ directory"
echo "  • Run 'skaffold dev' to start development"
echo "  • Open http://localhost:8080 in your browser"
echo ""
echo -e "${BLUE}Useful Commands:${NC}"
echo "  make dev-start    - Start development with skaffold"
echo "  make dev-stop     - Stop development environment"
echo "  make status       - Check cluster status"
echo ""

# Final log
log INFO "Setup completed with ${#INSTALLED_TOOLS[@]} new installations, ${#SKIPPED_TOOLS[@]} skipped, ${#FAILED_TOOLS[@]} failed"

# Exit successfully even if some tools failed
exit 0