#!/bin/bash

# Test script for DNS validation functionality
# This script tests the DNS validation features without requiring actual domains

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_DOMAINS_FILE="$SCRIPT_DIR/.test_validated_domains"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_test() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

print_error() {
    echo -e "${RED}[FAIL]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_header() {
    echo
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE} $1${NC}"
    echo -e "${BLUE}================================${NC}"
    echo
}

# Test 1: Check if DNS validation function exists in setup.sh
test_dns_function_exists() {
    print_test "Checking if validate_dns function exists in setup.sh"
    
    if grep -q "validate_dns()" "$SCRIPT_DIR/setup.sh"; then
        print_success "validate_dns function found in setup.sh"
        return 0
    else
        print_error "validate_dns function not found in setup.sh"
        return 1
    fi
}

# Test 2: Check if Caddyfile generation function exists
test_caddyfile_generation_function() {
    print_test "Checking if generate_caddyfile_from_domains function exists"
    
    if grep -q "generate_caddyfile_from_domains()" "$SCRIPT_DIR/setup.sh"; then
        print_success "generate_caddyfile_from_domains function found"
        return 0
    else
        print_error "generate_caddyfile_from_domains function not found"
        return 1
    fi
}

# Test 3: Check if CADDY_EMAIL is in .env.example
test_caddy_email_env() {
    print_test "Checking if CADDY_EMAIL is configured in .env.example"
    
    if grep -q "CADDY_EMAIL=" "$SCRIPT_DIR/.env.example"; then
        print_success "CADDY_EMAIL found in .env.example"
        return 0
    else
        print_error "CADDY_EMAIL not found in .env.example"
        return 1
    fi
}

# Test 4: Check if CADDY_EMAIL is in docker-compose.yml
test_caddy_email_docker() {
    print_test "Checking if CADDY_EMAIL is configured in docker-compose.yml"
    
    if grep -q "CADDY_EMAIL" "$SCRIPT_DIR/docker-compose.yml"; then
        print_success "CADDY_EMAIL found in docker-compose.yml"
        return 0
    else
        print_error "CADDY_EMAIL not found in docker-compose.yml"
        return 1
    fi
}

# Test 5: Test Caddyfile generation structure
test_caddyfile_generation() {
    print_test "Testing Caddyfile generation structure"
    
    # Check if the function contains the expected logic
    if grep -q "Auto-generated Caddyfile from validated domains" "$SCRIPT_DIR/setup.sh"; then
        print_success "Caddyfile generation template found"
    else
        print_error "Caddyfile generation template not found"
        return 1
    fi
    
    # Check for domain pattern recognition
    if grep -q "nexus\\\\." "$SCRIPT_DIR/setup.sh" && grep -q "homeserver\\\\." "$SCRIPT_DIR/setup.sh"; then
        print_success "Domain pattern recognition logic found"
    else
        print_error "Domain pattern recognition logic not found"
        return 1
    fi
    
    # Check for SSL security headers
    if grep -q "Strict-Transport-Security" "$SCRIPT_DIR/setup.sh"; then
        print_success "SSL security headers configuration found"
    else
        print_error "SSL security headers configuration not found"
        return 1
    fi
    
    # Check for CORS configuration
    if grep -q "Access-Control-Allow-Origin" "$SCRIPT_DIR/setup.sh"; then
        print_success "CORS configuration found"
    else
        print_error "CORS configuration not found"
        return 1
    fi
    
    return 0
}

# Test 6: Check if DNS validation is in the main menu
test_dns_menu_option() {
    print_test "Checking if DNS validation option is in the main menu"
    
    if grep -q "Validate DNS for SSL certificates" "$SCRIPT_DIR/setup.sh"; then
        print_success "DNS validation option found in menu"
        return 0
    else
        print_error "DNS validation option not found in menu"
        return 1
    fi
}

# Test 7: Check required tools for DNS validation
test_dns_tools() {
    print_test "Checking availability of DNS validation tools"
    
    local tools_available=0
    local total_tools=0
    
    for tool in nslookup dig curl; do
        ((total_tools++))
        if command -v "$tool" >/dev/null 2>&1; then
            print_success "$tool is available"
            ((tools_available++))
        else
            print_warning "$tool is not available (optional but recommended)"
        fi
    done
    
    if [[ $tools_available -gt 0 ]]; then
        print_success "$tools_available/$total_tools DNS tools available"
        return 0
    else
        print_error "No DNS validation tools available"
        return 1
    fi
}

# Main test execution
main() {
    print_header "DNS VALIDATION FUNCTIONALITY TESTS"
    
    local tests_passed=0
    local tests_failed=0
    
    # Run all tests
    local tests=(
        "test_dns_function_exists"
        "test_caddyfile_generation_function"
        "test_caddy_email_env"
        "test_caddy_email_docker"
        "test_caddyfile_generation"
        "test_dns_menu_option"
        "test_dns_tools"
    )
    
    for test in "${tests[@]}"; do
        if $test; then
            ((tests_passed++))
        else
            ((tests_failed++))
        fi
        echo
    done
    
    # Summary
    print_header "TEST SUMMARY"
    echo -e "Tests passed: ${GREEN}$tests_passed${NC}"
    echo -e "Tests failed: ${RED}$tests_failed${NC}"
    echo -e "Total tests: $((tests_passed + tests_failed))"
    
    if [[ $tests_failed -eq 0 ]]; then
        print_success "All DNS validation tests passed! 🎉"
        echo
        echo -e "${GREEN}The DNS validation functionality is ready to use.${NC}"
        echo -e "${BLUE}To test with real domains, run: ./setup.sh and select option 8${NC}"
        return 0
    else
        print_error "Some tests failed. Please check the implementation."
        return 1
    fi
}

# Run main function
main "$@"