# 🛠 ModernBlog Troubleshooting Guide

**Quick solutions for common development issues**

This guide provides step-by-step solutions for the most common problems you'll encounter while developing with ModernBlog.

## 🚨 Emergency Quick Fixes

### The Nuclear Option (When Everything Breaks)

```bash
# Stop everything and start fresh (5 minutes)
make dev-stop
make clean
make setup
make dev

# If that doesn't work, the full reset (10 minutes)
kind delete cluster --name modernblog-dev
docker system prune -f
make setup
```

### Quick Health Check

```bash
# Run comprehensive health check
make setup-verify

# Expected output with all ✅:
✅ Docker is running
✅ Kubernetes cluster is healthy
✅ All services are responding
✅ Database is accessible
✅ AI tools are configured
```

---

## 🐳 Docker Issues

### Problem: Docker Not Running

**Symptoms:**
- `docker: command not found`
- `Cannot connect to the Docker daemon`
- `make dev` fails with Docker errors

**Solutions:**

```bash
# macOS: Start Docker Desktop
open -a Docker

# Linux: Start Docker service
sudo systemctl start docker

# Verify Docker is running
docker info
docker ps

# If Docker Desktop is installed but not working
# Restart Docker Desktop from the menu bar
```

### Problem: Docker Out of Space

**Symptoms:**
- `no space left on device`
- `failed to copy files: no space left on device`

**Solutions:**

```bash
# Clean up Docker resources
docker system prune -f

# Clean up everything (including volumes)
docker system prune -a --volumes

# Check disk usage
docker system df

# Remove specific items
docker image prune -f     # Remove unused images
docker container prune -f # Remove stopped containers
docker volume prune -f    # Remove unused volumes
```

### Problem: Port Conflicts

**Symptoms:**
- `port is already allocated`
- `bind: address already in use`

**Solutions:**

```bash
# Find what's using the port
lsof -i :8080    # Replace 8080 with your port
lsof -i :3000    # Check Grafana port
lsof -i :5432    # Check PostgreSQL port

# Kill process using port
kill -9 [PID]

# Or stop ModernBlog first
make dev-stop

# Common conflicting applications
# - Other development servers on :8080/:3000
# - PostgreSQL on :5432
# - Redis on :6379
```

---

## ☸️ Kubernetes Issues

### Problem: Kind Cluster Won't Start

**Symptoms:**
- `kind cluster not found`
- `cluster creation failed`
- `nodes not ready`

**Solutions:**

```bash
# Check if cluster exists
kind get clusters

# Delete and recreate cluster
kind delete cluster --name modernblog-dev
make setup

# If that fails, check Docker
docker ps | grep kind

# Check cluster status
kubectl get nodes
kubectl get pods --all-namespaces
```

### Problem: Pods Stuck in Pending/CrashLoopBackOff

**Symptoms:**
- Pods show `Pending` or `CrashLoopBackOff` status
- Application not accessible

**Solutions:**

```bash
# Check pod status
kubectl get pods

# Get detailed information
kubectl describe pod [pod-name]

# Check logs
kubectl logs [pod-name]
kubectl logs [pod-name] --previous  # Previous container logs

# Common fixes:
# 1. Resource constraints
kubectl top nodes
kubectl top pods

# 2. Image pull issues
kubectl describe pod [pod-name] | grep -i image

# 3. Configuration issues
kubectl get configmaps
kubectl get secrets
```

### Problem: Services Not Accessible

**Symptoms:**
- `curl` commands fail
- Browser shows connection errors
- Services show in `kubectl get svc` but not accessible

**Solutions:**

```bash
# Check service configuration
kubectl get services
kubectl describe service [service-name]

# Check ingress configuration
kubectl get ingress
kubectl describe ingress [ingress-name]

# Test internal connectivity
kubectl exec -it [pod-name] -- curl http://[service-name]:[port]

# Check DNS resolution
kubectl exec -it [pod-name] -- nslookup [service-name]

# Restart ingress controller
kubectl rollout restart deployment/ingress-nginx-controller -n ingress-nginx
```

