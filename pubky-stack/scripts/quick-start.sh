#!/bin/bash

# Pubky Stack Quick Start Script
# Rapid deployment with default settings

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="$(dirname "$SCRIPT_DIR")"

print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

print_color $CYAN "=================================="
print_color $CYAN "PUBKY STACK QUICK START"
print_color $CYAN "=================================="
echo

# Source the main setup script for prerequisite functions
source "$STACK_DIR/setup.sh"

# Check prerequisites
print_color $BLUE "➤ Checking prerequisites..."
if ! check_prerequisites; then
    print_color $RED "✗ Prerequisites check failed. Cannot continue."
    exit 1
fi

print_color $BLUE "➤ Setting up with default configuration..."

# Copy default environment if it doesn't exist
if [[ ! -f "$STACK_DIR/.env" ]]; then
    cp "$STACK_DIR/.env.example" "$STACK_DIR/.env"
    
    # Set build date
    sed -i "s/PUBKY_APP_DATE=/PUBKY_APP_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")/" "$STACK_DIR/.env"
    
    print_color $GREEN "✓ Environment configuration created"
else
    print_color $YELLOW "⚠ Using existing environment configuration"
fi

# Change to stack directory
cd "$STACK_DIR"

print_color $BLUE "➤ Building services..."
docker-compose build

print_color $BLUE "➤ Starting stack..."
docker-compose up -d

print_color $GREEN "✓ Pubky Stack started successfully!"

echo
print_color $CYAN "Access URLs:"
print_color $CYAN "  • Pubky App: http://localhost"
print_color $CYAN "  • Nexus: http://localhost:8080"
print_color $CYAN "  • Homeserver: http://localhost:6287"
print_color $CYAN "  • HTTP Relay: http://localhost:15412"
echo

print_color $YELLOW "To stop the stack: docker-compose down"
print_color $YELLOW "To view logs: docker-compose logs -f"
print_color $YELLOW "To check status: docker-compose ps"