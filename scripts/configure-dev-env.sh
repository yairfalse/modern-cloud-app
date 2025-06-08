#!/bin/bash
set -euo pipefail

# Development environment configuration script for ModernBlog

setup_directories() {
    log_info "Setting up project directories..."
    
    local dirs=(
        "$HOME/.modernblog"
        "$HOME/.modernblog/cache"
        "$HOME/.modernblog/logs"
        "${SCRIPT_DIR}/data"
        "${SCRIPT_DIR}/data/postgres"
        "${SCRIPT_DIR}/data/redis"
        "${SCRIPT_DIR}/data/minio"
        "${SCRIPT_DIR}/data/grafana"
        "${SCRIPT_DIR}/logs"
    )
    
    for dir in "${dirs[@]}"; do
        mkdir -p "$dir"
    done
    
    log_success "Project directories created"
}

configure_git() {
    log_info "Configuring Git settings..."
    
    # Check if Git is configured
    if ! git config --global user.name &> /dev/null; then
        log_warning "Git user.name not set. Please configure:"
        echo "  git config --global user.name \"Your Name\""
    fi
    
    if ! git config --global user.email &> /dev/null; then
        log_warning "Git user.email not set. Please configure:"
        echo "  git config --global user.email \"your.email@example.com\""
    fi
    
    # Set up useful Git aliases
    git config --global alias.st status
    git config --global alias.co checkout
    git config --global alias.br branch
    git config --global alias.ci commit
    git config --global alias.lg "log --oneline --graph --decorate"
    git config --global alias.last "log -1 HEAD"
    git config --global alias.unstage "reset HEAD --"
    
    # Configure Git for better development workflow
    git config --global pull.rebase true
    git config --global push.default simple
    git config --global core.autocrlf input
    git config --global init.defaultBranch main
    
    log_success "Git configuration complete"
}

setup_env_files() {
    log_info "Setting up environment files..."
    
    # Create main .env file if it doesn't exist
    if [[ ! -f "${SCRIPT_DIR}/.env" ]]; then
        cat > "${SCRIPT_DIR}/.env" << 'EOF'
# ModernBlog Development Environment Variables

# Database Configuration
DATABASE_URL=postgresql://modernblog:modernblog123@localhost:5432/modernblog
POSTGRES_USER=modernblog
POSTGRES_PASSWORD=modernblog123
POSTGRES_DB=modernblog
POSTGRES_HOST=localhost
POSTGRES_PORT=5432

# Redis Configuration
REDIS_URL=redis://localhost:6379
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=

# MinIO Configuration (S3-compatible storage)
MINIO_ROOT_USER=minioadmin
MINIO_ROOT_PASSWORD=minioadmin123
MINIO_ENDPOINT=http://localhost:9000
MINIO_ACCESS_KEY=minioadmin
MINIO_SECRET_KEY=minioadmin123
MINIO_BUCKET=modernblog

# Application Configuration
NODE_ENV=development
API_PORT=3000
FRONTEND_PORT=3001
LOG_LEVEL=debug

# Monitoring Configuration
PROMETHEUS_PORT=9090
GRAFANA_PORT=3000
GRAFANA_USER=admin
GRAFANA_PASSWORD=admin123

# pgAdmin Configuration
PGADMIN_DEFAULT_EMAIL=admin@modernblog.local
PGADMIN_DEFAULT_PASSWORD=admin123
PGADMIN_PORT=5050

# JWT Configuration (development only)
JWT_SECRET=your-super-secret-jwt-key-change-in-production
JWT_EXPIRES_IN=7d

# API Keys (development only)
OPENAI_API_KEY=your-openai-api-key
ANTHROPIC_API_KEY=your-anthropic-api-key

# Email Configuration (development - using local SMTP)
SMTP_HOST=localhost
SMTP_PORT=1025
SMTP_USER=
SMTP_PASSWORD=
SMTP_FROM=noreply@modernblog.local

# Development Features
DEBUG=true
HOT_RELOAD=true
ENABLE_PROFILER=true
ENABLE_SWAGGER=true
EOF
        log_success "Created .env file"
    else
        log_info ".env file already exists"
    fi
    
    # Create Docker environment file
    if [[ ! -f "${SCRIPT_DIR}/.env.docker" ]]; then
        cat > "${SCRIPT_DIR}/.env.docker" << 'EOF'
# Docker-specific environment variables
COMPOSE_PROJECT_NAME=modernblog
COMPOSE_FILE=dev/docker-compose.dev.yml

# Docker network
DOCKER_NETWORK=modernblog-network

# Volume prefixes
POSTGRES_DATA=./data/postgres
REDIS_DATA=./data/redis
MINIO_DATA=./data/minio
GRAFANA_DATA=./data/grafana
EOF
        log_success "Created .env.docker file"
    fi
}