---

## 🗄 Database Issues

### Problem: Cannot Connect to PostgreSQL

**Symptoms:**
- `connection refused` errors
- `make shell-db` fails
- Application logs show database connection errors

**Solutions:**

```bash
# Check if PostgreSQL is running
docker-compose -f dev/docker-compose.dev.yml ps postgres

# Restart PostgreSQL
docker-compose -f dev/docker-compose.dev.yml restart postgres

# Check logs
docker-compose -f dev/docker-compose.dev.yml logs postgres

# Test connection manually
psql -h localhost -U postgres -d modernblog -p 5432

# If password issues, check environment variables
echo $DATABASE_URL
```

### Problem: Database Migration Failures

**Symptoms:**
- Application won't start due to migration errors
- Database schema out of sync

**Solutions:**

```bash
# Check migration status
make db-migrate-status

# Reset database (development only!)
make db-reset

# Run migrations manually
make db-migrate

# If using AI assistance
claude "Help me debug this database migration error"
```

### Problem: Database Performance Issues

**Symptoms:**
- Slow database queries
- High CPU usage from PostgreSQL
- Timeouts in application

**Solutions:**

```bash
# Check current connections
make shell-db
# In psql:
SELECT * FROM pg_stat_activity;

# Check slow queries
SELECT * FROM pg_stat_statements ORDER BY total_time DESC LIMIT 10;

# Restart database
docker-compose -f dev/docker-compose.dev.yml restart postgres

# Use AI for query optimization
claude "This query is slow, help me optimize it: [your query]"
```

---

## 🌐 Network and DNS Issues

### Problem: Can't Access http://modernblog.local

**Symptoms:**
- Browser shows "This site can't be reached"
- `curl` fails with connection errors

**Solutions:**

```bash
# Check if ingress is running
kubectl get ingress

# Check if services are accessible
kubectl get services

# Test internal connectivity
kubectl port-forward service/web-frontend 8080:80
# Then visit http://localhost:8080

# Check DNS configuration
cat /etc/hosts | grep modernblog
# Should contain: 127.0.0.1 modernblog.local api.modernblog.local

# Add manually if missing
echo "127.0.0.1 modernblog.local api.modernblog.local" | sudo tee -a /etc/hosts

# Flush DNS cache
# macOS:
sudo dscacheutil -flushcache
# Linux:
sudo systemctl restart systemd-resolved
```

### Problem: SSL/TLS Certificate Issues

**Symptoms:**
- Browser shows certificate warnings
- HTTPS not working locally

**Solutions:**

```bash
# Check certificate status
kubectl get certificates

# Restart cert-manager if installed
kubectl rollout restart deployment/cert-manager -n cert-manager

# For local development, use HTTP
curl -k https://modernblog.local  # -k ignores SSL errors

# Regenerate local certificates
make certs-generate
```

---

## 🔧 Build and Deployment Issues

### Problem: Build Failures

**Symptoms:**
- `make build` fails
- Go compilation errors
- Node.js build errors

**Solutions:**

```bash
# Check Go version and dependencies
go version
go mod tidy
go mod download

# Check Node.js version and dependencies
node --version
npm --version
npm install

# Clean build cache
go clean -cache
npm ci  # Clean install

# Use AI for build issues
claude "Help me fix this build error: [error message]"
```

### Problem: Skaffold Hot Reloading Not Working

**Symptoms:**
- Changes not reflected automatically
- Manual restart required after code changes

**Solutions:**

```bash
# Check Skaffold status
skaffold dev --port-forward

# Restart Skaffold
pkill skaffold
make dev

# Check file sync configuration
cat dev/skaffold.yaml | grep -A 10 sync

# Check if files are being watched
skaffold dev --verbosity=debug
```

### Problem: Image Pull Failures

**Symptoms:**
- `ImagePullBackOff` errors
- Unable to pull container images

**Solutions:**

