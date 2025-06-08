#!/bin/bash
set -euo pipefail

# Tool installation script for ModernBlog

# Source platform detection
source "${SCRIPT_DIR:-$(dirname "$0")/../}/scripts/detect-platform.sh"

# Tool versions
KUBECTL_VERSION="1.29.0"
KIND_VERSION="0.20.0"
HELM_VERSION="3.13.3"
SKAFFOLD_VERSION="2.10.0"
TERRAFORM_VERSION="1.6.6"
NODE_VERSION="20"
GO_VERSION="1.21.5"

install_linux_tools() {
    log_info "Installing tools for Linux..."
    
    # Update package manager
    case $PACKAGE_MANAGER in
        apt)
            sudo apt-get update
            sudo apt-get install -y curl wget git jq unzip build-essential
            ;;
        yum)
            sudo yum update -y
            sudo yum install -y curl wget git jq unzip gcc make
            ;;
        dnf)
            sudo dnf update -y
            sudo dnf install -y curl wget git jq unzip gcc make
            ;;
        *)
            log_warning "Unsupported package manager: $PACKAGE_MANAGER"
            ;;
    esac
    
    # Install Docker
    if ! command -v docker &> /dev/null; then
        log_info "Installing Docker..."
        curl -fsSL https://get.docker.com | sh
        sudo usermod -aG docker $USER
        log_success "Docker installed. Please log out and back in for group changes to take effect."
    fi
    
    # Install kubectl
    if ! command -v kubectl &> /dev/null; then
        log_info "Installing kubectl..."
        curl -LO "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/${ARCH}/kubectl"
        chmod +x kubectl
        sudo mv kubectl /usr/local/bin/
        log_success "kubectl installed"
    fi
    
    # Install Kind
    if ! command -v kind &> /dev/null; then
        log_info "Installing Kind..."
        curl -Lo ./kind "https://kind.sigs.k8s.io/dl/v${KIND_VERSION}/kind-linux-${ARCH}"
        chmod +x ./kind
        sudo mv ./kind /usr/local/bin/kind
        log_success "Kind installed"
    fi
    
    # Install Helm
    if ! command -v helm &> /dev/null; then
        log_info "Installing Helm..."
        curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
        chmod 700 get_helm.sh
        ./get_helm.sh
        rm get_helm.sh
        log_success "Helm installed"
    fi
    
    # Install Skaffold
    if ! command -v skaffold &> /dev/null; then
        log_info "Installing Skaffold..."
        curl -Lo skaffold "https://storage.googleapis.com/skaffold/releases/v${SKAFFOLD_VERSION}/skaffold-linux-${ARCH}"
        chmod +x skaffold
        sudo mv skaffold /usr/local/bin
        log_success "Skaffold installed"
    fi
    
    # Install Terraform
    if ! command -v terraform &> /dev/null; then
        log_info "Installing Terraform..."
        wget "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${ARCH}.zip"
        unzip terraform_${TERRAFORM_VERSION}_linux_${ARCH}.zip
        sudo mv terraform /usr/local/bin/
        rm terraform_${TERRAFORM_VERSION}_linux_${ARCH}.zip
        log_success "Terraform installed"
    fi
    
    # Install Node.js
    if ! command -v node &> /dev/null; then
        log_info "Installing Node.js..."
        curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | sudo -E bash -
        sudo apt-get install -y nodejs
        log_success "Node.js installed"
    fi
    
    # Install Go
    if ! command -v go &> /dev/null; then
        log_info "Installing Go..."
        wget "https://golang.org/dl/go${GO_VERSION}.linux-${ARCH}.tar.gz"
        sudo rm -rf /usr/local/go
        sudo tar -C /usr/local -xzf go${GO_VERSION}.linux-${ARCH}.tar.gz
        rm go${GO_VERSION}.linux-${ARCH}.tar.gz
        echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
        export PATH=$PATH:/usr/local/go/bin
        log_success "Go installed"
    fi
}

