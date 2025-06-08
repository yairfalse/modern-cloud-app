#!/bin/bash
set -euo pipefail

# Tool installation script for ModernBlog development environment
# Installs all required development tools

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Load platform configuration
if [[ -f "$HOME/.modernblog/platform.conf" ]]; then
    source "$HOME/.modernblog/platform.conf"
else
    echo -e "${RED}✗ Platform configuration not found. Run detect-platform.sh first${NC}"
    exit 1
fi

# Installation tracking
TOOLS_INSTALLED=0
TOOLS_FAILED=0

log_install() {
    echo -e "${BLUE}Installing $1...${NC}"
}

check_command() {
    if command -v "$1" &> /dev/null; then
        echo -e "${GREEN}✓ $1 is already installed${NC}"
        return 0
    else
        return 1
    fi
}

install_homebrew_package() {
    local package=$1
    local cask=${2:-false}
    
    if [[ "$cask" == "true" ]]; then
        brew install --cask "$package"
    else
        brew install "$package"
    fi
}

install_go() {
    log_install "Go $GO_VERSION"
    
    if check_command go; then
        local current_version=$(go version | awk '{print $3}' | sed 's/go//')
        echo "  Current version: $current_version"
        return 0
    fi
    
    if [[ "$PLATFORM" == "darwin" ]]; then
        install_homebrew_package go
    else
        # Download and install Go for Linux
        local go_url="https://go.dev/dl/go${GO_VERSION}.linux-${ARCH}.tar.gz"
        curl -LO "$go_url"
        sudo rm -rf /usr/local/go
        sudo tar -C /usr/local -xzf "go${GO_VERSION}.linux-${ARCH}.tar.gz"
        rm "go${GO_VERSION}.linux-${ARCH}.tar.gz"
        
        # Add to PATH
        echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
        export PATH=$PATH:/usr/local/go/bin
    fi
    
    TOOLS_INSTALLED=$((TOOLS_INSTALLED + 1))
}

install_node() {
    log_install "Node.js $NODE_VERSION"
    
    if check_command node; then
        local current_version=$(node --version)
        echo "  Current version: $current_version"
        return 0
    fi
    
    if [[ "$PLATFORM" == "darwin" ]]; then
        install_homebrew_package node@$NODE_VERSION
        brew link --overwrite node@$NODE_VERSION
    else
        # Install Node via NodeSource repository
        curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | sudo -E bash -
        sudo apt-get install -y nodejs
    fi
    
    # Install global npm packages
    npm install -g yarn pnpm
    
    TOOLS_INSTALLED=$((TOOLS_INSTALLED + 1))
}

install_docker() {
    log_install "Docker"
    
    if check_command docker; then
        local current_version=$(docker --version)
        echo "  Current version: $current_version"
        return 0
    fi
    
    if [[ "$PLATFORM" == "darwin" ]]; then
        if [[ ! -d "/Applications/Docker.app" ]]; then
            install_homebrew_package docker true
            echo -e "${YELLOW}⚠ Please start Docker Desktop from Applications${NC}"
        fi
    else
        # Install Docker Engine on Linux
        curl -fsSL https://get.docker.com | sudo sh
        sudo usermod -aG docker $USER
        echo -e "${YELLOW}⚠ Log out and back in for Docker group changes to take effect${NC}"
    fi
    
    TOOLS_INSTALLED=$((TOOLS_INSTALLED + 1))
}

install_kubectl() {
    log_install "kubectl"
    
    if check_command kubectl; then
        local current_version=$(kubectl version --client --short 2>/dev/null || kubectl version --client)
        echo "  Current version: $current_version"
        return 0
    fi
    
    if [[ "$PLATFORM" == "darwin" ]]; then
        install_homebrew_package kubectl
    else
        # Install kubectl on Linux
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${ARCH}/kubectl"
        sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
        rm kubectl
    fi
    
    TOOLS_INSTALLED=$((TOOLS_INSTALLED + 1))
}

