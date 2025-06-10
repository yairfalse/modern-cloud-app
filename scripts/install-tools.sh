#!/bin/bash

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}Installing essential development tools...${NC}"

# Detect OS
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
else
    echo -e "${RED}❌ Unsupported OS: $OSTYPE${NC}"
    exit 1
fi

install_macos() {
    # Check if Homebrew is installed
    if ! command -v brew &> /dev/null; then
        echo -e "${YELLOW}Installing Homebrew...${NC}"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    echo -e "${YELLOW}Installing tools via Homebrew...${NC}"
    
    # Essential tools
    brew install \
        go \
        node \
        docker \
        kubectl \
        kind \
        skaffold \
        terraform
    
    # Claude Code CLI
    if ! command -v claude-code &> /dev/null; then
        echo -e "${YELLOW}Installing Claude Code CLI...${NC}"
        npm install -g @anthropic-ai/claude-code
    fi
}

install_linux() {
    # Update package lists
    sudo apt-get update

    # Install Node.js
    if ! command -v node &> /dev/null; then
        echo -e "${YELLOW}Installing Node.js...${NC}"
        curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
        sudo apt-get install -y nodejs
    fi

    # Install Go
    if ! command -v go &> /dev/null; then
        echo -e "${YELLOW}Installing Go...${NC}"
        wget https://go.dev/dl/go1.21.0.linux-amd64.tar.gz
        sudo tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz
        echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
        rm go1.21.0.linux-amd64.tar.gz
    fi

    # Install Docker
    if ! command -v docker &> /dev/null; then
        echo -e "${YELLOW}Installing Docker...${NC}"
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        sudo usermod -aG docker $USER
        rm get-docker.sh
    fi

    # Install kubectl
    if ! command -v kubectl &> /dev/null; then
        echo -e "${YELLOW}Installing kubectl...${NC}"
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        chmod +x kubectl
        sudo mv kubectl /usr/local/bin/
    fi

    # Install kind
    if ! command -v kind &> /dev/null; then
        echo -e "${YELLOW}Installing kind...${NC}"
        curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
        chmod +x ./kind
        sudo mv ./kind /usr/local/bin/kind
    fi

    # Install skaffold
    if ! command -v skaffold &> /dev/null; then
        echo -e "${YELLOW}Installing skaffold...${NC}"
        curl -Lo skaffold https://storage.googleapis.com/skaffold/releases/latest/skaffold-linux-amd64
        chmod +x skaffold
        sudo mv skaffold /usr/local/bin
    fi

    # Install Terraform
    if ! command -v terraform &> /dev/null; then
        echo -e "${YELLOW}Installing Terraform...${NC}"
        wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
        sudo apt update && sudo apt install terraform
    fi

    # Claude Code CLI
    if ! command -v claude-code &> /dev/null; then
        echo -e "${YELLOW}Installing Claude Code CLI...${NC}"
        npm install -g @anthropic-ai/claude-code
    fi
}

# Install based on OS
if [[ "$OS" == "macos" ]]; then
    install_macos
elif [[ "$OS" == "linux" ]]; then
    install_linux
fi

# Verify installations
echo -e "${YELLOW}Verifying installations...${NC}"

TOOLS=("go" "node" "docker" "kubectl" "kind" "skaffold" "terraform" "claude-code")
FAILED=()

for tool in "${TOOLS[@]}"; do
    if command -v "$tool" &> /dev/null; then
        echo -e "${GREEN}✓ $tool installed${NC}"
    else
        echo -e "${RED}✗ $tool not found${NC}"
        FAILED+=("$tool")
    fi
done

if [[ ${#FAILED[@]} -gt 0 ]]; then
    echo -e "${RED}❌ Failed to install: ${FAILED[*]}${NC}"
    exit 1
fi

echo -e "${GREEN}🎉 All essential tools installed successfully!${NC}"