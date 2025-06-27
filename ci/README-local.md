# ModernBlog Local Development Setup - No Philosophy Required

A simple, robust local development environment that actually works.

**Target Audience**: Developers who overthink simple concepts and need step-by-step instructions.

## What You Get

- ✅ Local Kubernetes cluster (Kind)
- ✅ Hot reload for Go backend and React frontend
- ✅ PostgreSQL and Redis running locally
- ✅ One command setup
- ✅ Zero cloud costs during development

## Quick Start

```bash
# 1. Run the setup script (idempotent, safe to run multiple times)
./setup.sh

# 2. Start development with hot reload
make dev

# 3. Access your app
# Frontend: http://localhost:3000
# Backend API: http://localhost:8080
```

That's it. No philosophy, no complex configurations.

## What Just Happened?

1. **setup.sh** installed tools and created a Kind cluster
2. **docker-compose** started PostgreSQL and Redis locally
3. **skaffold** built and deployed your app with hot reload enabled
4. Port forwarding connected everything together

## Development Commands

```bash
# Main commands
make dev          # Start development environment
make stop         # Stop all services
make logs         # View application logs
make restart      # Restart everything
make clean        # Nuclear option - removes everything

# Debug commands
make status       # Show what's running
make db-shell     # Connect to PostgreSQL
make backend-logs # Backend logs only
make frontend-logs # Frontend logs only
```

## File Structure

```
ci/
├── setup.sh              # Main installer
├── Makefile              # Development commands
├── docker-compose.yml    # Local services (PostgreSQL, Redis)
├── skaffold.yaml         # Hot reload configuration
├── kind-config.yaml      # Kubernetes cluster config
├── k8s-dev/              # Kubernetes manifests
│   ├── backend.yaml
│   └── frontend.yaml
└── README-local.md       # This file
```

## How Hot Reload Works

### Go Backend
- Changes to `*.go` files trigger rebuild
- Go mod changes also trigger rebuild
- Usually takes 5-10 seconds

### React Frontend
- Changes to `src/` files trigger rebuild
- Package.json changes trigger full rebuild
- Usually takes 2-5 seconds

## Database Access

### PostgreSQL
- **Host**: localhost:5432
- **Database**: modernblog_dev
- **User**: modernblog
- **Password**: dev_password_123

```bash
# Connect via CLI
make db-shell

# Connect via any GUI tool
Host: localhost
Port: 5432
Database: modernblog_dev
User: modernblog
Password: dev_password_123
```

### Redis
- **Host**: localhost:6379
- **Password**: None

```bash
# Connect via CLI
make redis-cli
```

## Environment Variables

Backend automatically gets these environment variables:

```bash
PORT=8080
DB_HOST=host.docker.internal
DB_PORT=5432
DB_NAME=modernblog_dev
DB_USER=modernblog
DB_PASSWORD=dev_password_123
REDIS_HOST=host.docker.internal
REDIS_PORT=6379
ENV=development
```

Frontend gets:
```bash
REACT_APP_API_URL=http://localhost:8080
NODE_ENV=development
```

## Troubleshooting

### "Docker is not running"
Start Docker Desktop and try again.

### "Kind cluster already exists"
The setup script is idempotent. It will use the existing cluster.

### "Port already in use"
```bash
# Stop everything and try again
make stop
make dev
```

### "Database connection failed"
```bash
# Check if PostgreSQL is running
docker ps | grep postgres

# If not running, restart services
make stop
make dev
```

### "Hot reload not working"
```bash
# Check Skaffold logs
make logs

# Restart development environment
make restart
```

### "I broke everything"
```bash
# Nuclear option - removes everything including data
make clean

# Then start fresh
./setup.sh
make dev
```

## What's Different from Production?

- Uses Kind instead of managed Kubernetes
- Database runs in Docker, not as a managed service
- No ingress controller, just port forwarding
- No secrets management, just environment variables
- No monitoring or logging aggregation

This is intentional. Local development should be simple.

## Requirements

- Docker Desktop
- macOS or Linux
- Internet connection (for tool downloads)

The setup script will install:
- kubectl
- Kind
- Skaffold

## Tips

1. **First time setup takes longer** - subsequent runs are faster
2. **Leave `make dev` running** - it watches for changes
3. **Use separate terminal tabs** - one for `make dev`, one for commands
4. **Database data persists** - survives restarts, but not `make clean`
5. **Check `make status`** - if confused about what's running

## Next Steps

1. Edit your Go code - watch it rebuild automatically
2. Edit your React code - watch it rebuild automatically
3. Use `make db-shell` to run database migrations
4. Use `make logs` to debug issues
5. Use `make clean` if you want to start fresh

## Anti-Goals

This setup intentionally does NOT:
- Replicate production exactly
- Use complex networking
- Implement advanced Kubernetes features
- Optimize for performance
- Handle edge cases perfectly

It's good enough for development. You can improve it later.

## Support

If something doesn't work:

1. Check the error message
2. Try `make status`
3. Try `make restart`
4. Try `make clean` and start over
5. Check if Docker is running
6. Check if you have internet connection

The error messages are designed to be helpful, not cryptic.