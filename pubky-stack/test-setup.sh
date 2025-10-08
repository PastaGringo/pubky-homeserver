#!/bin/bash

# Test script for Pubky Stack Setup
# This script tests the setup functionality without requiring Docker

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Function to print colored output
print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to print success
print_success() {
    print_color $GREEN "✓ $1"
}

# Function to print error
print_error() {
    print_color $RED "✗ $1"
}

# Function to print step
print_step() {
    print_color $BLUE "➤ $1"
}

print_color $CYAN "=================================="
print_color $CYAN "PUBKY STACK SETUP TEST"
print_color $CYAN "=================================="
echo

# Test 1: Check if setup script exists and is executable
print_step "Testing setup script existence and permissions..."
if [[ -f "$SCRIPT_DIR/setup.sh" ]]; then
    print_success "setup.sh exists"
else
    print_error "setup.sh not found"
    exit 1
fi

if [[ -x "$SCRIPT_DIR/setup.sh" ]]; then
    print_success "setup.sh is executable"
else
    print_error "setup.sh is not executable"
    exit 1
fi

# Test 2: Check configuration files
print_step "Testing configuration files..."

config_files=(
    ".env.example"
    "docker-compose.yml"
    "configs/caddy/Caddyfile"
    "configs/homeserver/homeserver.config.toml"
    "configs/homeserver/homeserver.entrypoint.sh"
    "configs/nexus/config.toml"
    "README.md"
)

for file in "${config_files[@]}"; do
    if [[ -f "$SCRIPT_DIR/$file" ]]; then
        print_success "$file exists"
    else
        print_error "$file not found"
        exit 1
    fi
done

# Test 3: Check directory structure
print_step "Testing directory structure..."

directories=(
    "configs"
    "configs/caddy"
    "configs/homeserver"
    "configs/nexus"
    "data"
    "scripts"
)

for dir in "${directories[@]}"; do
    if [[ -d "$SCRIPT_DIR/$dir" ]]; then
        print_success "Directory $dir exists"
    else
        print_error "Directory $dir not found"
        exit 1
    fi
done

# Test 4: Validate environment template
print_step "Testing environment template..."
if grep -q "NEXT_PUBLIC_HOMESERVER" "$SCRIPT_DIR/.env.example"; then
    print_success "Environment template contains required variables"
else
    print_error "Environment template missing required variables"
    exit 1
fi

# Test 5: Validate docker-compose file
print_step "Testing docker-compose configuration..."
if grep -q "services:" "$SCRIPT_DIR/docker-compose.yml"; then
    print_success "Docker Compose file has services section"
else
    print_error "Docker Compose file missing services section"
    exit 1
fi

# Test 6: Check Caddy configuration
print_step "Testing Caddy configuration..."
if grep -q "reverse_proxy" "$SCRIPT_DIR/configs/caddy/Caddyfile"; then
    print_success "Caddy configuration contains reverse proxy rules"
else
    print_error "Caddy configuration missing reverse proxy rules"
    exit 1
fi

# Test 7: Check homeserver entrypoint permissions
print_step "Testing homeserver entrypoint permissions..."
if [[ -x "$SCRIPT_DIR/configs/homeserver/homeserver.entrypoint.sh" ]]; then
    print_success "Homeserver entrypoint is executable"
else
    print_error "Homeserver entrypoint is not executable"
    exit 1
fi

# Test 8: Validate script syntax
print_step "Testing setup script syntax..."
if bash -n "$SCRIPT_DIR/setup.sh"; then
    print_success "Setup script syntax is valid"
else
    print_error "Setup script has syntax errors"
    exit 1
fi

echo
print_color $GREEN "=================================="
print_color $GREEN "ALL TESTS PASSED!"
print_color $GREEN "=================================="
echo

print_color $YELLOW "The Pubky Stack is ready to use!"
echo
print_color $CYAN "To get started:"
print_color $CYAN "1. Install Docker and Docker Compose"
print_color $CYAN "2. Run: ./setup.sh"
print_color $CYAN "3. Follow the interactive prompts"
echo
print_color $CYAN "For more information, see README.md"