install_macos_tools() {
    log_info "Installing tools for macOS..."
    
    # Check if Homebrew is installed
    if ! command -v brew &> /dev/null; then
        log_error "Homebrew is not installed. Please run setup.sh first."
        exit 1
    fi
    
    # Install tools via Homebrew Bundle
    log_info "Installing tools via Homebrew Bundle..."
    brew bundle --file="${SCRIPT_DIR}/Brewfile"
    
    # Additional tools not in Brewfile
    
    # Install Node Version Manager (nvm)
    if [ ! -d "$HOME/.nvm" ]; then
        log_info "Installing nvm..."
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        nvm install $NODE_VERSION
        nvm use $NODE_VERSION
        nvm alias default $NODE_VERSION
        log_success "nvm and Node.js installed"
    fi
    
    # Configure Docker Desktop
    if [[ -d "/Applications/Docker.app" ]] && ! docker info &> /dev/null; then
        log_info "Starting Docker Desktop..."
        open -a Docker
        log_info "Waiting for Docker to start..."
        while ! docker info &> /dev/null; do
            sleep 2
        done
        log_success "Docker Desktop started"
    fi
}

install_python_tools() {
    log_info "Installing Python tools..."
    
    # Install pip if not present
    if ! command -v pip3 &> /dev/null; then
        curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
        python3 get-pip.py
        rm get-pip.py
    fi
    
    # Install Python tools
    pip3 install --user \
        pre-commit \
        yamllint \
        ansible \
        awscli \
        terraform-compliance
}

install_go_tools() {
    log_info "Installing Go tools..."
    
    if command -v go &> /dev/null; then
        go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
        go install github.com/go-task/task/v3/cmd/task@latest
        go install github.com/goreleaser/goreleaser@latest
        go install github.com/air-verse/air@latest
    fi
}

configure_shell() {
    log_info "Configuring shell environment..."
    
    # Detect shell
    SHELL_RC=""
    if [[ "$SHELL" == */bash ]]; then
        SHELL_RC="$HOME/.bashrc"
    elif [[ "$SHELL" == */zsh ]]; then
        SHELL_RC="$HOME/.zshrc"
    fi
    
    if [[ -n "$SHELL_RC" ]]; then
        # Add Kubernetes aliases
        echo "" >> "$SHELL_RC"
        echo "# ModernBlog aliases" >> "$SHELL_RC"
        echo "alias k='kubectl'" >> "$SHELL_RC"
        echo "alias kctx='kubectl config current-context'" >> "$SHELL_RC"
        echo "alias kns='kubectl config view --minify -o jsonpath={..namespace}'" >> "$SHELL_RC"
        echo "alias kgp='kubectl get pods'" >> "$SHELL_RC"
        echo "alias kgs='kubectl get svc'" >> "$SHELL_RC"
        echo "alias kgi='kubectl get ingress'" >> "$SHELL_RC"
        echo "alias kdp='kubectl describe pod'" >> "$SHELL_RC"
        echo "alias kl='kubectl logs'" >> "$SHELL_RC"
        echo "alias kexec='kubectl exec -it'" >> "$SHELL_RC"
        
        # Add path for Go binaries
        echo 'export PATH=$PATH:$HOME/go/bin' >> "$SHELL_RC"
        
        log_success "Shell aliases configured"
    fi
}

main() {
    log_info "Starting tool installation..."
    
    # Install platform-specific tools
    case $PLATFORM in
        linux)
            install_linux_tools
            ;;
        macos)
            install_macos_tools
            ;;
        *)
            log_error "Unsupported platform: $PLATFORM"
            exit 1
            ;;
    esac
    
    # Install language-specific tools
    install_python_tools
    install_go_tools
    
    # Configure shell
    configure_shell
    
    log_success "Tool installation complete"
    
    # Display installed versions
    log_info "Installed tool versions:"
    command -v docker &> /dev/null && echo "  Docker: $(docker --version)"
    command -v kubectl &> /dev/null && echo "  kubectl: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"
    command -v kind &> /dev/null && echo "  Kind: $(kind --version)"
    command -v helm &> /dev/null && echo "  Helm: $(helm version --short)"
    command -v skaffold &> /dev/null && echo "  Skaffold: $(skaffold version)"
    command -v terraform &> /dev/null && echo "  Terraform: $(terraform version | head -1)"
    command -v node &> /dev/null && echo "  Node.js: $(node --version)"
    command -v go &> /dev/null && echo "  Go: $(go version)"
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