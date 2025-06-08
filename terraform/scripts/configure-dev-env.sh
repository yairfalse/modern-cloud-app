#!/bin/bash
set -euo pipefail

# Development environment configuration script
# Sets up git hooks, IDE configs, and development tools

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

SETUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

setup_git_hooks() {
    echo -e "${BLUE}Setting up Git hooks...${NC}"
    
    local hooks_dir="$SETUP_DIR/.git/hooks"
    
    # Pre-commit hook
    cat > "$hooks_dir/pre-commit" << 'EOF'
#!/bin/bash
set -e

echo "Running pre-commit checks..."

# Check Go files
if git diff --cached --name-only | grep -q '\.go$'; then
    echo "Checking Go files..."
    go fmt ./...
    go vet ./...
    golangci-lint run
fi

# Check Terraform files
if git diff --cached --name-only | grep -q '\.tf$'; then
    echo "Checking Terraform files..."
    terraform fmt -recursive .
    tflint
fi

# Check for secrets
if git diff --cached --name-only | xargs grep -l "password\|secret\|key" 2>/dev/null; then
    echo "Warning: Potential secrets detected in staged files"
    echo "Please review before committing"
fi

echo "Pre-commit checks passed!"
EOF
    
    # Pre-push hook
    cat > "$hooks_dir/pre-push" << 'EOF'
#!/bin/bash
set -e

echo "Running pre-push checks..."

# Run tests if they exist
if [[ -f "Makefile" ]] && grep -q "test:" Makefile; then
    echo "Running tests..."
    make test
fi

echo "Pre-push checks passed!"
EOF
    
    # Make hooks executable
    chmod +x "$hooks_dir/pre-commit"
    chmod +x "$hooks_dir/pre-push"
    
    echo -e "${GREEN}✓ Git hooks configured${NC}"
}

setup_go_tools() {
    echo -e "${BLUE}Setting up Go development tools...${NC}"
    
    if command -v go &> /dev/null; then
        # Install useful Go tools
        go install github.com/cosmtrek/air@latest
        go install github.com/swaggo/swag/cmd/swag@latest
        go install github.com/pressly/goose/v3/cmd/goose@latest
        go install github.com/sqlc-dev/sqlc/cmd/sqlc@latest
        
        echo -e "${GREEN}✓ Go tools installed${NC}"
    else
        echo -e "${YELLOW}⚠ Go not found, skipping Go tools${NC}"
    fi
}

