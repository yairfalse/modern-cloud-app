#!/bin/bash

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

CLUSTER_NAME="modernblog-cluster"

echo -e "${YELLOW}Setting up Kind cluster...${NC}"

# Check prerequisites
if ! docker info &>/dev/null; then
    echo -e "${RED}ERROR: Docker not running${NC}"
    exit 1
fi

if ! command -v kind &>/dev/null; then
    echo -e "${RED}ERROR: Kind not installed${NC}"
    exit 1
fi

if ! command -v kubectl &>/dev/null; then
    echo -e "${RED}ERROR: kubectl not installed${NC}"
    exit 1
fi

# Check if cluster exists
if kind get clusters 2>/dev/null | grep -q "^$CLUSTER_NAME$"; then
    echo -e "${YELLOW}Cluster $CLUSTER_NAME already exists${NC}"
    if kubectl cluster-info --context "kind-$CLUSTER_NAME" &>/dev/null; then
        echo -e "${GREEN}[OK] Cluster is healthy${NC}"
        exit 0
    else
        echo -e "${YELLOW}Recreating unhealthy cluster...${NC}"
        kind delete cluster --name "$CLUSTER_NAME"
    fi
fi

# Create cluster
echo -e "${YELLOW}Creating Kind cluster...${NC}"
kind create cluster \
    --name "$CLUSTER_NAME" \
    --config "dev/kind-config.yaml" \
    --wait 300s

# Install ingress controller
echo -e "${YELLOW}Installing ingress controller...${NC}"
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# Wait for ingress controller
echo -e "${YELLOW}Waiting for ingress controller...${NC}"
kubectl wait --namespace ingress-nginx \
    --for=condition=ready pod \
    --selector=app.kubernetes.io/component=controller \
    --timeout=300s

# Create namespace
kubectl create namespace modernblog --dry-run=client -o yaml | kubectl apply -f -

# Set context
kubectl config use-context "kind-$CLUSTER_NAME"
kubectl config set-context --current --namespace=modernblog

echo -e "${GREEN}Kind cluster ready!${NC}"
echo "Context: kind-$CLUSTER_NAME"
echo "Namespace: modernblog"