configure_shell_environment() {
    log_info "Configuring shell environment..."
    
    # Detect shell
    local shell_rc=""
    if [[ "$SHELL" == */bash ]]; then
        shell_rc="$HOME/.bashrc"
    elif [[ "$SHELL" == */zsh ]]; then
        shell_rc="$HOME/.zshrc"
    else
        log_warning "Unknown shell: $SHELL"
        return 0
    fi
    
    # Add ModernBlog environment setup
    if ! grep -q "# ModernBlog Development Environment" "$shell_rc" 2>/dev/null; then
        cat >> "$shell_rc" << 'EOF'

# ModernBlog Development Environment
export MODERNBLOG_PROJECT_ROOT="$HOME/personal/modern-cloud-app"
export PATH="$PATH:$MODERNBLOG_PROJECT_ROOT/scripts"

# Kubernetes aliases
alias k='kubectl'
alias kctx='kubectl config current-context'
alias kns='kubectl config view --minify -o jsonpath={..namespace}'
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kgi='kubectl get ingress'
alias kdp='kubectl describe pod'
alias kl='kubectl logs'
alias kexec='kubectl exec -it'

# Docker aliases
alias dc='docker-compose'
alias dcup='docker-compose up -d'
alias dcdown='docker-compose down'
alias dclogs='docker-compose logs -f'

# ModernBlog aliases
alias mb='cd $MODERNBLOG_PROJECT_ROOT'
alias mbdev='cd $MODERNBLOG_PROJECT_ROOT && make dev'
alias mbtest='cd $MODERNBLOG_PROJECT_ROOT && make test'
alias mblogs='cd $MODERNBLOG_PROJECT_ROOT && make logs'

# Load .env file automatically when in project directory
load_env() {
    if [[ -f .env && "$PWD" == *"modern-cloud-app"* ]]; then
        export $(grep -v '^#' .env | xargs)
    fi
}

# Auto-load env when changing directories
cd() {
    builtin cd "$@"
    load_env
}
EOF
        log_success "Shell environment configured"
    else
        log_info "Shell environment already configured"
    fi
}

