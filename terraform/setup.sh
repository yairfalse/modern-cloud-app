#!/bin/bash
set -euo pipefail

# ModernBlog Development Environment Setup
# Complete 5-minute setup for AI-enhanced development

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SETUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${SETUP_DIR}/setup.log"
START_TIME=$(date +%s)

# Progress tracking
TOTAL_STEPS=5
CURRENT_STEP=0

print_banner() {
    echo -e "${BLUE}"
    echo "TPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPW"
    echo "Q          ModernBlog Development Environment Setup             Q"
    echo "Q                                                              Q"
    echo "Q  =€ Complete development stack in under 5 minutes            Q"
    echo "Q  > AI-enhanced development with Claude Code                 Q"
    echo "Q  8  Local Kubernetes with Kind                              Q"
    echo "Q  =à  All modern development tools included                   Q"
    echo "ZPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP]"
    echo -e "${NC}\n"
}

progress_bar() {
    local current=$1
    local total=$2
    local width=50
    local percentage=$((current * 100 / total))
    local filled=$((width * current / total))
    
    printf "\rProgress: ["
    printf "%${filled}s" | tr ' ' '='
    printf "%$((width - filled))s" | tr ' ' ' '
    printf "] %d%%" "$percentage"
}

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED} Error: $1${NC}" | tee -a "$LOG_FILE"
    exit 1
}

success() {
    echo -e "${GREEN} $1${NC}" | tee -a "$LOG_FILE"
}

info() {
    echo -e "${BLUE}9 $1${NC}" | tee -a "$LOG_FILE"
}

warning() {
    echo -e "${YELLOW}  $1${NC}" | tee -a "$LOG_FILE"
}

run_step() {
    local step_name=$1
    local script_path=$2
    
    CURRENT_STEP=$((CURRENT_STEP + 1))
    progress_bar $CURRENT_STEP $TOTAL_STEPS
    echo -e "\n\n${BLUE}Step $CURRENT_STEP/$TOTAL_STEPS: $step_name${NC}"
    echo ""
    
    if [[ -x "$script_path" ]]; then
        if "$script_path" 2>&1 | tee -a "$LOG_FILE"; then
            success "$step_name completed"
        else
            error "$step_name failed. Check $LOG_FILE for details"
        fi
    else
        error "Script not found or not executable: $script_path"
    fi
    
    echo ""
}

check_prerequisites() {
    info "Checking prerequisites..."
    
    # Check for required commands
    local required_commands=("curl" "git")
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            error "$cmd is required but not installed"
        fi
    done
    
    # Check disk space (need at least 10GB)
    local available_space
    if [[ "$OSTYPE" == "darwin"* ]]; then
        available_space=$(df -g . | awk 'NR==2 {print $4}')
    else
        available_space=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')
    fi
    
    if [[ $available_space -lt 10 ]]; then
        warning "Less than 10GB of disk space available. Setup may fail."
    fi
    
    success "Prerequisites check passed"
}

create_directories() {
    info "Creating project directories..."
    
    # Create all necessary directories
    local dirs=(
        ".modernblog"
        ".modernblog/cache"
        ".modernblog/logs"
        "bin"
        "data/postgres"
        "data/redis"
    )
    
    for dir in "${dirs[@]}"; do
        mkdir -p "$SETUP_DIR/$dir"
    done
    
    success "Directories created"
}

main() {
    # Clear screen and show banner
    clear
    print_banner
    
    # Initialize log
    echo "ModernBlog Setup Log - $(date)" > "$LOG_FILE"
    
    # Check prerequisites
    check_prerequisites
    
    # Create necessary directories
    create_directories
    
    # Make all scripts executable
    chmod +x "$SETUP_DIR"/scripts/*.sh
    
    # Run setup steps
    run_step "Platform Detection" "$SETUP_DIR/scripts/detect-platform.sh"
    run_step "Tool Installation" "$SETUP_DIR/scripts/install-tools.sh"
    run_step "Kubernetes Setup" "$SETUP_DIR/scripts/setup-local-k8s.sh"
    run_step "Development Environment" "$SETUP_DIR/scripts/configure-dev-env.sh"
    run_step "Validation" "$SETUP_DIR/scripts/validate-setup.sh"
    
    # Calculate total time
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    MINUTES=$((DURATION / 60))
    SECONDS=$((DURATION % 60))
    
    # Final summary
    echo -e "\n${GREEN}${NC}"
    echo -e "${GREEN} ModernBlog Development Environment Setup Complete!${NC}"
    echo -e "${GREEN}${NC}"
    echo ""
    echo "ñ  Setup completed in: ${MINUTES}m ${SECONDS}s"
    echo ""
    echo "<¯ Next Steps:"
    echo "   1. Authenticate Claude Code: claude-code auth login"
    echo "   2. Start development: make dev"
    echo "   3. Access application: http://modernblog.local"
    echo ""
    echo "=Ú Quick Commands:"
    echo "   " make help     - Show all available commands"
    echo "   " make dev      - Start development environment"
    echo "   " make test     - Run all tests"
    echo "   " make build    - Build application"
    echo ""
    echo "=Ý Setup log: $LOG_FILE"
    echo ""
    
    # Source environment if bash
    if [[ -n "$BASH_VERSION" ]]; then
        info "Run 'source ~/.bashrc' to load environment changes"
    elif [[ -n "$ZSH_VERSION" ]]; then
        info "Run 'source ~/.zshrc' to load environment changes"
    fi
}

# Trap errors
trap 'error "Setup failed at line $LINENO"' ERR

# Run main function
main "$@"