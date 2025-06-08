# ModernBlog Development Environment Setup Guide

🚀 **Complete 5-minute setup for AI-enhanced cloud-native development**

## Quick Start

```bash
# Clone and setup
git clone <repository-url>
cd modern-cloud-app/terraform

# Run the complete setup
make setup

# Start development
make dev
```

## What Gets Installed

### Core Development Tools
- **Go 1.21+** - Backend development
- **Node.js 20+** - Frontend development  
- **Docker Desktop** - Containerization
- **kubectl** - Kubernetes CLI
- **Terraform** - Infrastructure as Code

### Kubernetes & Cloud Tools
- **Kind** - Local Kubernetes clusters
- **Skaffold** - Continuous development
- **Helm** - Package management
- **k9s** - Kubernetes TUI

### Code Quality Tools
- **golangci-lint** - Go code linting
- **TFLint** - Terraform linting
- **Pre-commit hooks** - Automated quality checks

### AI-Enhanced Development
- **Claude Code** - AI pair programming
- **VS Code configuration** - Optimized IDE setup
- **Development aliases** - Productivity shortcuts

## Local Services

The setup includes these local services via Docker Compose:

| Service | URL | Purpose |
|---------|-----|---------|
| PostgreSQL | localhost:5432 | Primary database |
| Redis | localhost:6379 | Caching & sessions |
| MinIO | localhost:9000 | S3-compatible storage |
| Grafana | localhost:3000 | Metrics dashboard |
| Prometheus | localhost:9090 | Metrics collection |
| Jaeger | localhost:16686 | Distributed tracing |
| pgAdmin | localhost:5050 | Database admin |
| Mailhog | localhost:8025 | Email testing |

## Kubernetes Cluster

- **Cluster Name**: `modernblog-dev`
- **Namespaces**: `modernblog-dev`, `modernblog-staging`, `monitoring`
- **Ingress**: NGINX with SSL termination
- **DNS**: `modernblog.local`, `api.modernblog.local`

## Development Workflow

### 1. Start Development Environment
```bash
make dev
```
This starts:
- Local services (PostgreSQL, Redis, etc.)
- Kubernetes cluster
- Skaffold for hot reloading
- Port forwarding for local access

### 2. Code Quality
```bash
make test      # Run all tests
make lint      # Run all linters
make fmt       # Format code
```

### 3. Build & Deploy
```bash
make build        # Build applications
make deploy-dev   # Deploy to development
```

## AI Development with Claude Code

### Setup Authentication
```bash
make ai-setup
# Or directly: claude-code auth login
```

### AI-Assisted Development
```bash
make ai-help      # Open Claude Code chat
claude           # Direct AI assistance
```

### VS Code Integration
- Install recommended extensions
- Claude Code extension for AI pair programming
- Optimized settings for Go and Terraform

## Useful Commands

### Development
```bash
make dev-logs     # View application logs
make dev-restart  # Restart development environment
make dev-stop     # Stop development environment
```

### Database & Services
```bash
make shell-db     # Open database shell
make shell-api    # Shell into API pod
```

### Cleanup
```bash
make clean        # Clean all artifacts
make clean-docker # Clean Docker images
make clean-k8s    # Clean Kubernetes resources
```

## Troubleshooting

### Setup Issues
```bash
make setup-verify  # Validate setup
./scripts/validate-setup.sh  # Detailed validation
```

### Common Issues

**Docker not running**
```bash
# macOS: Start Docker Desktop
open -a Docker

# Verify: 
docker info
```

**Cluster issues**
```bash
# Recreate cluster
kind delete cluster --name modernblog-dev
make setup
```

**Port conflicts**
```bash
# Check what's using ports
lsof -i :8080
lsof -i :3000
```

## Configuration Files

### Key Files Created
- `setup.sh` - Main setup orchestrator
- `Makefile` - Development commands
- `dev/kind-config.yaml` - Kubernetes cluster config
- `dev/docker-compose.dev.yml` - Local services
- `dev/skaffold.yaml` - Development workflow
- `.vscode/` - VS Code configuration
- `CLAUDE.md` - AI development context

### Platform Detection
The setup automatically detects:
- Operating system (macOS/Linux)
- Architecture (x86_64/arm64)
- Package manager (brew/apt/yum)
- Available resources

## Next Steps

1. **Authenticate Claude Code**: `claude-code auth login`
2. **Start development**: `make dev`
3. **Open VS Code**: Install recommended extensions
4. **Access services**: Visit http://modernblog.local

## Support

- **Documentation**: Check `CLAUDE.md` for project context
- **AI Help**: Use `make ai-help` or `claude` command
- **Validation**: Run `make setup-verify` to check environment
- **Logs**: Check `setup.log` for detailed setup information

## Architecture Overview

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Developer     │───▶│  Claude Code     │───▶│  AI Assistant   │
│   Workspace     │    │  Integration     │    │  & Context      │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │
         ▼
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Local K8s     │◀──▶│   Skaffold       │◀──▶│   Docker        │
│   (Kind)        │    │   Workflow       │    │   Services      │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   ModernBlog    │    │   Hot Reload     │    │   PostgreSQL    │
│   Application   │    │   & Testing      │    │   Redis, etc.   │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

Ready to build amazing cloud-native applications with AI assistance! 🎉