create_vscode_config() {
    echo -e "${BLUE}Creating VS Code configuration...${NC}"
    
    local vscode_dir="$SETUP_DIR/.vscode"
    mkdir -p "$vscode_dir"
    
    # Settings
    cat > "$vscode_dir/settings.json" << 'EOF'
{
  "go.toolsManagement.checkForUpdates": "local",
  "go.useLanguageServer": true,
  "go.formatTool": "goimports",
  "go.lintTool": "golangci-lint",
  "go.lintFlags": [
    "--fast"
  ],
  "terraform.languageServer": {
    "enabled": true,
    "args": [
      "serve"
    ]
  },
  "files.associations": {
    "*.yaml": "yaml",
    "*.yml": "yaml"
  },
  "yaml.schemas": {
    "https://json.schemastore.org/github-workflow.json": "/.github/workflows/*"
  },
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.organizeImports": true
  },
  "files.exclude": {
    "**/.git": true,
    "**/.svn": true,
    "**/.hg": true,
    "**/CVS": true,
    "**/.DS_Store": true,
    "**/Thumbs.db": true,
    "**/.terraform": true,
    "**/.terraform.lock.hcl": false,
    "**/node_modules": true,
    "**/vendor": true
  }
}
EOF
    
    # Extensions recommendations
    cat > "$vscode_dir/extensions.json" << 'EOF'
{
  "recommendations": [
    "golang.go",
    "hashicorp.terraform",
    "ms-kubernetes-tools.vscode-kubernetes-tools",
    "ms-vscode.vscode-json",
    "redhat.vscode-yaml",
    "ms-vscode-remote.remote-containers",
    "github.copilot",
    "github.copilot-chat",
    "anthropic.claude-dev",
    "ms-vscode.makefile-tools",
    "formulahendry.docker-explorer",
    "ms-azuretools.vscode-docker"
  ]
}
EOF
    
    # Launch configurations
    cat > "$vscode_dir/launch.json" << 'EOF'
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Launch API Server",
      "type": "go",
      "request": "launch",
      "mode": "auto",
      "program": "${workspaceFolder}/cmd/api",
      "env": {
        "ENV": "development",
        "DB_HOST": "localhost",
        "DB_PORT": "5432",
        "DB_USER": "modernblog",
        "DB_PASSWORD": "dev-password-123",
        "DB_NAME": "modernblog_dev",
        "REDIS_HOST": "localhost",
        "REDIS_PORT": "6379"
      },
      "args": []
    },
    {
      "name": "Attach to Process",
      "type": "go",
      "request": "attach",
      "mode": "local",
      "processId": "${command:pickProcess}"
    }
  ]
}
EOF
    
    # Tasks
    cat > "$vscode_dir/tasks.json" << 'EOF'
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "build",
      "type": "shell",
      "command": "make",
      "args": ["build"],
      "group": {
        "kind": "build",
        "isDefault": true
      },
      "presentation": {
        "echo": true,
        "reveal": "always",
        "focus": false,
        "panel": "shared"
      },
      "problemMatcher": ["$go"]
    },
    {
      "label": "test",
      "type": "shell",
      "command": "make",
      "args": ["test"],
      "group": {
        "kind": "test",
        "isDefault": true
      },
      "presentation": {
        "echo": true,
        "reveal": "always",
        "focus": false,
        "panel": "shared"
      },
      "problemMatcher": ["$go"]
    },
    {
      "label": "dev",
      "type": "shell",
      "command": "make",
      "args": ["dev"],
      "group": "build",
      "presentation": {
        "echo": true,
        "reveal": "always",
        "focus": false,
        "panel": "dedicated"
      },
      "isBackground": true,
      "problemMatcher": {
        "owner": "go",
        "fileLocation": ["relative", "${workspaceFolder}"],
        "pattern": {
          "regexp": "^(.*):(\\d+):(\\d+):\\s+(warning|error):\\s+(.*)$",
          "file": 1,
          "line": 2,
          "column": 3,
          "severity": 4,
          "message": 5
        },
        "background": {
          "activeOnStart": true,
          "beginsPattern": "^.*restarting due to changes...$",
          "endsPattern": "^.*started successfully.*$"
        }
      }
    }
  ]
}
EOF
    
    echo -e "${GREEN}✓ VS Code configuration created${NC}"
}

setup_editorconfig() {
    echo -e "${BLUE}Creating .editorconfig...${NC}"
    
    cat > "$SETUP_DIR/.editorconfig" << 'EOF'
root = true

[*]
charset = utf-8
end_of_line = lf
insert_final_newline = true
trim_trailing_whitespace = true
indent_style = space
indent_size = 2

[*.go]
indent_style = tab
indent_size = 4

[*.{tf,tfvars}]
indent_size = 2

[*.{yaml,yml}]
indent_size = 2

[*.md]
trim_trailing_whitespace = false

[Makefile]
indent_style = tab
EOF
    
    echo -e "${GREEN}✓ .editorconfig created${NC}"
}

setup_gitignore() {
    echo -e "${BLUE}Updating .gitignore...${NC}"
    
    cat >> "$SETUP_DIR/.gitignore" << 'EOF'

# ModernBlog Development Environment
.modernblog/
setup.log
data/

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Logs
*.log
logs/

# Environment files
.env
.env.local
.env.development
.env.test
.env.production

# Dependencies
node_modules/
vendor/

# Build artifacts
dist/
build/
bin/
*.exe

# Terraform
.terraform/
.terraform.lock.hcl
terraform.tfstate*
*.tfplan

# Go
*.test
*.out
coverage.txt

# Database
*.db
*.sqlite
*.sqlite3

# Certificates
*.pem
*.key
*.crt

# Temporary files
tmp/
temp/
EOF
    
    echo -e "${GREEN}✓ .gitignore updated${NC}"
}

