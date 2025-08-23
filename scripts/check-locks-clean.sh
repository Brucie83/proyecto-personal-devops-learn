#!/bin/bash

# Sandbox DevOps - Infrastructure Lock Verification Script
# This script verifies if there are active locks in the infrastructure

set -e

# Configuration variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS] $1${NC}"
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

# Help function
show_help() {
    echo "Sandbox DevOps - Infrastructure Lock Verification"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help          Show this help"
    echo "  -v, --verbose       Verbose mode"
    echo "  -f, --force         Force verification (ignore errors)"
    echo ""
    echo "Examples:"
    echo "  $0                  # Normal verification"
    echo "  $0 --verbose        # Detailed verification"
    echo "  $0 --force          # Forced verification"
}

# Function to check file locks
check_file_locks() {
    log "Checking file locks..."
    
    local lock_files=()
    local found_locks=false
    
    # Search for lock files
    while IFS= read -r -d '' file; do
        lock_files+=("$file")
        found_locks=true
    done < <(find "$PROJECT_ROOT" -name "*.lock" -type f -print0 2>/dev/null)
    
    if [ "$found_locks" = true ]; then
        warning "File locks found:"
        for file in "${lock_files[@]}"; do
            echo "  - $file"
            if [ "$VERBOSE" = true ]; then
                echo "    Created: $(stat -f "%Sm" "$file" 2>/dev/null || stat -c "%y" "$file" 2>/dev/null || echo "N/A")"
                echo "    Size: $(stat -f "%z" "$file" 2>/dev/null || stat -c "%s" "$file" 2>/dev/null || echo "N/A") bytes"
            fi
        done
        return 1
    else
        success "No file locks found"
        return 0
    fi
}

# Function to check Docker locks
check_docker_locks() {
    log "Checking Docker locks..."
    
    # Check if containers are running
    if docker ps --format "table {{.Names}}" | grep -q "sandbox-vm"; then
        warning "Container sandbox-vm is running"
        if [ "$VERBOSE" = true ]; then
            echo "  Status: $(docker ps --format "table {{.Status}}" | grep sandbox-vm)"
            echo "  Resources: $(docker stats --no-stream sandbox-vm 2>/dev/null | tail -n 1 || echo "N/A")"
        fi
        return 1
    else
        success "No sandbox-vm containers running"
        return 0
    fi
}

# Function to check port locks
check_port_locks() {
    log "Checking port locks..."
    
    local ports=(22 80 1433)
    local blocked_ports=()
    
    for port in "${ports[@]}"; do
        if lsof -i :$port >/dev/null 2>&1; then
            blocked_ports+=("$port")
        fi
    done
    
    if [ ${#blocked_ports[@]} -gt 0 ]; then
        warning "Blocked ports found:"
        for port in "${blocked_ports[@]}"; do
            echo "  - Port $port"
            if [ "$VERBOSE" = true ]; then
                echo "    Process: $(lsof -i :$port | tail -n +2 | head -1 | awk '{print $1, $2}' || echo "N/A")"
            fi
        done
        return 1
    else
        success "No blocked ports found"
        return 0
    fi
}

# Function to check configuration locks
check_configuration_locks() {
    log "Checking configuration locks..."
    
    local required_files=("secrets.json" "keyvault.json")
    local missing_files=()
    
    for file in "${required_files[@]}"; do
        if [ ! -f "$PROJECT_ROOT/$file" ]; then
            missing_files+=("$file")
        fi
    done
    
    if [ ${#missing_files[@]} -gt 0 ]; then
        error "Missing configuration files:"
        for file in "${missing_files[@]}"; do
            echo "  - $file"
        done
        return 1
    else
        success "All configuration files present"
        return 0
    fi
}

# Function to check permission locks
check_permission_locks() {
    log "Checking permission locks..."
    
    local scripts_dir="$PROJECT_ROOT/scripts"
    local failed_checks=0
    
    if [ -d "$scripts_dir" ]; then
        for script in "$scripts_dir"/*.sh; do
            if [ -f "$script" ] && [ ! -x "$script" ]; then
                warning "Script not executable: $script"
                failed_checks=$((failed_checks + 1))
            fi
        done
    fi
    
    if [ $failed_checks -eq 0 ]; then
        success "All scripts have execution permissions"
        return 0
    else
        return 1
    fi
}

# Main verification function
main() {
    echo "Starting infrastructure lock verification..."
    echo
    
    local total_checks=5
    local passed_checks=0
    local failed_checks=0
    
    # Check file locks
    if check_file_locks; then
        passed_checks=$((passed_checks + 1))
    else
        failed_checks=$((failed_checks + 1))
    fi
    
    # Check Docker locks
    if check_docker_locks; then
        passed_checks=$((passed_checks + 1))
    else
        failed_checks=$((failed_checks + 1))
    fi
    
    # Check port locks
    if check_port_locks; then
        passed_checks=$((passed_checks + 1))
    else
        failed_checks=$((failed_checks + 1))
    fi
    
    # Check configuration locks
    if check_configuration_locks; then
        passed_checks=$((passed_checks + 1))
    else
        failed_checks=$((failed_checks + 1))
    fi
    
    # Check permission locks
    if check_permission_locks; then
        passed_checks=$((passed_checks + 1))
    else
        failed_checks=$((failed_checks + 1))
    fi
    
    echo
    echo "=== Verification Summary ==="
    echo "Passed checks: $passed_checks/$total_checks"
    echo "Failed checks: $failed_checks/$total_checks"
    
    if [ $failed_checks -gt 0 ]; then
        echo "WARNING: $failed_checks locks found."
        echo "To ignore locks, use: $0 --force"
        exit 1
    else
        echo "SUCCESS: No locks found."
        exit 0
    fi
}

# Parse command line arguments
VERBOSE=false
FORCE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -f|--force)
            FORCE=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Execute main function
main "$@"

