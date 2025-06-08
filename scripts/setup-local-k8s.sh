#!/bin/bash
set -euo pipefail

# Kubernetes setup script for ModernBlog

CLUSTER_NAME="modernblog-cluster"
K8S_VERSION="v1.29.0"

check_prerequisites() {
    log_info "Checking Kubernetes prerequisites..."
    
    # Check if Docker is running
    if ! docker info &> /dev/null; then
        log_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi
    
    # Check if Kind is installed
    if ! command -v kind &> /dev/null; then
        log_error "Kind is not installed. Please run install-tools.sh first."
        exit 1
    fi
    
    # Check if kubectl is installed
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl is not installed. Please run install-tools.sh first."
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

create_cluster() {
    log_info "Creating Kind cluster: $CLUSTER_NAME"
    
    # Check if cluster already exists
    if kind get clusters | grep -q "^$CLUSTER_NAME$"; then
        log_warning "Cluster $CLUSTER_NAME already exists"
        
        # Check if cluster is healthy
        if kubectl cluster-info --context "kind-$CLUSTER_NAME" &> /dev/null; then
            log_success "Existing cluster is healthy"
            return 0
        else
            log_warning "Existing cluster is unhealthy, recreating..."
            kind delete cluster --name "$CLUSTER_NAME"
        fi
    fi
    
    # Create cluster with config file
    kind create cluster \
        --name "$CLUSTER_NAME" \
        --config "${SCRIPT_DIR}/dev/kind-config.yaml" \
        --image "kindest/node:$K8S_VERSION"
    
    # Wait for cluster to be ready
    log_info "Waiting for cluster to be ready..."
    kubectl wait --for=condition=Ready nodes --all --timeout=300s
    
    log_success "Kind cluster created successfully"
}

install_ingress_controller() {
    log_info "Installing NGINX Ingress Controller..."
    
    # Install NGINX Ingress Controller
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
    
    # Wait for ingress controller to be ready
    log_info "Waiting for ingress controller to be ready..."
    kubectl wait --namespace ingress-nginx \
        --for=condition=ready pod \
        --selector=app.kubernetes.io/component=controller \
        --timeout=300s
    
    log_success "NGINX Ingress Controller installed"
}

setup_local_registry() {
    log_info "Setting up local container registry..."
    
    # Check if registry is already running
    if docker ps --format "table {{.Names}}" | grep -q "kind-registry"; then
        log_success "Local registry already running"
        return 0
    fi
    
    # Create registry container unless it already exists
    if ! docker ps -a --format "table {{.Names}}" | grep -q "kind-registry"; then
        docker run -d --restart=always -p "5001:5000" --name "kind-registry" registry:2
    else
        docker start kind-registry
    fi
    
    # Connect the registry to the cluster network if not already connected
    if [ "$(docker inspect -f='{{json .NetworkSettings.Networks.kind}}' kind-registry)" = 'null' ]; then
        docker network connect "kind" "kind-registry"
    fi
    
    # Document the local registry
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: local-registry-hosting
  namespace: kube-public
data:
  localRegistryHosting.v1: |
    host: "localhost:5001"
    help: "https://kind.sigs.k8s.io/docs/user/local-registry/"
EOF
    
    log_success "Local registry setup complete"
}

install_cert_manager() {
    log_info "Installing cert-manager..."
    
    # Install cert-manager
    kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.3/cert-manager.yaml
    
    # Wait for cert-manager to be ready
    log_info "Waiting for cert-manager to be ready..."
    kubectl wait --namespace cert-manager \
        --for=condition=ready pod \
        --selector=app.kubernetes.io/instance=cert-manager \
        --timeout=300s
    
    log_success "cert-manager installed"
}

setup_monitoring() {
    log_info "Setting up monitoring namespace..."
    
    # Create monitoring namespace
    kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
    
    # Create ModernBlog namespace
    kubectl create namespace modernblog --dry-run=client -o yaml | kubectl apply -f -
    
    log_success "Namespaces created"
}

configure_kubectl() {
    log_info "Configuring kubectl context..."
    
    # Set current context
    kubectl config use-context "kind-$CLUSTER_NAME"
    
    # Set default namespace
    kubectl config set-context --current --namespace=modernblog
    
    log_success "kubectl configured"
}

create_development_secrets() {
    log_info "Creating development secrets..."
    
    # Create database secret
    kubectl create secret generic postgres-secret \
        --from-literal=username=modernblog \
        --from-literal=password=modernblog123 \
        --from-literal=database=modernblog \
        --namespace=modernblog \
        --dry-run=client -o yaml | kubectl apply -f -
    
    # Create redis secret
    kubectl create secret generic redis-secret \
        --from-literal=password="" \
        --namespace=modernblog \
        --dry-run=client -o yaml | kubectl apply -f -
    
    # Create minio secret
    kubectl create secret generic minio-secret \
        --from-literal=access-key=minioadmin \
        --from-literal=secret-key=minioadmin123 \
        --namespace=modernblog \
        --dry-run=client -o yaml | kubectl apply -f -
    
    log_success "Development secrets created"
}

verify_cluster() {
    log_info "Verifying cluster setup..."
    
    # Check cluster info
    kubectl cluster-info
    
    # Check nodes
    kubectl get nodes -o wide
    
    # Check system pods
    kubectl get pods -A
    
    log_success "Cluster verification complete"
}

main() {
    log_info "Setting up local Kubernetes cluster..."
    
    check_prerequisites
    create_cluster
    install_ingress_controller
    setup_local_registry
    install_cert_manager
    setup_monitoring
    configure_kubectl
    create_development_secrets
    verify_cluster
    
    echo ""
    log_success "🎉 Local Kubernetes cluster setup complete!"
    echo ""
    echo "Cluster Information:"
    echo "  Name: $CLUSTER_NAME"
    echo "  Context: kind-$CLUSTER_NAME"
    echo "  Registry: localhost:5001"
    echo "  Ingress: localhost:80, localhost:443"
    echo ""
    echo "Quick commands:"
    echo "  kubectl get nodes"
    echo "  kubectl get pods -A"
    echo "  kubectl config current-context"
    echo ""
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