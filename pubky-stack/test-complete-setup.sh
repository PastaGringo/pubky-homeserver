#!/bin/bash

# Complete setup validation test for pubky-stack
echo "🧪 Testing complete pubky-stack setup..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0

# Test function
test_check() {
    local description="$1"
    local command="$2"
    
    echo -n "Testing: $description... "
    
    if eval "$command" >/dev/null 2>&1; then
        echo -e "${GREEN}PASS${NC}"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}FAIL${NC}"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Test file existence
test_file() {
    local description="$1"
    local file="$2"
    
    test_check "$description" "[ -f '$file' ]"
}

# Test directory existence
test_dir() {
    local description="$1"
    local dir="$2"
    
    test_check "$description" "[ -d '$dir' ]"
}

echo "📁 Testing file structure..."

# Core files
test_file "Main setup script" "setup.sh"
test_file "Docker Compose configuration" "docker-compose.yml"
test_file "Environment template" ".env.example"
test_file "README documentation" "README.md"

# Configuration directories
test_dir "Caddy configuration directory" "config/caddy"
test_dir "Homeserver configuration directory" "config/homeserver"
test_dir "Nexus configuration directory" "config/nexus"

# Configuration files
test_file "Caddyfile template" "config/caddy/Caddyfile"
test_file "Homeserver configuration" "config/homeserver/homeserver.toml"
test_file "Nexus configuration" "config/nexus/nexus.toml"

# Scripts directory
test_dir "Scripts directory" "scripts"
test_file "Quick start script" "scripts/quick-start.sh"
test_file "Production setup script" "scripts/production-setup.sh"
test_file "Test setup script" "scripts/test-setup.sh"

# Test scripts
test_file "DNS validation test" "test-dns-validation.sh"

echo ""
echo "🔧 Testing script functionality..."

# Test script executability
test_check "Main setup script is executable" "[ -x 'setup.sh' ]"
test_check "Quick start script is executable" "[ -x 'scripts/quick-start.sh' ]"
test_check "Production setup script is executable" "[ -x 'scripts/production-setup.sh' ]"
test_check "Test setup script is executable" "[ -x 'scripts/test-setup.sh' ]"
test_check "DNS validation test is executable" "[ -x 'test-dns-validation.sh' ]"

# Test setup.sh functions
test_check "validate_dns function exists in setup.sh" "grep -q 'validate_dns()' setup.sh"
test_check "generate_caddyfile_from_domains function exists" "grep -q 'generate_caddyfile_from_domains()' setup.sh"
test_check "setup_environment function exists" "grep -q 'setup_environment()' setup.sh"

echo ""
echo "🐳 Testing Docker configuration..."

# Test Docker Compose syntax
test_check "Docker Compose file syntax is valid" "docker-compose config >/dev/null 2>&1"

# Test environment variables
test_check "CADDY_EMAIL in .env.example" "grep -q 'CADDY_EMAIL=' .env.example"
test_check "CADDY_EMAIL in docker-compose.yml" "grep -q 'CADDY_EMAIL' docker-compose.yml"

# Test service definitions
test_check "Caddy service defined" "grep -q 'caddy:' docker-compose.yml"
test_check "Homeserver service defined" "grep -q 'homeserver:' docker-compose.yml"
test_check "Nexus service defined" "grep -q 'nexus:' docker-compose.yml"
test_check "Pubky-app service defined" "grep -q 'pubky-app:' docker-compose.yml"

echo ""
echo "📋 Testing menu options..."

# Test main menu options
test_check "DNS validation option in menu" "grep -q '8.*DNS' setup.sh"
test_check "Cleanup option in menu" "grep -q '9.*Cleanup' setup.sh"
test_check "Exit option in menu" "grep -q '10.*Exit' setup.sh"

echo ""
echo "🔍 Testing configuration templates..."

# Test Caddyfile structure
test_check "Caddyfile has global options" "grep -q '{' config/caddy/Caddyfile"
test_check "Caddyfile has logging configuration" "grep -q 'log' config/caddy/Caddyfile"

# Test homeserver configuration
test_check "Homeserver config has bind address" "grep -q 'bind' config/homeserver/homeserver.toml"
test_check "Homeserver config has storage" "grep -q 'storage' config/homeserver/homeserver.toml"

# Test nexus configuration
test_check "Nexus config has server section" "grep -q '\[server\]' config/nexus/nexus.toml"

echo ""
echo "📚 Testing documentation..."

# Test README content
test_check "README has DNS configuration section" "grep -q 'DNS Configuration' README.md"
test_check "README has production setup section" "grep -q 'Production Setup' README.md"
test_check "README has development setup section" "grep -q 'Development Setup' README.md"

echo ""
echo "🎯 Testing production setup script..."

# Test production script structure
test_check "Production script has prerequisites check" "grep -q 'check_prerequisites' scripts/production-setup.sh"
test_check "Production script has DNS validation" "grep -q 'validate_dns' scripts/production-setup.sh"
test_check "Production script has Caddyfile generation" "grep -q 'generate_caddyfile' scripts/production-setup.sh"

echo ""
echo "📊 Test Results Summary"
echo "======================"
echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"
echo -e "Total Tests: $((TESTS_PASSED + TESTS_FAILED))"

if [ $TESTS_FAILED -eq 0 ]; then
    echo ""
    echo -e "${GREEN}🎉 All tests passed! The pubky-stack setup is complete and ready for use.${NC}"
    echo ""
    echo "Next steps:"
    echo "1. For development: ./scripts/quick-start.sh"
    echo "2. For production: ./scripts/production-setup.sh"
    echo "3. For interactive setup: ./setup.sh"
    exit 0
else
    echo ""
    echo -e "${RED}❌ Some tests failed. Please review the setup.${NC}"
    exit 1
fi