setup_vscode_config() {
    log_info "Setting up VS Code configuration..."
    
    local vscode_dir="${SCRIPT_DIR}/.vscode"
    mkdir -p "$vscode_dir"
    
    # Create VS Code settings
    cat > "$vscode_dir/settings.json" << 'EOF'
{
    "editor.formatOnSave": true,
    "editor.codeActionsOnSave": {
        "source.fixAll": true,
        "source.organizeImports": true
    },
    "files.associations": {
        "*.yaml": "yaml",
        "*.yml": "yaml",
        "Dockerfile*": "dockerfile",
        "*.env*": "dotenv"
    },
    "go.formatTool": "goimports",
    "go.lintTool": "golangci-lint",
    "go.testFlags": ["-v"],
    "typescript.preferences.importModuleSpecifier": "relative",
    "javascript.preferences.importModuleSpecifier": "relative",
    "yaml.schemas": {
        "https://json.schemastore.org/github-workflow.json": ".github/workflows/*.yml",
        "https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json": "**/docker-compose*.yml"
    },
    "eslint.workingDirectories": ["frontend", "backend"],
    "prettier.configPath": ".prettierrc",
    "terminal.integrated.env.osx": {
        "MODERNBLOG_PROJECT_ROOT": "${workspaceFolder}"
    },
    "terminal.integrated.env.linux": {
        "MODERNBLOG_PROJECT_ROOT": "${workspaceFolder}"
    }
}
EOF
    
    # Create VS Code extensions recommendations
    cat > "$vscode_dir/extensions.json" << 'EOF'
{
    "recommendations": [
        "ms-vscode.vscode-typescript-next",
        "golang.go",
        "ms-python.python",
        "redhat.vscode-yaml",
        "ms-kubernetes-tools.vscode-kubernetes-tools",
        "ms-vscode.docker",
        "hashicorp.terraform",
        "bradlc.vscode-tailwindcss",
        "esbenp.prettier-vscode",
        "dbaeumer.vscode-eslint",
        "ms-vscode.vscode-json",
        "github.copilot",
        "ms-vscode-remote.remote-containers",
        "ms-vscode-remote.remote-ssh",
        "formulahendry.auto-rename-tag",
        "christian-kohler.path-intellisense",
        "streetsidesoftware.code-spell-checker",
        "gruntfuggly.todo-tree",
        "eamodio.gitlens"
    ]
}
EOF
    
    # Create launch configuration for debugging
    cat > "$vscode_dir/launch.json" << 'EOF'
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Debug Backend API",
            "type": "go",
            "request": "launch",
            "mode": "auto",
            "program": "${workspaceFolder}/backend/cmd/api",
            "env": {
                "NODE_ENV": "development"
            },
            "args": []
        },
        {
            "name": "Debug Frontend",
            "type": "node",
            "request": "launch",
            "name": "Next.js: debug server-side",
            "program": "${workspaceFolder}/frontend/node_modules/.bin/next",
            "args": ["dev"],
            "cwd": "${workspaceFolder}/frontend",
            "env": {
                "NODE_ENV": "development"
            }
        }
    ]
}
EOF
    
    # Create tasks configuration
    cat > "$vscode_dir/tasks.json" << 'EOF'
{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "Start Development Environment",
            "type": "shell",
            "command": "make",
            "args": ["dev"],
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
            "problemMatcher": []
        },
        {
            "label": "Run Tests",
            "type": "shell",
            "command": "make",
            "args": ["test"],
            "group": "test",
            "presentation": {
                "echo": true,
                "reveal": "always",
                "focus": false,
                "panel": "shared"
            }
        },
        {
            "label": "Build Application",
            "type": "shell",
            "command": "make",
            "args": ["build"],
            "group": "build",
            "presentation": {
                "echo": true,
                "reveal": "always",
                "focus": false,
                "panel": "shared"
            }
        }
    ]
}
EOF
    
    log_success "VS Code configuration created"
}

configure_git_hooks() {
    log_info "Configuring Git hooks..."
    
    # Install pre-commit if available
    if command -v pre-commit &> /dev/null; then
        if [[ -f "${SCRIPT_DIR}/.pre-commit-config.yaml" ]]; then
            pre-commit install
            log_success "Pre-commit hooks installed"
        fi
    fi
    
    # Install lefthook if available and configured
    if command -v lefthook &> /dev/null; then
        if [[ -f "${SCRIPT_DIR}/lefthook.yml" ]]; then
            lefthook install
            log_success "Lefthook installed"
        fi
    fi
}

setup_development_certificates() {
    log_info "Setting up development certificates..."
    
    local cert_dir="${SCRIPT_DIR}/dev/certs"
    mkdir -p "$cert_dir"
    
    # Generate self-signed certificate for local development
    if [[ ! -f "$cert_dir/localhost.crt" ]]; then
        openssl req -x509 -newkey rsa:4096 -keyout "$cert_dir/localhost.key" -out "$cert_dir/localhost.crt" -days 365 -nodes -subj "/C=US/ST=Development/L=Local/O=ModernBlog/CN=localhost"
        log_success "Development certificates generated"
    else
        log_info "Development certificates already exist"
    fi
}

main() {
    log_info "Configuring development environment..."
    
    setup_directories
    configure_git
    setup_env_files
    configure_shell_environment
    setup_vscode_config
    configure_git_hooks
    setup_development_certificates
    
    log_success "Development environment configuration complete"
    
    echo ""
    echo "Configuration Summary:"
    echo "  ✓ Project directories created"
    echo "  ✓ Git aliases and settings configured"
    echo "  ✓ Environment files created"
    echo "  ✓ Shell environment configured"
    echo "  ✓ VS Code workspace configured"
    echo "  ✓ Git hooks installed"
    echo "  ✓ Development certificates generated"
    echo ""
    echo "Next steps:"
    echo "  1. Restart your terminal to load new environment"
    echo "  2. Open VS Code: code ."
    echo "  3. Install recommended extensions"
    echo "  4. Start development: make dev"
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