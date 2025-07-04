.PHONY: dev-up dev-down dev-logs dev-status install-tools

# Install required tools
install-tools:
	@echo "Installing required tools..."
	@which kind > /dev/null || (echo "Installing kind..." && brew install kind)
	@which skaffold > /dev/null || (echo "Installing skaffold..." && brew install skaffold)
	@which kubectl > /dev/null || (echo "Installing kubectl..." && brew install kubectl)
	@echo "All tools installed!"

# Start local development environment
dev-up: install-tools
	@echo "Setting up PostgreSQL..."
	@./scripts/setup-postgres.sh
	@echo "Starting Kind cluster..."
	@kind get clusters | grep -q modernblog-local || kind create cluster --name modernblog-local --config kind-config.yaml
	@echo "Installing NGINX Ingress Controller..."
	@kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
	@echo "Waiting for ingress controller to be ready..."
	@kubectl wait --namespace ingress-nginx \
		--for=condition=ready pod \
		--selector=app.kubernetes.io/component=controller,app.kubernetes.io/instance=ingress-nginx \
		--timeout=90s
	@echo "Starting Skaffold..."
	@skaffold dev --port-forward

# Stop local development environment
dev-down:
	@echo "Stopping Skaffold..."
	@pkill skaffold || true
	@echo "Deleting Kind cluster..."
	@kind delete cluster --name modernblog-local
	@echo "Development environment stopped!"

# View logs
dev-logs:
	@kubectl logs -f deployment/backend

# Check status
dev-status:
	@echo "=== Cluster Info ==="
	@kubectl cluster-info --context kind-modernblog-local
	@echo "\n=== Pods ==="
	@kubectl get pods
	@echo "\n=== Services ==="
	@kubectl get services
	@echo "\n=== Ingress ==="
	@kubectl get ingress
	@echo "\n=== API Access ==="
	@echo "Backend API: http://localhost:8080"
	@echo "PostgreSQL: localhost:5432"

# Quick restart of backend
dev-restart:
	@kubectl rollout restart deployment/backend
	@kubectl rollout status deployment/backend