#!/bin/bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 ModernBlog Setup - Simple & Fast${NC}"
echo "==============================================="

# Check if we're in the right directory
if [[ ! -f "setup.sh" ]]; then
    echo -e "${RED}❌ Please run this script from the project root directory${NC}"
    exit 1
fi

# Install essential tools
echo -e "${YELLOW}📦 Installing essential tools...${NC}"
./scripts/install-tools.sh

# Setup local Kubernetes cluster
echo -e "${YELLOW}☸️ Setting up Kind cluster...${NC}"
./scripts/setup-local-k8s.sh

# Basic validation
echo -e "${YELLOW}✅ Running basic validation...${NC}"
if ! kubectl cluster-info &>/dev/null; then
    echo -e "${RED}❌ Kubernetes cluster not accessible${NC}"
    exit 1
fi

if ! docker info &>/dev/null; then
    echo -e "${RED}❌ Docker not running${NC}"
    exit 1
fi

echo -e "${GREEN}🎉 Setup complete!${NC}"
echo ""
echo "Next steps:"
echo "  1. cd to frontend/ or backend/ directory"
echo "  2. Run 'skaffold dev' to start development"
echo "  3. Open http://localhost:8080 in your browser"
echo ""
echo "Useful commands:"
echo "  make dev-start    - Start development with skaffold"
echo "  make dev-stop     - Stop development environment"
echo "  make status       - Check cluster status"