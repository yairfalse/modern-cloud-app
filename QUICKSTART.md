# ModernBlog Local Development Quick Start

## Prerequisites
- Docker Desktop installed and running
- macOS with Homebrew (for automatic tool installation)

## 5-Minute Setup

### 1. Start Development Environment
```bash
make dev-up
```

This command will:
- Install required tools (kind, skaffold, kubectl) if not present
- Create a local Kubernetes cluster using Kind
- Deploy PostgreSQL database
- Build and deploy the Go backend with hot reload
- Set up port forwarding

### 2. Access Services
- **Backend API**: http://localhost:8080
- **PostgreSQL**: localhost:5432 (user: postgres, password: postgres123, db: modernblog)

### 3. Check Status
```bash
make dev-status
```

### 4. View Logs
```bash
make dev-logs
```

### 5. Stop Environment
```bash
make dev-down
```

## Development Workflow

### Hot Reload
- Any changes to Go files in `/backend` will automatically trigger a rebuild
- Skaffold watches for file changes and redeploys instantly

### Database Access
```bash
# Connect to PostgreSQL
psql -h localhost -p 5432 -U postgres -d modernblog
# Password: postgres123
```

### API Testing
```bash
# Health check
curl http://localhost:8080/health

# Create a post (example)
curl -X POST http://localhost:8080/api/posts \
  -H "Content-Type: application/json" \
  -d '{"title":"Test Post","content":"Hello World"}'
```

### Restart Backend
```bash
make dev-restart
```

## Troubleshooting

### If port 8080 is already in use:
1. Stop the conflicting service, or
2. Modify `skaffold.yaml` to use a different localPort

### If Kind cluster creation fails:
```bash
# Clean up and retry
docker system prune
kind delete cluster --name modernblog-local
make dev-up
```

### View all resources:
```bash
kubectl get all
```

## Architecture

- **Kind**: Local Kubernetes cluster
- **Skaffold**: Handles building, pushing, and deploying
- **PostgreSQL**: Running as a Kubernetes deployment with persistent storage
- **Backend**: Go API with hot reload support
- **Ingress**: NGINX ingress controller for routing

## Next Steps

1. Add frontend service to `skaffold.yaml`
2. Configure additional microservices
3. Set up local domain names in `/etc/hosts`
4. Add monitoring stack (Prometheus, Grafana)