install_terraform() {
    log_install "Terraform $TERRAFORM_VERSION"
    
    if check_command terraform; then
        local current_version=$(terraform version | head -n1 | awk '{print $2}')
        echo "  Current version: $current_version"
        return 0
    fi
    
    if [[ "$PLATFORM" == "darwin" ]]; then
        install_homebrew_package terraform
    else
        # Install Terraform on Linux
        wget -O terraform.zip "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${ARCH}.zip"
        unzip terraform.zip
        sudo mv terraform /usr/local/bin/
        rm terraform.zip
    fi
    
    TOOLS_INSTALLED=$((TOOLS_INSTALLED + 1))
}

install_kind() {
    log_install "Kind $KIND_VERSION"
    
    if check_command kind; then
        local current_version=$(kind version)
        echo "  Current version: $current_version"
        return 0
    fi
    
    if [[ "$PLATFORM" == "darwin" ]]; then
        install_homebrew_package kind
    else
        # Install Kind on Linux
        curl -Lo ./kind "https://kind.sigs.k8s.io/dl/v${KIND_VERSION}/kind-linux-${ARCH}"
        chmod +x ./kind
        sudo mv ./kind /usr/local/bin/kind
    fi
    
    TOOLS_INSTALLED=$((TOOLS_INSTALLED + 1))
}

install_skaffold() {
    log_install "Skaffold $SKAFFOLD_VERSION"
    
    if check_command skaffold; then
        local current_version=$(skaffold version)
        echo "  Current version: $current_version"
        return 0
    fi
    
    if [[ "$PLATFORM" == "darwin" ]]; then
        install_homebrew_package skaffold
    else
        # Install Skaffold on Linux
        curl -Lo skaffold "https://storage.googleapis.com/skaffold/releases/v${SKAFFOLD_VERSION}/skaffold-linux-${ARCH}"
        chmod +x skaffold
        sudo mv skaffold /usr/local/bin
    fi
    
    TOOLS_INSTALLED=$((TOOLS_INSTALLED + 1))
}

install_dagger() {
    log_install "Dagger $DAGGER_VERSION"
    
    if check_command dagger; then
        local current_version=$(dagger version)
        echo "  Current version: $current_version"
        return 0
    fi
    
    # Install Dagger
    curl -L https://dl.dagger.io/dagger/install.sh | sh
    sudo mv bin/dagger /usr/local/bin/
    rmdir bin
    
    TOOLS_INSTALLED=$((TOOLS_INSTALLED + 1))
}

install_golangci_lint() {
    log_install "golangci-lint"
    
    if check_command golangci-lint; then
        local current_version=$(golangci-lint version)
        echo "  Current version: $current_version"
        return 0
    fi
    
    if [[ "$PLATFORM" == "darwin" ]]; then
        install_homebrew_package golangci-lint
    else
        # Install golangci-lint on Linux
        curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $(go env GOPATH)/bin
    fi
    
    TOOLS_INSTALLED=$((TOOLS_INSTALLED + 1))
}

install_tflint() {
    log_install "TFLint"
    
    if check_command tflint; then
        local current_version=$(tflint --version)
        echo "  Current version: $current_version"
        return 0
    fi
    
    if [[ "$PLATFORM" == "darwin" ]]; then
        install_homebrew_package tflint
    else
        # Install TFLint on Linux
        curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash
    fi
    
    TOOLS_INSTALLED=$((TOOLS_INSTALLED + 1))
}

install_claude_code() {
    log_install "Claude Code"
    
    if check_command claude-code; then
        local current_version=$(claude-code --version 2>/dev/null || echo "version unknown")
        echo "  Current version: $current_version"
        return 0
    fi
    
    # Install Claude Code
    if [[ "$PLATFORM" == "darwin" ]]; then
        # Check if npm is available
        if command -v npm &> /dev/null; then
            npm install -g @anthropic-ai/claude-code
        else
            echo -e "${YELLOW}⚠ npm not found. Install Node.js first${NC}"
            TOOLS_FAILED=$((TOOLS_FAILED + 1))
            return 1
        fi
    else
        # Install on Linux
        if command -v npm &> /dev/null; then
            sudo npm install -g @anthropic-ai/claude-code
        else
            echo -e "${YELLOW}⚠ npm not found. Install Node.js first${NC}"
            TOOLS_FAILED=$((TOOLS_FAILED + 1))
            return 1
        fi
    fi
    
    echo -e "${BLUE}ℹ Claude Code installed. Authenticate with: claude-code auth login${NC}"
    
    TOOLS_INSTALLED=$((TOOLS_INSTALLED + 1))
}

