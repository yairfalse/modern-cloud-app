#!/bin/bash
set -euo pipefail

# Kubernetes setup script for ModernBlog development
# Creates Kind cluster with ingress and monitoring

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Configuration
CLUSTER_NAME="${KIND_CLUSTER_NAME:-modernblog-dev}"
K8S_VERSION="${K8S_VERSION:-1.29.0}"
SETUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KIND_CONFIG="$SETUP_DIR/dev/kind-config.yaml"

check_docker() {
    if ! docker info &> /dev/null; then
        echo -e "${RED}✗ Docker is not running${NC}"
        echo -e "${YELLOW}Please start Docker and try again${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ Docker is running${NC}"
}

check_existing_cluster() {
    if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
        echo -e "${YELLOW}⚠ Cluster '${CLUSTER_NAME}' already exists${NC}"
        read -p "Delete existing cluster and create new one? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${BLUE}Deleting existing cluster...${NC}"
            kind delete cluster --name "$CLUSTER_NAME"
        else
            echo -e "${GREEN}✓ Using existing cluster${NC}"
            kubectl config use-context "kind-${CLUSTER_NAME}"
            return 0
        fi
    fi
    return 1
}

create_kind_cluster() {
    echo -e "${BLUE}Creating Kind cluster '${CLUSTER_NAME}'...${NC}"
    
    # Create cluster with config
    if [[ -f "$KIND_CONFIG" ]]; then
        kind create cluster \
            --name "$CLUSTER_NAME" \
            --image "kindest/node:v${K8S_VERSION}" \
            --config "$KIND_CONFIG" \
            --wait 60s
    else
        echo -e "${YELLOW}⚠ Kind config not found, using defaults${NC}"
        kind create cluster \
            --name "$CLUSTER_NAME" \
            --image "kindest/node:v${K8S_VERSION}" \
            --wait 60s
    fi
    
    # Set kubectl context
    kubectl config use-context "kind-${CLUSTER_NAME}"
    
    echo -e "${GREEN}✓ Kind cluster created${NC}"
}

install_ingress_nginx() {
    echo -e "${BLUE}Installing NGINX Ingress Controller...${NC}"
    
    # Install ingress-nginx
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
    
    # Wait for ingress to be ready
    echo "Waiting for ingress controller to be ready..."
    kubectl wait --namespace ingress-nginx \
        --for=condition=ready pod \
        --selector=app.kubernetes.io/component=controller \
        --timeout=120s
    
    echo -e "${GREEN}✓ NGINX Ingress Controller installed${NC}"
}

install_metrics_server() {
    echo -e "${BLUE}Installing Metrics Server...${NC}"
    
    # Install metrics-server
    kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
    
    # Patch metrics-server for Kind
    kubectl patch -n kube-system deployment metrics-server --type=json \
        -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'
    
    echo -e "${GREEN}✓ Metrics Server installed${NC}"
}

create_namespaces() {
    echo -e "${BLUE}Creating development namespaces...${NC}"
    
    # Create namespaces
    kubectl create namespace modernblog-dev --dry-run=client -o yaml | kubectl apply -f -
    kubectl create namespace modernblog-staging --dry-run=client -o yaml | kubectl apply -f -
    kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
    
    # Label namespaces
    kubectl label namespace modernblog-dev environment=development --overwrite
    kubectl label namespace modernblog-staging environment=staging --overwrite
    kubectl label namespace monitoring environment=monitoring --overwrite
    
    # Set default namespace
    kubectl config set-context --current --namespace=modernblog-dev
    
    echo -e "${GREEN}✓ Namespaces created${NC}"
}

install_local_storage() {
    echo -e "${BLUE}Setting up local storage...${NC}"
    
    # Create StorageClass for local development
    cat <<EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-path
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: rancher.io/local-path
volumeBindingMode: WaitForFirstConsumer
reclaimPolicy: Delete
EOF
    
    echo -e "${GREEN}✓ Local storage configured${NC}"
}

