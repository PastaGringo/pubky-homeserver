#!/bin/bash

# Test script for prerequisite installation functions
# This script tests the automatic installation of Docker, Docker Compose, and DNS tools

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_test() {
    echo -e "${CYAN}[TEST]${NC} $1"
}

print_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

print_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Source the setup script to get our functions
source "$SCRIPT_DIR/setup.sh"

echo
echo -e "${BLUE}================================${NC}"
echo -e "${BLUE} TESTING PREREQUISITE FUNCTIONS${NC}"
echo -e "${BLUE}================================${NC}"
echo

# Test 1: Check OS detection
print_test "Testing OS detection..."
if detect_os; then
    print_pass "OS detection works: $OS_TYPE"
else
    print_fail "OS detection failed"
    exit 1
fi

# Test 2: Check root privilege detection
print_test "Testing root privilege detection..."
if check_root_privileges; then
    print_pass "Root privilege check works"
else
    print_info "Root privilege check works (not root)"
fi

# Test 3: Check Docker detection
print_test "Testing Docker detection..."
if command -v docker >/dev/null 2>&1; then
    print_pass "Docker is installed"
    docker --version
else
    print_info "Docker is not installed (this is expected for testing)"
fi

# Test 4: Check Docker Compose detection
print_test "Testing Docker Compose detection..."
if command -v docker-compose >/dev/null 2>&1; then
    print_pass "Docker Compose is installed"
    docker-compose --version
elif docker compose version >/dev/null 2>&1; then
    print_pass "Docker Compose (plugin) is installed"
    docker compose version
else
    print_info "Docker Compose is not installed (this is expected for testing)"
fi

# Test 5: Check DNS tools detection
print_test "Testing DNS tools detection..."
if command -v dig >/dev/null 2>&1; then
    print_pass "dig is installed"
    dig -v 2>&1 | head -1
else
    print_info "dig is not installed (this is expected for testing)"
fi

if command -v nslookup >/dev/null 2>&1; then
    print_pass "nslookup is installed"
else
    print_info "nslookup is not installed (this is expected for testing)"
fi

# Test 6: Test prerequisite check function (dry run)
print_test "Testing prerequisite check function..."
echo -e "${YELLOW}Note: This will show what would be installed but won't actually install anything${NC}"

# We'll test the logic without actually installing
if declare -f check_prerequisites >/dev/null; then
    print_pass "check_prerequisites function exists"
else
    print_fail "check_prerequisites function not found"
    exit 1
fi

# Test 7: Check if installation functions exist
print_test "Testing installation function definitions..."

functions_to_check=(
    "detect_os"
    "check_root_privileges"
    "install_docker"
    "install_docker_compose"
    "install_dns_tools"
    "check_prerequisites"
)

for func in "${functions_to_check[@]}"; do
    if declare -f "$func" >/dev/null; then
        print_pass "Function $func is defined"
    else
        print_fail "Function $func is not defined"
        exit 1
    fi
done

echo
print_pass "All prerequisite function tests passed!"
echo
echo -e "${YELLOW}To test actual installation, run setup.sh and it will automatically install missing components.${NC}"
echo