install_additional_tools() {
    log_install "Additional development tools"
    
    if [[ "$PLATFORM" == "darwin" ]]; then
        # Install additional tools via Homebrew
        local tools=(
            "jq"           # JSON processor
            "yq"           # YAML processor
            "htop"         # Process viewer
            "watch"        # Command repeater
            "tree"         # Directory viewer
            "gh"           # GitHub CLI
            "helm"         # Kubernetes package manager
            "k9s"          # Kubernetes TUI
            "stern"        # Multi-pod log tailing
            "kubectx"      # Context switcher
            "dive"         # Docker image explorer
            "hadolint"     # Dockerfile linter
        )
        
        for tool in "${tools[@]}"; do
            if ! check_command "$tool"; then
                install_homebrew_package "$tool"
            fi
        done
    else
        # Install on Linux using appropriate package manager
        local tools=(
            "jq"
            "htop"
            "tree"
        )
        
        case "$PACKAGE_MANAGER" in
            apt)
                sudo apt-get update
                sudo apt-get install -y "${tools[@]}"
                ;;
            yum|dnf)
                sudo $PACKAGE_MANAGER install -y "${tools[@]}"
                ;;
        esac
    fi
}

configure_shell_completions() {
    echo -e "${BLUE}Configuring shell completions...${NC}"
    
    # Detect shell
    local shell_name=$(basename "$SHELL")
    local completion_dir=""
    
    case "$shell_name" in
        bash)
            completion_dir="$HOME/.bash_completion.d"
            mkdir -p "$completion_dir"
            
            # Generate completions
            kubectl completion bash > "$completion_dir/kubectl"
            kind completion bash > "$completion_dir/kind"
            skaffold completion bash > "$completion_dir/skaffold"
            helm completion bash > "$completion_dir/helm" 2>/dev/null || true
            
            # Source completions
            echo "for f in $completion_dir/*; do source \$f; done" >> ~/.bashrc
            ;;
        zsh)
            # Ensure .zshrc exists
            touch ~/.zshrc
            
            # Add completions to zsh
            echo "# Kubernetes tools completions" >> ~/.zshrc
            echo "source <(kubectl completion zsh)" >> ~/.zshrc
            echo "source <(kind completion zsh)" >> ~/.zshrc
            echo "source <(skaffold completion zsh)" >> ~/.zshrc
            echo "source <(helm completion zsh) 2>/dev/null || true" >> ~/.zshrc
            ;;
    esac
    
    echo -e "${GREEN}✓ Shell completions configured${NC}"
}

main() {
    echo -e "${BLUE}=== Installing Development Tools ===${NC}"
    echo ""
    
    # Core tools
    install_go
    install_node
    install_docker
    install_kubectl
    install_terraform
    
    # Kubernetes tools
    install_kind
    install_skaffold
    
    # CI/CD tools
    install_dagger
    
    # Linting tools
    install_golangci_lint
    install_tflint
    
    # AI-enhanced development
    install_claude_code
    
    # Additional tools
    install_additional_tools
    
    # Configure completions
    configure_shell_completions
    
    # Summary
    echo ""
    echo -e "${BLUE}=== Installation Summary ===${NC}"
    echo -e "${GREEN}✓ Tools installed: $TOOLS_INSTALLED${NC}"
    if [[ $TOOLS_FAILED -gt 0 ]]; then
        echo -e "${RED}✗ Tools failed: $TOOLS_FAILED${NC}"
    fi
    
    # Post-installation notes
    echo ""
    echo -e "${BLUE}=== Post-Installation Notes ===${NC}"
    echo "1. Restart your terminal to load shell completions"
    echo "2. Authenticate Claude Code: claude-code auth login"
    if [[ "$PLATFORM" == "darwin" ]] && [[ ! -d "/Applications/Docker.app" ]]; then
        echo "3. Start Docker Desktop from Applications"
    fi
    if [[ "$PLATFORM" != "darwin" ]]; then
        echo "3. Log out and back in for Docker group changes"
    fi
    
    echo ""
    echo -e "${GREEN}✓ Tool installation complete${NC}"
}

main "$@"