configure_dns() {
    echo -e "${BLUE}Configuring local DNS...${NC}"
    
    # Get ingress IP
    local ingress_ip="127.0.0.1"
    
    # Add to /etc/hosts if not already present
    if ! grep -q "modernblog.local" /etc/hosts; then
        echo -e "${YELLOW}Adding modernblog.local to /etc/hosts (requires sudo)${NC}"
        echo "$ingress_ip modernblog.local api.modernblog.local admin.modernblog.local" | sudo tee -a /etc/hosts
    fi
    
    echo -e "${GREEN}✓ Local DNS configured${NC}"
    echo "  Access your app at: http://modernblog.local"
}

install_cert_manager() {
    echo -e "${BLUE}Installing cert-manager...${NC}"
    
    # Install cert-manager
    kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.3/cert-manager.yaml
    
    # Wait for cert-manager to be ready
    echo "Waiting for cert-manager to be ready..."
    kubectl wait --namespace cert-manager \
        --for=condition=ready pod \
        --selector=app.kubernetes.io/instance=cert-manager \
        --timeout=120s
    
    # Create self-signed issuer for local development
    cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: selfsigned-issuer
spec:
  selfSigned: {}
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: modernblog-local-tls
  namespace: modernblog-dev
spec:
  secretName: modernblog-local-tls
  issuerRef:
    name: selfsigned-issuer
    kind: ClusterIssuer
  commonName: modernblog.local
  dnsNames:
  - modernblog.local
  - "*.modernblog.local"
EOF
    
    echo -e "${GREEN}✓ cert-manager installed${NC}"
}

create_dev_secrets() {
    echo -e "${BLUE}Creating development secrets...${NC}"
    
    # Create database secret
    kubectl create secret generic modernblog-db-secret \
        --namespace modernblog-dev \
        --from-literal=username=modernblog \
        --from-literal=password=dev-password-123 \
        --from-literal=database=modernblog_dev \
        --dry-run=client -o yaml | kubectl apply -f -
    
    # Create Redis secret
    kubectl create secret generic modernblog-redis-secret \
        --namespace modernblog-dev \
        --from-literal=password=redis-dev-password \
        --dry-run=client -o yaml | kubectl apply -f -
    
    # Create JWT secret
    kubectl create secret generic modernblog-jwt-secret \
        --namespace modernblog-dev \
        --from-literal=secret=dev-jwt-secret-key-123456789 \
        --dry-run=client -o yaml | kubectl apply -f -
    
    echo -e "${GREEN}✓ Development secrets created${NC}"
}

print_cluster_info() {
    echo ""
    echo -e "${BLUE}=== Kubernetes Cluster Information ===${NC}"
    echo "Cluster Name: $CLUSTER_NAME"
    echo "Context: kind-$CLUSTER_NAME"
    echo "Kubernetes Version: $K8S_VERSION"
    echo ""
    echo "Access URLs:"
    echo "  • Application: http://modernblog.local"
    echo "  • API: http://api.modernblog.local"
    echo "  • Admin: http://admin.modernblog.local"
    echo ""
    echo "Useful commands:"
    echo "  • kubectl get pods -n modernblog-dev"
    echo "  • kubectl logs -n modernblog-dev -f deployment/modernblog-api"
    echo "  • k9s -n modernblog-dev"
    echo ""
}

save_kubeconfig() {
    echo -e "${BLUE}Saving kubeconfig...${NC}"
    
    # Export kubeconfig
    local kubeconfig_dir="$HOME/.kube/configs"
    mkdir -p "$kubeconfig_dir"
    
    kind get kubeconfig --name "$CLUSTER_NAME" > "$kubeconfig_dir/kind-${CLUSTER_NAME}.yaml"
    
    echo -e "${GREEN}✓ Kubeconfig saved to $kubeconfig_dir/kind-${CLUSTER_NAME}.yaml${NC}"
}

main() {
    echo -e "${BLUE}=== Setting up Local Kubernetes ===${NC}"
    echo ""
    
    # Check Docker
    check_docker
    
    # Check for existing cluster
    if ! check_existing_cluster; then
        # Create Kind cluster
        create_kind_cluster
        
        # Install components
        install_ingress_nginx
        install_metrics_server
        install_cert_manager
        install_local_storage
    fi
    
    # Setup namespaces and configs
    create_namespaces
    create_dev_secrets
    configure_dns
    save_kubeconfig
    
    # Print cluster information
    print_cluster_info
    
    echo -e "${GREEN}✓ Kubernetes setup complete${NC}"
}

main "$@"