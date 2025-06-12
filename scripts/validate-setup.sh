#!/bin/bash
set -euo pipefail

# Simple validation script for ModernBlog

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Validating ModernBlog setup...${NC}"
echo ""

# Check essential tools
TOOLS=("docker" "kubectl" "kind" "skaffold" "go" "node" "claude-code")
MISSING=()

for tool in "${TOOLS[@]}"; do
    if command -v "$tool" &> /dev/null; then
        echo -e "${GREEN}[OK] $tool installed${NC}"
    else
        echo -e "${RED}[FAIL] $tool not found${NC}"
        MISSING+=("$tool")
    fi
done

# Check Docker daemon
if docker info &> /dev/null; then
    echo -e "${GREEN}[OK] Docker daemon running${NC}"
else
    echo -e "${RED}[FAIL] Docker daemon not running${NC}"
    exit 1
fi

# Check Kind cluster
if kind get clusters 2>/dev/null | grep -q "modernblog-cluster"; then
    echo -e "${GREEN}[OK] Kind cluster exists${NC}"
    
    # Check kubectl connection
    if kubectl cluster-info &> /dev/null; then
        echo -e "${GREEN}[OK] Kubernetes cluster accessible${NC}"
    else
        echo -e "${RED}[FAIL] Cannot connect to Kubernetes cluster${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}[INFO] Kind cluster not found - run setup.sh first${NC}"
fi

echo ""
if [[ ${#MISSING[@]} -gt 0 ]]; then
    echo -e "${RED}Missing tools: ${MISSING[*]}${NC}"
    echo "Run ./setup.sh to install missing tools"
    exit 1
else
    echo -e "${GREEN}All checks passed!${NC}"
fi