#!/bin/bash

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}Setting up minimal Kind cluster...${NC}"

# Check Docker
if ! docker info &>/dev/null; then
    echo -e "${RED}ERROR: Docker not running${NC}"
    exit 1
fi

# Check Kind
if ! command -v kind &>/dev/null; then
    echo -e "${RED}ERROR: Kind not installed${NC}"
    exit 1
fi

# Delete existing cluster if present
if kind get clusters 2>/dev/null | grep -q "^kind$"; then
    echo "Removing existing cluster..."
    kind delete cluster
fi

# Create cluster
echo "Creating Kind cluster..."
kind create cluster --config dev/kind-config.yaml --wait 30s

# Install nginx ingress (minimal)
echo "Installing nginx ingress..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# Quick check - don't wait for full readiness
echo "Ingress controller deployed (will be ready in ~60s)"

echo -e "${GREEN}✓ Kind cluster ready!${NC}"
kubectl cluster-info --context kind-kind