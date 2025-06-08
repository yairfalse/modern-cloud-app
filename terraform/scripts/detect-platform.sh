#!/bin/bash
set -euo pipefail

# Platform detection script for ModernBlog setup
# Detects OS type, version, and architecture

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Export platform info for other scripts
export PLATFORM=""
export PLATFORM_VERSION=""
export ARCH=""
export PACKAGE_MANAGER=""
export IS_WSL=false

detect_architecture() {
    local arch=$(uname -m)
    case $arch in
        x86_64)
            ARCH="amd64"
            ;;
        aarch64|arm64)
            ARCH="arm64"
            ;;
        armv7l)
            ARCH="arm"
            ;;
        *)
            echo -e "${RED}✗ Unsupported architecture: $arch${NC}"
            exit 1
            ;;
    esac
}

detect_linux_distro() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        PLATFORM=$ID
        PLATFORM_VERSION=$VERSION_ID
        
        # Detect package manager
        if command -v apt-get &> /dev/null; then
            PACKAGE_MANAGER="apt"
        elif command -v yum &> /dev/null; then
            PACKAGE_MANAGER="yum"
        elif command -v dnf &> /dev/null; then
            PACKAGE_MANAGER="dnf"
        elif command -v pacman &> /dev/null; then
            PACKAGE_MANAGER="pacman"
        elif command -v zypper &> /dev/null; then
            PACKAGE_MANAGER="zypper"
        else
            echo -e "${RED}✗ No supported package manager found${NC}"
            exit 1
        fi
        
        # Check if running in WSL
        if grep -qi microsoft /proc/version; then
            IS_WSL=true
            echo -e "${YELLOW}⚠ WSL detected. Some features may require additional configuration${NC}"
        fi
    else
        echo -e "${RED}✗ Cannot detect Linux distribution${NC}"
        exit 1
    fi
}

detect_macos_version() {
    PLATFORM="darwin"
    PLATFORM_VERSION=$(sw_vers -productVersion)
    PACKAGE_MANAGER="brew"
    
    # Check macOS version compatibility
    local major_version=$(echo "$PLATFORM_VERSION" | cut -d. -f1)
    if [[ $major_version -lt 11 ]]; then
        echo -e "${YELLOW}⚠ macOS $PLATFORM_VERSION detected. Minimum recommended version is 11.0 (Big Sur)${NC}"
    fi
    
    # Check if Homebrew is installed
    if ! command -v brew &> /dev/null; then
        echo -e "${YELLOW}⚠ Homebrew not installed. Installing Homebrew...${NC}"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add Homebrew to PATH based on architecture
        if [[ "$ARCH" == "arm64" ]]; then
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
            eval "$(/opt/homebrew/bin/brew shellenv)"
        else
            echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zprofile
            eval "$(/usr/local/bin/brew shellenv)"
        fi
    fi
}

check_docker_desktop() {
    if [[ "$PLATFORM" == "darwin" ]]; then
        if [[ -d "/Applications/Docker.app" ]]; then
            echo -e "${GREEN}✓ Docker Desktop detected${NC}"
            
            # Check if Docker is running
            if ! docker info &> /dev/null; then
                echo -e "${YELLOW}⚠ Docker Desktop is installed but not running${NC}"
                echo -e "${BLUE}ℹ Starting Docker Desktop...${NC}"
                open -a Docker
                
                # Wait for Docker to start (max 30 seconds)
                local count=0
                while ! docker info &> /dev/null && [[ $count -lt 30 ]]; do
                    sleep 1
                    count=$((count + 1))
                done
                
                if docker info &> /dev/null; then
                    echo -e "${GREEN}✓ Docker Desktop started successfully${NC}"
                else
                    echo -e "${RED}✗ Failed to start Docker Desktop${NC}"
                    exit 1
                fi
            fi
        else
            echo -e "${YELLOW}⚠ Docker Desktop not found. It will be installed during setup${NC}"
        fi
    fi
}

write_platform_config() {
    local config_file="$HOME/.modernblog/platform.conf"
    mkdir -p "$HOME/.modernblog"
    
    cat > "$config_file" << EOF
# ModernBlog Platform Configuration
# Generated on $(date)

PLATFORM="$PLATFORM"
PLATFORM_VERSION="$PLATFORM_VERSION"
ARCH="$ARCH"
PACKAGE_MANAGER="$PACKAGE_MANAGER"
IS_WSL=$IS_WSL

# Tool versions
GO_VERSION="1.21.5"
NODE_VERSION="20"
TERRAFORM_VERSION="1.6.6"
KIND_VERSION="0.20.0"
SKAFFOLD_VERSION="2.10.0"
DAGGER_VERSION="0.9.5"
CLAUDE_CODE_VERSION="latest"

# Kubernetes configuration
KIND_CLUSTER_NAME="modernblog-dev"
K8S_VERSION="1.29.0"
EOF
    
    echo -e "${GREEN}✓ Platform configuration saved to $config_file${NC}"
}

main() {
    echo -e "${BLUE}=== Platform Detection ===${NC}"
    echo ""
    
    # Detect architecture
    detect_architecture
    echo -e "${GREEN}✓ Architecture: $ARCH${NC}"
    
    # Detect OS
    case "$OSTYPE" in
        linux*)
            detect_linux_distro
            echo -e "${GREEN}✓ Platform: $PLATFORM $PLATFORM_VERSION${NC}"
            echo -e "${GREEN}✓ Package Manager: $PACKAGE_MANAGER${NC}"
            ;;
        darwin*)
            detect_macos_version
            echo -e "${GREEN}✓ Platform: macOS $PLATFORM_VERSION${NC}"
            echo -e "${GREEN}✓ Package Manager: $PACKAGE_MANAGER${NC}"
            check_docker_desktop
            ;;
        msys*|cygwin*)
            echo -e "${RED}✗ Windows (non-WSL) is not supported. Please use WSL2${NC}"
            exit 1
            ;;
        *)
            echo -e "${RED}✗ Unknown operating system: $OSTYPE${NC}"
            exit 1
            ;;
    esac
    
    # Check system resources
    echo ""
    echo -e "${BLUE}=== System Resources ===${NC}"
    
    # Check CPU cores
    if [[ "$PLATFORM" == "darwin" ]]; then
        CPU_CORES=$(sysctl -n hw.ncpu)
    else
        CPU_CORES=$(nproc)
    fi
    echo -e "${GREEN}✓ CPU Cores: $CPU_CORES${NC}"
    
    # Check memory
    if [[ "$PLATFORM" == "darwin" ]]; then
        TOTAL_MEM=$(( $(sysctl -n hw.memsize) / 1024 / 1024 / 1024 ))
    else
        TOTAL_MEM=$(( $(grep MemTotal /proc/meminfo | awk '{print $2}') / 1024 / 1024 ))
    fi
    echo -e "${GREEN}✓ Total Memory: ${TOTAL_MEM}GB${NC}"
    
    if [[ $TOTAL_MEM -lt 8 ]]; then
        echo -e "${YELLOW}⚠ Less than 8GB RAM detected. Performance may be impacted${NC}"
    fi
    
    # Write configuration
    write_platform_config
    
    # Export for immediate use
    export MODERNBLOG_PLATFORM_CONFIG="$HOME/.modernblog/platform.conf"
    
    echo ""
    echo -e "${GREEN}✓ Platform detection complete${NC}"
}

main "$@"