```bash
# Check image names and tags
kubectl describe pod [pod-name] | grep -i image

# Check if images exist locally
docker images | grep modernblog

# Build images locally
make build

# Load images into Kind cluster
kind load docker-image [image-name] --name modernblog-dev
```

---

## 🤖 AI and Tool Issues

### Problem: Claude Code Not Working

**Symptoms:**
- `claude: command not found`
- Authentication errors
- AI responses not helpful

**Solutions:**

```bash
# Install Claude Code CLI
make ai-setup

# Check authentication status
claude-code auth status

# Re-authenticate
claude-code auth login

# Test basic functionality
claude "Hello, can you help me?"

# Check for updates
claude-code update
```

### Problem: VS Code Extensions Not Working

**Symptoms:**
- Go/Terraform syntax highlighting missing
- IntelliSense not working
- Debugging not available

**Solutions:**

```bash
# Open VS Code in project directory
code .

# Install recommended extensions
# VS Code will prompt for recommended extensions

# Manually install key extensions:
# - Go extension
# - Terraform extension
# - Docker extension
# - Kubernetes extension

# Reload VS Code
# Cmd+Shift+P -> "Developer: Reload Window"
```

---

## 🔍 Performance Issues

### Problem: Slow Development Environment

**Symptoms:**
- Long startup times
- Slow hot reloading
- High CPU/memory usage

**Solutions:**

```bash
# Check resource usage
docker stats
kubectl top nodes
kubectl top pods

# Reduce resource allocation (if needed)
# Edit dev/kind-config.yaml to reduce cluster size

# Close unnecessary applications
# Stop other Docker containers
docker ps
docker stop [container-id]

# Restart with clean slate
make dev-stop
make dev
```

### Problem: Out of Memory Errors

**Symptoms:**
- Pods get killed with OOMKilled
- System becomes unresponsive

**Solutions:**

```bash
# Check memory usage
free -h                    # Linux
vm_stat                    # macOS

# Check pod resource limits
kubectl describe pod [pod-name] | grep -A 5 -B 5 memory

# Increase Docker Desktop memory allocation
# Docker Desktop -> Settings -> Resources -> Memory

# Reduce local cluster size
# Edit dev/kind-config.yaml
```

---

## 🔐 Security and Permission Issues

### Problem: Permission Denied Errors

**Symptoms:**
- `permission denied` when running commands
- Unable to write files
- Docker permission errors

**Solutions:**

```bash
# Fix Docker permissions (Linux)
sudo usermod -aG docker $USER
newgrp docker

# Fix file permissions
sudo chown -R $USER:$USER .

# Check directory permissions
ls -la

# For Kubernetes RBAC issues
kubectl auth can-i [verb] [resource]
kubectl get clusterroles
kubectl get rolebindings
```

### Problem: Secret/ConfigMap Issues

**Symptoms:**
- Application can't access configuration
- Environment variables not set

**Solutions:**

```bash
# Check secrets and configmaps
kubectl get secrets
kubectl get configmaps

# Describe to see contents
kubectl describe secret [secret-name]
kubectl describe configmap [configmap-name]

# Recreate if needed
kubectl delete secret [secret-name]
kubectl create secret generic [secret-name] --from-literal=key=value
```

---

## 📊 Monitoring and Logging Issues

### Problem: Grafana Not Accessible

**Symptoms:**
- http://localhost:3000 not working
- Login page not loading

**Solutions:**

```bash
# Check if Grafana is running
docker-compose -f dev/docker-compose.dev.yml ps grafana

# Restart Grafana
docker-compose -f dev/docker-compose.dev.yml restart grafana

# Check logs
docker-compose -f dev/docker-compose.dev.yml logs grafana

# Default credentials: admin/admin
```

### Problem: Missing Logs

**Symptoms:**
- `make dev-logs` shows no output
- Application logs not appearing

**Solutions:**

```bash
# Check if logging is configured
kubectl get pods
kubectl logs [pod-name]

# Check logging configuration
cat dev/docker-compose.dev.yml | grep -A 5 logging

# Restart logging services
kubectl rollout restart deployment/fluent-bit
docker-compose -f dev/docker-compose.dev.yml restart prometheus
```

---

## 🎯 Common Error Messages and Solutions

### "Failed to create cluster"

```bash
# Usually a Docker issue
docker system prune -f
make setup
```

### "No such host" errors

```bash
# DNS/hosts file issue
echo "127.0.0.1 modernblog.local api.modernblog.local" | sudo tee -a /etc/hosts
```

### "Port already in use"

```bash
# Find and kill conflicting process
lsof -i :[port]
kill -9 [PID]
```

### "Database connection refused"

```bash
# Restart database
docker-compose -f dev/docker-compose.dev.yml restart postgres
```

### "Image pull failed"

```bash
# Build and load images
make build
kind load docker-image [image] --name modernblog-dev
```

### "Certificate not found"

```bash
# Regenerate certificates
make certs-generate
kubectl rollout restart deployment/cert-manager
```

---

## 🆘 Getting Help

### Self-Help Checklist

Before asking for help, try:
- [ ] Run `make setup-verify`
- [ ] Check `setup.log` for error details
- [ ] Try the "nuclear option" reset
- [ ] Search this troubleshooting guide
- [ ] Ask AI: `claude "Help me debug [specific error]"`

### AI Assistance

```bash
# Describe your problem to AI
claude "I'm getting this error: [error message]. How do I fix it?"

# Get AI help with logs
claude "Analyze these logs and tell me what's wrong: [paste logs]"

# Ask for step-by-step debugging
claude "Walk me through debugging [specific issue]"
```

### Team Help

When all else fails:
1. **Document your issue**: What you tried, error messages, logs
2. **Create minimal reproduction**: Steps to reproduce the problem  
3. **Ask in Slack**: #modernblog-dev channel
4. **Pair with senior developer**: Schedule debugging session

### Creating Good Bug Reports

Include:
- **Environment**: OS, Docker version, etc.
- **Steps to reproduce**: Exact commands run
- **Expected vs actual behavior**
- **Error messages**: Full error text
- **Logs**: Relevant log entries
- **What you tried**: Solutions attempted

---

## 🔄 Prevention Tips

### Daily Maintenance

```bash
# Weekly cleanup (Fridays)
make clean-docker
docker system prune -f

# Keep tools updated
brew upgrade        # macOS
apt update && apt upgrade  # Linux

# Validate environment health
make setup-verify
```

### Best Practices

- **Always run tests before committing**: `make test lint`
- **Don't commit secrets**: Use `.env` files, never commit them
- **Keep dependencies updated**: Regular `go mod tidy`, `npm update`
- **Monitor resource usage**: Check `docker stats` periodically
- **Use AI for early problem detection**: Regular code reviews with Claude

### Early Warning Signs

Watch for these indicators of potential issues:
- Slow startup times
- High memory usage in `docker stats`
- Frequent pod restarts in `kubectl get pods`
- Disk space warnings
- Network timeouts

---

## 📋 Quick Reference

### Essential Debugging Commands

```bash
# System health
make setup-verify
make dev-status

# Service status
docker-compose -f dev/docker-compose.dev.yml ps
kubectl get pods
kubectl get services

# Logs
make dev-logs
kubectl logs [pod-name]
docker-compose -f dev/docker-compose.dev.yml logs [service]

# Resource usage
docker stats
kubectl top nodes
kubectl top pods

# Network
kubectl get ingress
lsof -i :[port]
curl -v http://modernblog.local

# Reset options
make dev-restart        # Soft reset
make clean && make setup  # Hard reset
kind delete cluster --name modernblog-dev  # Nuclear option
```

### Emergency Contacts

- **Immediate help**: `claude "Emergency! Help me with [issue]"`
- **Team Slack**: #modernblog-dev
- **Senior developers**: Available during business hours
- **Documentation**: All guides in `docs/` directory

---

**Remember**: Most issues can be solved with AI assistance first! Try `claude "help me debug [your issue]"` before escalating. 🤖