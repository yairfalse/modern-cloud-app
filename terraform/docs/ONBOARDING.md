# 📖 ModernBlog Developer Onboarding Guide

**Welcome to the ModernBlog team!** This guide will take you from zero to productive developer in about 30 minutes.

## 🎯 What You'll Accomplish Today

By the end of this guide, you'll have:
- ✅ Complete development environment running locally
- ✅ AI-enhanced development workflow with Claude Code
- ✅ First code contribution ready
- ✅ Understanding of team development practices
- ✅ Access to all development tools and services

## 📋 Prerequisites Checklist

Before starting, ensure you have:
- [ ] **Laptop** with macOS, Windows, or Linux
- [ ] **Admin access** to install software
- [ ] **Internet connection** for downloading tools
- [ ] **GitHub account** with repository access
- [ ] **Google Cloud account** (for cloud deployments)
- [ ] **Claude Code account** (optional but recommended)

## 🚀 Step 1: Repository Setup (5 minutes)

### 1.1 Clone the Repository

```bash
# Clone the repository
git clone https://github.com/your-org/modern-cloud-app.git
cd modern-cloud-app/terraform

# Verify you're in the right place
ls -la
# You should see: Makefile, setup.sh, README.md, etc.
```

### 1.2 Verify Prerequisites

```bash
# Check if git is configured
git config --global user.name
git config --global user.email

# If not configured, set them up
git config --global user.name "Your Name"
git config --global user.email "your.email@company.com"
```

**✅ Success Criteria**: You can see the repository files and git is configured.

---

## ⚙️ Step 2: Automated Setup (5 minutes)

### 2.1 Run the Setup Script

Our automated setup will install and configure everything you need:

```bash
# Run the complete setup
make setup

# This will:
# - Detect your platform (macOS/Linux, x86_64/arm64)
# - Install all required tools via package manager
# - Create local Kubernetes cluster
# - Set up development services
# - Configure AI development environment
```

**What's Being Installed:**
- **Core Tools**: Go, Node.js, Docker, kubectl, Terraform
- **Kubernetes**: Kind (local cluster), Skaffold, Helm, k9s
- **Quality Tools**: golangci-lint, TFLint, pre-commit hooks
- **AI Tools**: Claude Code CLI and VS Code extensions

### 2.2 Monitor Setup Progress

The setup provides real-time feedback:

```bash
🔍 Detecting platform: macOS arm64
📦 Installing core development tools...
   ✅ Go 1.21.5 installed
   ✅ Node.js 20.10.0 installed
   ✅ Docker Desktop installed
🐳 Setting up Kubernetes cluster...
   ✅ Kind cluster 'modernblog-dev' created
   ✅ Ingress controller installed
🚀 Starting development services...
   ✅ PostgreSQL ready on localhost:5432
   ✅ Redis ready on localhost:6379
   ✅ All services healthy
🤖 Configuring AI development...
   ✅ Claude Code CLI installed
   ✅ VS Code configuration applied
✨ Setup complete! Ready to develop.
```

### 2.3 Verify Installation

```bash
# Verify everything is working
make setup-verify

# This will check:
# - All tools are installed and accessible
# - Kubernetes cluster is running
# - All services are healthy
# - AI development is configured
```

**✅ Success Criteria**: All checks pass with green checkmarks.

---

## 🛠 Step 3: Development Environment (5 minutes)

### 3.1 Start Development Mode

```bash
# Start the complete development environment
make dev

# This starts:
# - All local services (PostgreSQL, Redis, etc.)
# - Kubernetes cluster with applications
# - Skaffold for hot reloading
# - Port forwarding for local access
```

### 3.2 Verify Services

Check that all services are running:

```bash
# Check service status
make dev-status

# Expected output:
Service            Status    URL
─────────────────  ────────  ─────────────────────────
ModernBlog Web     ✅ Ready  http://modernblog.local
API Server         ✅ Ready  http://api.modernblog.local
PostgreSQL         ✅ Ready  localhost:5432
Redis              ✅ Ready  localhost:6379
Grafana            ✅ Ready  http://localhost:3000
pgAdmin            ✅ Ready  http://localhost:5050
Jaeger             ✅ Ready  http://localhost:16686
```

### 3.3 Access the Application

Open your browser and visit:

```bash
# Open the main application
open http://modernblog.local

# Or check if it's working
curl -s http://modernblog.local | grep -o "<title>.*</title>"
# Should return: <title>ModernBlog - AI-Enhanced Blogging Platform</title>
```

**✅ Success Criteria**: The ModernBlog application loads in your browser.

---

## 🤖 Step 4: AI Development Setup (5 minutes)

### 4.1 Configure Claude Code

```bash
# Set up Claude Code authentication
make ai-setup

# This will:
# - Install Claude Code CLI
# - Open authentication in browser
# - Configure development context
# - Set up VS Code integration
```

### 4.2 Test AI Integration

```bash
# Test AI assistance
claude "Hello! I'm new to ModernBlog. Can you help me understand the codebase?"

# You should get a helpful response about the project structure
```

### 4.3 Configure VS Code (Recommended)

```bash
# Open the project in VS Code
code .

# Install recommended extensions when prompted:
# - Go extension
# - Terraform extension
# - Claude Code extension
# - Docker extension
# - Kubernetes extension
```

**VS Code will automatically:**
- Load project settings
- Suggest recommended extensions
- Configure debugging for Go and Node.js
- Enable AI assistance integration

**✅ Success Criteria**: Claude Code responds to your questions and VS Code opens with all extensions.

---

## 💻 Step 5: Your First Code Change (10 minutes)

Let's make a small change to verify everything works!

### 5.1 Understand the Project Structure

```bash
# Get AI help understanding the codebase
claude "Show me the main components of this project and where I should look to understand the architecture"

# Or explore manually
ls -la
# Key directories:
# - modules/     - Terraform infrastructure modules
# - dev/         - Local development configuration
# - scripts/     - Setup and utility scripts
```

### 5.2 Make a Small Change

Let's add your name to the development team list:

```bash
# Create a simple change
echo "# Development Team

- **Your Name** - New Team Member ($(date +%Y-%m-%d))
- **Previous Team Members** - Welcome message placeholder

" >> TEAM.md

# Check what we changed
git status
git diff
```

### 5.3 Test Your Change

```bash
# Test that everything still works
make test

# Run linting to ensure code quality
make lint

# If everything passes, you're ready to commit!
```

### 5.4 Commit Your Change

```bash
# Add your changes
git add TEAM.md

# Commit with a good message
git commit -m "docs: add new team member to development team

- Add [Your Name] to TEAM.md
- First contribution to establish development workflow

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"

# Check your commit
git log --oneline -1
```

**✅ Success Criteria**: You successfully made and committed a change.

---

## 📚 Step 6: Understanding the Development Workflow (5 minutes)

### 6.1 Key Development Commands

Memorize these essential commands:

```bash
# Daily development workflow
make dev          # Start development environment
make dev-logs     # View application logs
make test         # Run all tests
make lint         # Run code quality checks
make build        # Build applications
make dev-stop     # Stop development environment

# AI assistance
make ai-help      # Open Claude Code chat
claude "help"     # Quick AI assistance

# Debugging and troubleshooting
make setup-verify # Check environment health
make dev-restart  # Restart if something breaks
```

### 6.2 Hot Reloading Workflow

The development environment supports hot reloading:

```bash
# Start development with hot reloading
make dev

# In another terminal, make a change to any file
# The system will automatically:
# 1. Detect the change
# 2. Rebuild the affected component
# 3. Redeploy to the local cluster
# 4. Update your browser automatically

# Watch the logs to see hot reloading in action
make dev-logs
```

### 6.3 Service Access Reference

Bookmark these URLs for daily development:

| Service | URL | Credentials | Purpose |
|---------|-----|-------------|---------|
| **ModernBlog App** | http://modernblog.local | None | Main application |
| **API Server** | http://api.modernblog.local | None | Backend API |
| **Grafana** | http://localhost:3000 | admin/admin | Metrics dashboard |
| **pgAdmin** | http://localhost:5050 | admin@example.com/admin | Database management |
| **Jaeger** | http://localhost:16686 | None | Distributed tracing |
| **Prometheus** | http://localhost:9090 | None | Metrics collection |

**✅ Success Criteria**: You can access all services and understand the workflow.

---

## 🎯 Step 7: Team Integration (5 minutes)

### 7.1 Communication Channels

Join these team communication channels:
- **Slack**: #modernblog-dev (development discussions)
- **Slack**: #modernblog-deployments (deployment notifications)
- **GitHub**: Watch the repository for notifications
- **Calendar**: Add "ModernBlog Daily Standup" meetings

### 7.2 Development Practices

**Code Review Process:**
1. Create feature branch: `git checkout -b feature/your-feature-name`
2. Make your changes with AI assistance
3. Run tests and linting: `make test lint`
4. Push and create Pull Request
5. Request review from team members
6. AI can help with code review comments

**Commit Message Format:**
```
type(scope): brief description

- Detailed explanation of changes
- Why the change was needed
- Any breaking changes

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>
```

### 7.3 Getting Help

When you need help:

1. **AI First**: `claude "help me with [specific problem]"`
2. **Documentation**: Check `docs/` directory
3. **Team Slack**: Ask in #modernblog-dev
4. **Pair Programming**: Schedule with senior team members

**✅ Success Criteria**: You know where to get help and understand team practices.

---

## 🚀 Next Steps

Congratulations! Your development environment is ready. Here's what to do next:

### Immediate Actions (Today)
- [ ] **Explore the codebase** with AI assistance
- [ ] **Review open issues** and pick a "good first issue"
- [ ] **Join team standup** tomorrow morning
- [ ] **Read [Daily Workflow Guide](DAILY-WORKFLOW.md)** for common tasks

### This Week
- [ ] **Complete your first feature** (team will assign)
- [ ] **Set up cloud deployment access** (staging environment)
- [ ] **Familiarize with monitoring tools** (Grafana dashboards)
- [ ] **Learn the architecture** by reading [Architecture Guide](ARCHITECTURE.md)

### Ongoing Learning
- [ ] **AI Development Mastery**: Read [AI Workflow Guide](AI-WORKFLOW.md)
- [ ] **Troubleshooting Skills**: Keep [Troubleshooting Guide](TROUBLESHOOTING.md) handy
- [ ] **Cloud Platform**: Learn GKE and Terraform for production deployments

## 🆘 Troubleshooting

If anything goes wrong during setup:

### Quick Fixes
```bash
# If setup fails, try again
make clean && make setup

# If services won't start
make dev-restart

# If cluster is broken
kind delete cluster --name modernblog-dev
make setup

# Check what's wrong
make setup-verify
```

### Get Help
- **AI Assistant**: `claude "I'm having trouble with [specific issue]"`
- **Logs**: Check `setup.log` for detailed error messages
- **Team**: Ask in #modernblog-dev Slack channel
- **Documentation**: Check [Troubleshooting Guide](TROUBLESHOOTING.md)

## 🎉 Welcome to the Team!

You're now ready to be a productive member of the ModernBlog development team! 

### Key Points to Remember:
- **AI is your pair programming partner** - use it liberally
- **Hot reloading** gives you instant feedback on changes
- **Local environment mirrors production** - what works locally will work in production
- **Quality is automated** - tests and linting catch issues early
- **Team is here to help** - don't hesitate to ask questions

### Quick Reference Card
```bash
# Start working
make dev

# AI help
claude "help with [task]"

# Test changes
make test lint

# View logs
make dev-logs

# Stop working
make dev-stop
```

**Happy coding with AI assistance!** 🤖✨

---

*Need help? Use `claude "help me with onboarding"` for AI assistance or ask in #modernblog-dev*