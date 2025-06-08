#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export SCRIPT_DIR

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

show_banner() {
    echo -e "${BLUE}"
    cat << "EOF"
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║    __  __           _                 ____  _                ║
║   |  \/  | ___   __| | ___ _ __ _ __ | __ )| | ___   __ _   ║
║   | |\/| |/ _ \ / _` |/ _ \ '__| '_ \|  _ \| |/ _ \ / _` |  ║
║   | |  | | (_) | (_| |  __/ |  | | | | |_) | | (_) | (_| |  ║
║   |_|  |_|\___/ \__,_|\___|_|  |_| |_|____/|_|\___/ \__, |  ║
║                                                      |___/   ║
║                                                              ║
║            🚀 Development Environment Setup                  ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    local missing_tools=()
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if ! command -v brew &> /dev/null; then
            log_error "Homebrew is not installed. Please install it first:"
            echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
            exit 1
        fi
    fi
    
    if ! command -v git &> /dev/null; then
        missing_tools+=("git")
    fi
    
    if ! command -v curl &> /dev/null; then
        missing_tools+=("curl")
    fi
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        log_error "Please install them before running this script."
        exit 1
    fi
    
    log_success "All prerequisites satisfied"
}

detect_platform() {
    log_info "Detecting platform..."
    source "${SCRIPT_DIR}/scripts/detect-platform.sh"
}

install_tools() {
    log_info "Installing development tools..."
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        log_info "Installing tools via Homebrew..."
        brew bundle --file="${SCRIPT_DIR}/Brewfile"
    else
        "${SCRIPT_DIR}/scripts/install-tools.sh"
    fi
    
    log_success "Development tools installed"
}

setup_docker() {
    log_info "Setting up Docker..."
    
    if ! docker info &> /dev/null; then
        log_error "Docker is not running. Please start Docker Desktop and try again."
        exit 1
    fi
    
    log_info "Pulling required Docker images..."
    docker pull postgres:16-alpine
    docker pull redis:7-alpine
    docker pull grafana/grafana:latest
    docker pull prom/prometheus:latest
    docker pull minio/minio:latest
    docker pull dpage/pgadmin4:latest
    
    log_success "Docker setup complete"
}

setup_kubernetes() {
    log_info "Setting up local Kubernetes cluster..."
    "${SCRIPT_DIR}/scripts/setup-local-k8s.sh"
    log_success "Kubernetes cluster ready"
}

configure_dev_env() {
    log_info "Configuring development environment..."
    "${SCRIPT_DIR}/scripts/configure-dev-env.sh"
    log_success "Development environment configured"
}

setup_git_hooks() {
    log_info "Setting up git hooks..."
    
    if command -v lefthook &> /dev/null; then
        lefthook install
        log_success "Git hooks installed"
    else
        log_warning "Lefthook not found, skipping git hooks setup"
    fi
}

create_env_files() {
    log_info "Creating environment files..."
    
    if [[ ! -f "${SCRIPT_DIR}/.env" ]]; then
        cat > "${SCRIPT_DIR}/.env" << EOF
# Database
DATABASE_URL=postgresql://modernblog:modernblog123@localhost:5432/modernblog
POSTGRES_USER=modernblog
POSTGRES_PASSWORD=modernblog123
POSTGRES_DB=modernblog

# Redis
REDIS_URL=redis://localhost:6379

# MinIO (S3-compatible storage)
MINIO_ROOT_USER=minioadmin
MINIO_ROOT_PASSWORD=minioadmin123
MINIO_ENDPOINT=http://localhost:9000
MINIO_ACCESS_KEY=minioadmin
MINIO_SECRET_KEY=minioadmin123

# Application
NODE_ENV=development
API_PORT=3000
FRONTEND_PORT=3001

# Monitoring
PROMETHEUS_PORT=9090
GRAFANA_PORT=3000

# pgAdmin
PGADMIN_DEFAULT_EMAIL=admin@modernblog.local
PGADMIN_DEFAULT_PASSWORD=admin123
EOF
        log_success "Created .env file"
    else
        log_info ".env file already exists, skipping"
    fi
}

run_validation() {
    log_info "Running validation checks..."
    "${SCRIPT_DIR}/scripts/validate-setup.sh"
}

main() {
    show_banner
    
    cd "$SCRIPT_DIR"
    
    check_prerequisites
    detect_platform
    
    install_tools
    setup_docker
    create_env_files
    setup_kubernetes
    configure_dev_env
    setup_git_hooks
    
    run_validation
    
    echo ""
    log_success "🎉 ModernBlog development environment setup complete!"
    echo ""
    echo "Quick start commands:"
    echo "  make dev           # Start all local services"
    echo "  make k8s-deploy    # Deploy to local Kubernetes"
    echo "  make test          # Run all tests"
    echo "  make help          # Show all available commands"
    echo ""
    echo "Next steps:"
    echo "  1. Review the .env file and update any settings"
    echo "  2. Run 'make dev' to start local services"
    echo "  3. Visit http://localhost:3001 for the frontend"
    echo "  4. Visit http://localhost:3000 for the API"
    echo ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi