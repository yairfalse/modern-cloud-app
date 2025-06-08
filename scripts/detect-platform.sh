#!/bin/bash
set -euo pipefail

# Platform detection script for ModernBlog

# Export platform information
export PLATFORM=""
export ARCH=""
export PACKAGE_MANAGER=""
export INIT_SYSTEM=""

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        PLATFORM="linux"
        
        # Detect Linux distribution
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            export DISTRO="$ID"
            export DISTRO_VERSION="$VERSION_ID"
        elif [ -f /etc/debian_version ]; then
            export DISTRO="debian"
            export DISTRO_VERSION=$(cat /etc/debian_version)
        elif [ -f /etc/redhat-release ]; then
            export DISTRO="rhel"
            export DISTRO_VERSION=$(cat /etc/redhat-release | grep -oE '[0-9]+\.[0-9]+')
        else
            export DISTRO="unknown"
            export DISTRO_VERSION="unknown"
        fi
        
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
        elif command -v apk &> /dev/null; then
            PACKAGE_MANAGER="apk"
        else
            PACKAGE_MANAGER="unknown"
        fi
        
        # Detect init system
        if command -v systemctl &> /dev/null; then
            INIT_SYSTEM="systemd"
        elif command -v service &> /dev/null; then
            INIT_SYSTEM="sysvinit"
        elif command -v rc-service &> /dev/null; then
            INIT_SYSTEM="openrc"
        else
            INIT_SYSTEM="unknown"
        fi
        
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        PLATFORM="macos"
        PACKAGE_MANAGER="brew"
        INIT_SYSTEM="launchd"
        
        # Get macOS version
        export MACOS_VERSION=$(sw_vers -productVersion)
        export MACOS_BUILD=$(sw_vers -buildVersion)
        
    elif [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
        PLATFORM="windows"
        PACKAGE_MANAGER="choco"
        INIT_SYSTEM="windows"
        
    elif [[ "$OSTYPE" == "freebsd"* ]]; then
        PLATFORM="freebsd"
        PACKAGE_MANAGER="pkg"
        INIT_SYSTEM="rc"
        
    else
        PLATFORM="unknown"
        PACKAGE_MANAGER="unknown"
        INIT_SYSTEM="unknown"
    fi
}

# Detect architecture
detect_arch() {
    local machine=$(uname -m)
    
    case $machine in
        x86_64)
            ARCH="amd64"
            ;;
        aarch64|arm64)
            ARCH="arm64"
            ;;
        armv7l|armv6l)
            ARCH="arm"
            ;;
        i686|i386)
            ARCH="386"
            ;;
        *)
            ARCH="unknown"
            ;;
    esac
}

# Check if running in container
detect_container() {
    if [ -f /.dockerenv ]; then
        export CONTAINER="docker"
    elif [ -f /run/.containerenv ]; then
        export CONTAINER="podman"
    elif grep -q "lxc" /proc/1/cgroup 2>/dev/null; then
        export CONTAINER="lxc"
    elif [ -n "${KUBERNETES_SERVICE_HOST:-}" ]; then
        export CONTAINER="kubernetes"
    else
        export CONTAINER="none"
    fi
}

# Check if running in VM
detect_vm() {
    if command -v systemd-detect-virt &> /dev/null; then
        export VM=$(systemd-detect-virt)
    elif [ -f /sys/hypervisor/type ]; then
        export VM=$(cat /sys/hypervisor/type)
    elif dmesg | grep -qi "hypervisor" 2>/dev/null; then
        export VM="unknown"
    else
        export VM="none"
    fi
}

# Check available resources
check_resources() {
    # Memory in MB
    if [[ "$PLATFORM" == "macos" ]]; then
        export TOTAL_MEMORY=$(sysctl -n hw.memsize | awk '{print int($1/1024/1024)}')
        export CPU_COUNT=$(sysctl -n hw.logicalcpu)
    elif [[ "$PLATFORM" == "linux" ]]; then
        export TOTAL_MEMORY=$(free -m | awk '/^Mem:/{print $2}')
        export CPU_COUNT=$(nproc)
    else
        export TOTAL_MEMORY=0
        export CPU_COUNT=0
    fi
    
    # Available disk space in GB
    if [[ "$PLATFORM" == "macos" ]]; then
        export DISK_SPACE=$(df -g . | awk 'NR==2 {print $4}')
    else
        export DISK_SPACE=$(df -BG . | awk 'NR==2 {gsub(/[^0-9]/,"",$4); print $4}')
    fi
}

# Main detection
main() {
    log_info "Detecting platform..."
    
    detect_os
    detect_arch
    detect_container
    detect_vm
    check_resources
    
    # Export all variables
    export PLATFORM
    export ARCH
    export PACKAGE_MANAGER
    export INIT_SYSTEM
    
    # Display detected information
    log_success "Platform detection complete:"
    echo "  OS:              $PLATFORM"
    echo "  Architecture:    $ARCH"
    echo "  Package Manager: $PACKAGE_MANAGER"
    echo "  Init System:     $INIT_SYSTEM"
    echo "  Container:       $CONTAINER"
    echo "  VM:              $VM"
    echo "  CPU Count:       $CPU_COUNT"
    echo "  Memory (MB):     $TOTAL_MEMORY"
    echo "  Disk Space (GB): $DISK_SPACE"
    
    # Check minimum requirements
    if [[ $TOTAL_MEMORY -lt 4096 ]]; then
        log_warning "Less than 4GB of memory detected. You may experience performance issues."
    fi
    
    if [[ $DISK_SPACE -lt 20 ]]; then
        log_warning "Less than 20GB of disk space available. Setup may fail."
    fi
    
    if [[ "$PLATFORM" == "unknown" ]]; then
        log_error "Unable to detect platform. Manual configuration may be required."
        exit 1
    fi
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Import logging functions from parent script if available
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