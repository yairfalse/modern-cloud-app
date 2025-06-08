# ⚡ ModernBlog Daily Development Workflow

**Your go-to guide for day-to-day development with ModernBlog**

This guide covers the commands and workflows you'll use every day as a ModernBlog developer.

## 🌅 Starting Your Day

### Morning Routine (2 minutes)

```bash
# 1. Navigate to project
cd modern-cloud-app/terraform

# 2. Pull latest changes
git pull origin main

# 3. Start development environment
make dev

# 4. Verify everything is working
make dev-status
```

**Expected Output:**
```
✅ All services healthy
✅ Kubernetes cluster ready
✅ Hot reloading enabled
🚀 Development environment ready!
```

### Quick Health Check

```bash
# Check if everything is running properly
curl -s http://modernblog.local/health | jq .status
# Should return: "healthy"

# Or open in browser
open http://modernblog.local
```

---

## 💻 Core Development Commands

### Essential Daily Commands

| Command | Purpose | When to Use |
|---------|---------|-------------|
| `make dev` | Start development environment | Beginning of work session |
| `make dev-status` | Check service health | When something seems off |
| `make dev-logs` | View application logs | Debugging issues |
| `make test` | Run all tests | Before committing code |
| `make lint` | Run code quality checks | Before committing code |
| `make build` | Build applications | Testing production builds |
| `make dev-stop` | Stop development environment | End of work session |

### Git Workflow Commands

```bash
# Create new feature branch
git checkout -b feature/your-feature-name

# Check what you've changed
git status
git diff

# Stage and commit changes
git add .
git commit -m "feat: your descriptive commit message"

# Push and create PR
git push -u origin feature/your-feature-name
gh pr create --title "Your Feature Title" --body "Description of changes"
```

---

## 🔄 Development Workflow Patterns

### Pattern 1: Feature Development

```bash
# 1. Start with a clean environment
make dev

# 2. Create feature branch
git checkout -b feature/add-blog-comments

# 3. AI-assisted development
claude "Help me implement blog comments feature"

# 4. Make changes with hot reloading
# Edit files - changes appear automatically!

# 5. Test your changes
make test
make lint

# 6. Commit and push
git add .
git commit -m "feat: add blog comments functionality

- Add comments API endpoints
- Implement comment UI components
- Add comment database migrations

🤖 Generated with Claude Code"

git push -u origin feature/add-blog-comments

# 7. Create pull request
gh pr create --title "Add blog comments functionality"
```

### Pattern 2: Bug Fixing

```bash
# 1. Reproduce the bug
make dev
# Navigate to the problem area

# 2. Use AI to help diagnose
claude "I'm seeing [describe issue]. Help me debug this."

# 3. Check logs for clues
make dev-logs | grep ERROR

# 4. Make targeted fix
# Edit the problematic code

# 5. Verify fix works
make test
curl -s http://modernblog.local/api/endpoint | jq

# 6. Commit fix
git commit -m "fix: resolve [issue description]"
```

### Pattern 3: Code Review

```bash
# 1. Pull latest changes
git pull origin main

# 2. Checkout the PR branch
git checkout feature/colleague-feature

# 3. Start development environment
make dev

# 4. Test the changes
make test
# Manual testing in browser

# 5. Use AI for code review
claude "Review this pull request for potential issues"

# 6. Provide feedback
gh pr review --approve
# or
gh pr review --request-changes --body "Comments here"
```

---

## 🛠 Service Management

### Starting and Stopping Services

```bash
# Start everything
make dev

# Start only specific services
docker-compose -f dev/docker-compose.dev.yml up postgres redis

# Stop everything
make dev-stop

# Restart if something breaks
make dev-restart

# Reset everything (nuclear option)
make clean && make setup
```

### Service Access Quick Reference

```bash
# Application URLs
open http://modernblog.local          # Main app
open http://api.modernblog.local      # API server
open http://localhost:3000            # Grafana (admin/admin)
open http://localhost:5050            # pgAdmin (admin@example.com/admin)
open http://localhost:16686           # Jaeger tracing

# Database access
make shell-db                         # PostgreSQL shell
redis-cli                            # Redis shell

# Kubernetes access
kubectl get pods                      # List running pods
k9s                                  # Kubernetes TUI
```

### Log Monitoring

```bash
# View all application logs
make dev-logs

# View specific service logs
kubectl logs -f deployment/api-server
kubectl logs -f deployment/web-frontend

# View infrastructure logs
docker-compose -f dev/docker-compose.dev.yml logs -f postgres
docker-compose -f dev/docker-compose.dev.yml logs -f redis

# Filter logs for errors
make dev-logs | grep -i error
make dev-logs | grep -i "level=error"
```

---

## 🤖 AI-Enhanced Development

### Using Claude Code Daily

```bash
# Start AI assistance
claude

# Common AI workflows
claude "Help me implement [feature]"
claude "Why is [component] not working?"
claude "Optimize this function for performance"
claude "Write tests for this feature"
claude "Review this code for security issues"
```

### AI Development Patterns

**Code Generation:**
```bash
# Generate boilerplate
claude "Create a new API endpoint for user preferences"
claude "Generate a React component for displaying blog posts"
claude "Write a Terraform module for S3 bucket"
```

**Debugging:**
```bash
# Debug issues
claude "This API call is returning 500 error, help me debug"
claude "The frontend component isn't rendering, what could be wrong?"
claude "Database query is slow, how can I optimize it?"
```

**Code Review:**
```bash
# Self-review before committing
claude "Review my changes for potential issues"
claude "Are there any security concerns with this code?"
claude "Can you suggest improvements to this implementation?"
```

### VS Code Integration

Use these keyboard shortcuts for AI assistance:
- `Cmd+K` / `Ctrl+K`: Ask Claude about selected code
- `Cmd+Shift+P` → "Claude": Access Claude Code commands
- `F1` → "Claude Generate": Generate code from comments

---

## 🧪 Testing Workflows

### Running Tests

```bash
# Run all tests
make test

# Run specific test suites
make test-api         # Backend API tests
make test-frontend    # Frontend tests
make test-e2e         # End-to-end tests

# Run tests with coverage
make test-coverage

# Run tests in watch mode (during development)
make test-watch
```

### Quality Checks

```bash
# Run all quality checks
make lint

# Run specific linters
make lint-go          # Go code linting
make lint-js          # JavaScript/TypeScript linting
make lint-terraform   # Terraform linting

# Auto-fix issues where possible
make fmt              # Format all code
make lint-fix         # Auto-fix linting issues
```

### Testing in Development Environment

```bash
# Test API endpoints
curl -X GET http://api.modernblog.local/api/v1/posts | jq
curl -X POST http://api.modernblog.local/api/v1/posts \
  -H "Content-Type: application/json" \
  -d '{"title":"Test Post","content":"Test content"}'

# Test frontend functionality
open http://modernblog.local
# Navigate through the application manually

# Test with different data
make seed-dev-data    # Populate with test data
make reset-dev-data   # Reset to clean state
```

---

## 🚀 Deployment Workflows

### Local Development Deployment

```bash
# Deploy to local Kubernetes
make deploy-dev

# Check deployment status
kubectl get pods
kubectl get services

# Update deployment with new changes
# Changes are applied automatically with Skaffold hot reloading
```

### Staging Environment Deployment

```bash
# Deploy to staging (requires GCP access)
make deploy-staging

# Check staging deployment
kubectl get pods --context=staging
open https://staging.modernblog.example.com

# Run staging tests
make test-staging
```

### Production Deployment (Senior Developers)

```bash
# Production deployment (requires approval)
make deploy-prod

# Verify production health
make health-check-prod
```

---

## 🔍 Debugging Workflows

### Common Debugging Commands

```bash
# Check system health
make dev-status
make setup-verify

# Debug specific issues
kubectl describe pod [pod-name]        # Pod issues
kubectl logs -f [pod-name]            # Application logs
docker logs [container-id]            # Docker container logs

# Database debugging
make shell-db                         # Access database
psql -h localhost -U postgres -d modernblog -c "SELECT * FROM posts LIMIT 5;"

# Network debugging
kubectl get ingress                   # Check ingress configuration
curl -v http://modernblog.local       # Test connectivity
```

### Performance Debugging

```bash
# Monitor resource usage
kubectl top pods                      # Kubernetes resource usage
docker stats                         # Docker container stats

# Application performance
open http://localhost:3000            # Grafana metrics
open http://localhost:16686           # Jaeger tracing

# Database performance
make shell-db
# In psql: EXPLAIN ANALYZE SELECT * FROM posts;
```

---

## 📊 Monitoring and Observability

### Daily Monitoring Tasks

```bash
# Check application health
curl -s http://modernblog.local/health | jq

# View metrics dashboard
open http://localhost:3000
# Navigate to ModernBlog dashboard

# Check for errors
make dev-logs | grep -i error | tail -10

# Monitor performance
open http://localhost:16686
# Search for recent traces
```

### Creating Custom Metrics

```bash
# Use AI to help add metrics
claude "Help me add a custom metric to track user signups"

# Add monitoring for new features
claude "How do I add Prometheus metrics to this new API endpoint?"
```

---

## 🛡 Security and Best Practices

### Daily Security Checks

```bash
# Check for security issues
make security-scan                    # Run security scanners
make deps-audit                      # Check dependency vulnerabilities

# Verify secrets aren't committed
git diff --cached | grep -i "password\|secret\|key"
```

### Code Quality Practices

```bash
# Before every commit
make test lint                        # Verify tests pass and code is clean
git diff --check                     # Check for whitespace issues

# Use AI for code review
claude "Review this code for security issues and best practices"
```

---

## 🔧 Troubleshooting Quick Fixes

### When Things Break

```bash
# Services won't start
make dev-restart

# Kubernetes cluster issues
kind delete cluster --name modernblog-dev
make setup

# Database connection issues
docker-compose -f dev/docker-compose.dev.yml restart postgres
make shell-db  # Test connection

# Port conflicts
lsof -i :8080                        # Check what's using the port
make dev-stop                        # Stop everything
make dev                            # Restart
```

### Getting Help

```bash
# AI assistance
claude "I'm having trouble with [specific issue], help me debug"

# Check documentation
ls docs/                             # Available documentation
cat docs/TROUBLESHOOTING.md          # Specific troubleshooting guide

# Team help
# Ask in #modernblog-dev Slack channel
# Ping senior developers for urgent issues
```

---

## 📈 Productivity Tips

### Aliases and Shortcuts

Add these to your shell profile (`.bashrc`, `.zshrc`):

```bash
# ModernBlog shortcuts
alias mb="cd /path/to/modern-cloud-app/terraform"
alias mbd="make dev"
alias mbs="make dev-status"
alias mbl="make dev-logs"
alias mbt="make test lint"
alias mbr="make dev-restart"

# Git shortcuts
alias gs="git status"
alias gd="git diff"
alias gc="git commit"
alias gp="git push"

# Kubernetes shortcuts
alias k="kubectl"
alias kgp="kubectl get pods"
alias kgs="kubectl get services"
```

### VS Code Snippets

Create custom snippets for common patterns:
- API endpoint boilerplate
- React component templates
- Terraform resource blocks
- Test function templates

### AI Productivity

```bash
# Save common AI prompts
claude "Show me the standard patterns for [common task]"
claude "Generate boilerplate for [type of component]"
claude "What's the best practice for [specific scenario]"
```

---

## 🎯 End-of-Day Routine

### Before You Leave (2 minutes)

```bash
# 1. Commit any work in progress
git add .
git commit -m "wip: work in progress on [feature]"

# 2. Push to backup your work
git push

# 3. Stop development environment to save resources
make dev-stop

# 4. Check for any important updates
git fetch
git status
```

### Weekly Maintenance

```bash
# Clean up Docker resources (Fridays)
make clean-docker

# Update dependencies (as needed)
make update-deps

# Review and clean up feature branches
git branch | grep feature/
# Delete merged branches: git branch -d feature/old-feature
```

---

## 📋 Command Reference

### Quick Command Cheat Sheet

```bash
# Environment
make dev              # Start development
make dev-stop         # Stop development  
make dev-restart      # Restart development
make dev-status       # Check health
make dev-logs         # View logs

# Code Quality
make test             # Run tests
make lint             # Run linting
make fmt              # Format code
make build            # Build applications

# AI Assistance
claude               # Start AI chat
make ai-help         # Quick AI assistance

# Deployment
make deploy-dev      # Deploy to local k8s
make deploy-staging  # Deploy to staging

# Debugging
make shell-db        # Database shell
make setup-verify    # Verify environment
k9s                  # Kubernetes TUI
```

### Environment Variables

```bash
# Common environment variables you might need
export MODERNBLOG_ENV=development
export LOG_LEVEL=debug
export DATABASE_URL=postgres://postgres:password@localhost:5432/modernblog
export REDIS_URL=redis://localhost:6379
```

---

**Remember**: When in doubt, use `claude "help me with [your question]"` for instant AI assistance! 🤖

**Need more help?** Check out:
- [Troubleshooting Guide](TROUBLESHOOTING.md) for specific issues
- [Architecture Guide](ARCHITECTURE.md) for understanding the system
- [AI Workflow Guide](AI-WORKFLOW.md) for advanced AI usage