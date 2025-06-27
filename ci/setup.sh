#!/bin/bash
set -euo pipefail

# ModernBlog Local Development Setup
# No philosophy, just working code

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}ModernBlog Local Development Setup${NC}"
echo "=================================="
echo ""

# Check OS
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
else
    echo -e "${RED}Error: Unsupported OS. This script works on Mac and Linux only.${NC}"
    exit 1
fi

echo "Detected OS: $OS"
echo ""

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install tool
install_tool() {
    local tool=$1
    local install_cmd=$2
    
    if ! command_exists "$tool"; then
        echo -e "${YELLOW}Installing $tool...${NC}"
        eval "$install_cmd"
        if ! command_exists "$tool"; then
            echo -e "${RED}Failed to install $tool. Please install manually.${NC}"
            exit 1
        fi
        echo -e "${GREEN}✓ $tool installed${NC}"
    else
        echo -e "${GREEN}✓ $tool already installed${NC}"
    fi
}

# Check and install Docker
if ! command_exists docker; then
    echo -e "${RED}Docker is not installed.${NC}"
    echo "Please install Docker Desktop from: https://www.docker.com/products/docker-desktop"
    exit 1
else
    # Check if Docker is running
    if ! docker info >/dev/null 2>&1; then
        echo -e "${RED}Docker is not running. Please start Docker Desktop.${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ Docker is running${NC}"
fi

# Install kubectl
if [[ "$OS" == "macos" ]]; then
    install_tool "kubectl" "brew install kubectl"
else
    install_tool "kubectl" "curl -LO https://dl.k8s.io/release/\$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl && chmod +x kubectl && sudo mv kubectl /usr/local/bin/"
fi

# Install Kind
if [[ "$OS" == "macos" ]]; then
    install_tool "kind" "brew install kind"
else
    install_tool "kind" "curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64 && chmod +x ./kind && sudo mv ./kind /usr/local/bin/kind"
fi

# Install Skaffold
if [[ "$OS" == "macos" ]]; then
    install_tool "skaffold" "brew install skaffold"
else
    install_tool "skaffold" "curl -Lo skaffold https://storage.googleapis.com/skaffold/releases/latest/skaffold-linux-amd64 && chmod +x skaffold && sudo mv skaffold /usr/local/bin"
fi

echo ""
echo -e "${GREEN}All dependencies installed!${NC}"
echo ""

# Create Kind cluster
CLUSTER_NAME="modernblog-dev"

if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
    echo -e "${GREEN}✓ Kind cluster '${CLUSTER_NAME}' already exists${NC}"
else
    echo -e "${YELLOW}Creating Kind cluster '${CLUSTER_NAME}'...${NC}"
    
    # Create kind config if it doesn't exist
    if [ ! -f "$SCRIPT_DIR/kind-config.yaml" ]; then
        echo -e "${YELLOW}Creating kind-config.yaml...${NC}"
        cat > "$SCRIPT_DIR/kind-config.yaml" <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: modernblog-dev
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 30080
    hostPort: 8080
    protocol: TCP
  - containerPort: 30081
    hostPort: 3000
    protocol: TCP
  # PostgreSQL
  - containerPort: 30432
    hostPort: 5432
    protocol: TCP
EOF
    fi
    
    kind create cluster --config="$SCRIPT_DIR/kind-config.yaml" --name="${CLUSTER_NAME}"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Kind cluster created${NC}"
    else
        echo -e "${RED}Failed to create Kind cluster${NC}"
        exit 1
    fi
fi

# Set kubectl context
kubectl config use-context "kind-${CLUSTER_NAME}"
echo -e "${GREEN}✓ kubectl context set to 'kind-${CLUSTER_NAME}'${NC}"

# Create namespaces
echo -e "${YELLOW}Creating Kubernetes namespaces...${NC}"
kubectl create namespace modernblog-dev --dry-run=client -o yaml | kubectl apply -f -
echo -e "${GREEN}✓ Namespace 'modernblog-dev' ready${NC}"

# Deploy PostgreSQL to Kind cluster
echo ""
echo -e "${YELLOW}Deploying PostgreSQL to Kubernetes...${NC}"
kubectl apply -f "$SCRIPT_DIR/k8s-dev/postgres.yaml"
echo -e "${GREEN}✓ PostgreSQL deployed to cluster${NC}"

echo ""
echo -e "${GREEN}=================================="
echo "Setup Complete!"
echo "=================================="
echo ""
echo "Next steps:"
echo "1. Run 'make dev' to start development with hot reload"
echo "2. Access the app at http://localhost:3000"
echo "3. API is available at http://localhost:8080"
echo "4. PostgreSQL is available at localhost:30432"
echo ""
echo "Useful commands:"
echo "  make dev     - Start development environment"
echo "  make stop    - Stop all services"
echo "  make logs    - View application logs"
echo "  make restart - Restart services"
echo "  make clean   - Remove everything (including data)"
echo ""
echo "Happy coding! 🚀${NC}"