create_dev_aliases() {
    echo -e "${BLUE}Creating development aliases...${NC}"
    
    local aliases_file="$HOME/.modernblog/aliases.sh"
    
    cat > "$aliases_file" << 'EOF'
#!/bin/bash
# ModernBlog Development Aliases

# Kubernetes aliases
alias k="kubectl"
alias kgp="kubectl get pods"
alias kgs="kubectl get svc"
alias kgd="kubectl get deploy"
alias kd="kubectl describe"
alias kl="kubectl logs"
alias ke="kubectl exec -it"

# Development workflow
alias mb-dev="make dev"
alias mb-test="make test"
alias mb-build="make build"
alias mb-deploy="make deploy-dev"

# Database
alias mb-db="kubectl exec -it deployment/postgres -n modernblog-dev -- psql -U modernblog modernblog_dev"
alias mb-redis="kubectl exec -it deployment/redis -n modernblog-dev -- redis-cli"

# Logs
alias mb-api-logs="kubectl logs -f deployment/modernblog-api -n modernblog-dev"
alias mb-web-logs="kubectl logs -f deployment/modernblog-web -n modernblog-dev"

# Kind cluster
alias mb-cluster-start="kind create cluster --name modernblog-dev --config dev/kind-config.yaml"
alias mb-cluster-stop="kind delete cluster --name modernblog-dev"
alias mb-cluster-status="kind get clusters"

# Docker
alias mb-images="docker images | grep modernblog"
alias mb-clean="docker system prune -f"

# AI Development
alias claude="claude-code"
alias ai-help="claude-code chat"
EOF
    
    # Add to shell profile
    local shell_profile=""
    if [[ -f "$HOME/.zshrc" ]]; then
        shell_profile="$HOME/.zshrc"
    elif [[ -f "$HOME/.bashrc" ]]; then
        shell_profile="$HOME/.bashrc"
    elif [[ -f "$HOME/.bash_profile" ]]; then
        shell_profile="$HOME/.bash_profile"
    fi
    
    if [[ -n "$shell_profile" ]]; then
        echo "" >> "$shell_profile"
        echo "# ModernBlog Development Aliases" >> "$shell_profile"
        echo "source $aliases_file" >> "$shell_profile"
        echo -e "${GREEN}✓ Aliases added to $shell_profile${NC}"
    fi
}

setup_golangci_lint_config() {
    echo -e "${BLUE}Creating golangci-lint configuration...${NC}"
    
    cat > "$SETUP_DIR/.golangci.yml" << 'EOF'
run:
  timeout: 5m
  modules-download-mode: readonly

linters-settings:
  gci:
    local-prefixes: github.com/modernblog
  goconst:
    min-len: 2
    min-occurrences: 2
  gocritic:
    enabled-tags:
      - diagnostic
      - experimental
      - opinionated
      - performance
      - style
    disabled-checks:
      - dupImport
      - ifElseChain
      - octalLiteral
      - whyNoLint
      - wrapperFunc
  gocyclo:
    min-complexity: 15
  godot:
    scope: declarations
    capital: false
  gofmt:
    simplify: true
  goimports:
    local-prefixes: github.com/modernblog
  golint:
    min-confidence: 0
  gomnd:
    settings:
      mnd:
        checks: argument,case,condition,operation,return,assign
  govet:
    check-shadowing: true
  lll:
    line-length: 140
  maligned:
    suggest-new: true
  misspell:
    locale: US
  nolintlint:
    allow-leading-space: true
    allow-unused: false
    require-explanation: false
    require-specific: false

linters:
  enable:
    - bodyclose
    - deadcode
    - depguard
    - dogsled
    - dupl
    - errcheck
    - funlen
    - gochecknoinits
    - goconst
    - gocritic
    - gocyclo
    - gofmt
    - goimports
    - golint
    - gomnd
    - goprintffuncname
    - gosec
    - gosimple
    - govet
    - ineffassign
    - interfacer
    - lll
    - misspell
    - nakedret
    - noctx
    - nolintlint
    - rowserrcheck
    - scopelint
    - staticcheck
    - structcheck
    - stylecheck
    - typecheck
    - unconvert
    - unparam
    - unused
    - varcheck
    - whitespace

issues:
  exclude-rules:
    - path: _test\.go
      linters:
        - gomnd
        - funlen
        - gocyclo

  exclude-use-default: false
  max-issues-per-linter: 0
  max-same-issues: 0
EOF
    
    echo -e "${GREEN}✓ golangci-lint configuration created${NC}"
}

setup_claude_code_config() {
    echo -e "${BLUE}Creating Claude Code configuration...${NC}"
    
    local claude_dir="$HOME/.config/claude-code"
    mkdir -p "$claude_dir"
    
    cat > "$claude_dir/config.json" << 'EOF'
{
  "default_model": "claude-3-5-sonnet-20241022",
  "editor": "code",
  "auto_save": true,
  "context_files": [
    "README.md",
    "Makefile",
    "go.mod",
    "package.json",
    "terraform.tfvars.example"
  ],
  "ignore_patterns": [
    ".git",
    "node_modules",
    "vendor",
    ".terraform",
    "*.log",
    "data/"
  ]
}
EOF
    
    # Create CLAUDE.md for project context
    cat > "$SETUP_DIR/CLAUDE.md" << 'EOF'
# ModernBlog Development Context

## Project Overview
ModernBlog is a modern, cloud-native blogging platform built with Go, React, and Kubernetes.

## Architecture
- **Backend**: Go with Gin framework
- **Frontend**: React with TypeScript
- **Database**: PostgreSQL
- **Cache**: Redis
- **Infrastructure**: Kubernetes on GCP
- **CI/CD**: GitHub Actions with Dagger

## Development Environment
- Kind cluster for local Kubernetes
- Skaffold for development workflow
- Docker for containerization
- Terraform for infrastructure

## Key Directories
- `cmd/`: Go application entrypoints
- `internal/`: Go application code
- `web/`: React frontend
- `k8s/`: Kubernetes manifests
- `terraform/`: Infrastructure code
- `dev/`: Development configuration

## Common Tasks
- `make dev`: Start development environment
- `make test`: Run all tests
- `make build`: Build application
- `make deploy-dev`: Deploy to development

## Environment Variables
See `terraform.tfvars.example` for configuration options.

## Authentication
Use `claude-code auth login` to authenticate with Claude Code.
EOF
    
    echo -e "${GREEN}✓ Claude Code configuration created${NC}"
}

main() {
    echo -e "${BLUE}=== Configuring Development Environment ===${NC}"
    echo ""
    
    # Git configuration
    setup_git_hooks
    setup_gitignore
    
    # Development tools
    setup_go_tools
    setup_golangci_lint_config
    
    # IDE configuration
    create_vscode_config
    setup_editorconfig
    
    # Development convenience
    create_dev_aliases
    
    # AI-enhanced development
    setup_claude_code_config
    
    echo ""
    echo -e "${BLUE}=== Development Environment Tips ===${NC}"
    echo "1. Install VS Code extensions: Cmd/Ctrl+Shift+P -> 'Extensions: Show Recommended Extensions'"
    echo "2. Authenticate Claude Code: claude-code auth login"
    echo "3. Restart your terminal to load aliases"
    echo "4. Use 'ai-help' for AI assistance during development"
    echo ""
    echo -e "${GREEN}✓ Development environment configured${NC}"
}

main "$@"