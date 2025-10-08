#!/bin/bash

# Pubky Stack Setup and Management Script
# Interactive script to configure and launch the complete Pubky stack

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
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Configuration files
ENV_FILE="$SCRIPT_DIR/.env"
DOCKER_COMPOSE_FILE="$PROJECT_ROOT/docker-compose.yml"

# Default values
DEFAULT_HOMESERVER="e9qbrpxu7bdfiq863bny1xdfs4patdem8fp1grq5qe5tafep7a7o"
DEFAULT_NEXUS="https://nexus.pubky.fractalized.net"
DEFAULT_HTTP_RELAY="https://httprelay.pubky.fractalized.net/link"
DEFAULT_PKARR_RELAYS='["https://pkarr.pubky.app","https://pkarr.pubky.org"]'
DEFAULT_TESTNET="false"
DEFAULT_PLAUSIBLE="false"

# Function to print colored output
print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to print header
print_header() {
    echo
    print_color $CYAN "=================================="
    print_color $CYAN "$1"
    print_color $CYAN "=================================="
    echo
}

# Function to print step
print_step() {
    print_color $BLUE "➤ $1"
}

# Function to print success
print_success() {
    print_color $GREEN "✓ $1"
}

# Function to print warning
print_warning() {
    print_color $YELLOW "⚠ $1"
}

# Function to print error
print_error() {
    print_color $RED "✗ $1"
}

# Function to ask yes/no question
ask_yes_no() {
    local question=$1
    local default=${2:-"y"}
    
    if [[ $default == "y" ]]; then
        local prompt="[Y/n]"
    else
        local prompt="[y/N]"
    fi
    
    while true; do
        read -p "$(echo -e "${YELLOW}${question} ${prompt}: ${NC}")" yn
        case $yn in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            "" ) 
                if [[ $default == "y" ]]; then
                    return 0
                else
                    return 1
                fi
                ;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

# Function to ask for input with default
ask_input() {
    local question=$1
    local default=$2
    local var_name=$3
    
    read -p "$(echo -e "${YELLOW}${question} [${default}]: ${NC}")" input
    if [[ -z "$input" ]]; then
        input="$default"
    fi
    
    # Set the variable dynamically
    eval "$var_name=\"$input\""
}

# Function to detect OS
detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$ID
        OS_VERSION=$VERSION_ID
    elif [[ -f /etc/redhat-release ]]; then
        OS="centos"
    elif [[ -f /etc/debian_version ]]; then
        OS="debian"
    else
        OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    fi
}

# Function to check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        return 0
    else
        return 1
    fi
}

# Function to install Docker
install_docker() {
    print_step "Installing Docker..."
    
    detect_os
    
    case $OS in
        ubuntu|debian)
            if ! check_root; then
                print_warning "Docker installation requires sudo privileges"
                if ! ask_yes_no "Continue with Docker installation?" "y"; then
                    return 1
                fi
            fi
            
            # Update package index
            sudo apt-get update
            
            # Install prerequisites
            sudo apt-get install -y \
                ca-certificates \
                curl \
                gnupg \
                lsb-release
            
            # Add Docker's official GPG key
            sudo mkdir -p /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/$OS/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            
            # Set up the repository
            echo \
                "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$OS \
                $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            
            # Update package index again
            sudo apt-get update
            
            # Install Docker Engine
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin
            
            # Add current user to docker group
            sudo usermod -aG docker $USER
            
            print_success "Docker installed successfully"
            print_warning "Please log out and log back in for group changes to take effect"
            ;;
        centos|rhel|fedora)
            if ! check_root; then
                print_warning "Docker installation requires sudo privileges"
                if ! ask_yes_no "Continue with Docker installation?" "y"; then
                    return 1
                fi
            fi
            
            # Install yum-utils
            sudo yum install -y yum-utils
            
            # Add Docker repository
            sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            
            # Install Docker Engine
            sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin
            
            # Start and enable Docker
            sudo systemctl start docker
            sudo systemctl enable docker
            
            # Add current user to docker group
            sudo usermod -aG docker $USER
            
            print_success "Docker installed successfully"
            print_warning "Please log out and log back in for group changes to take effect"
            ;;
        *)
            print_error "Unsupported OS: $OS"
            print_error "Please install Docker manually: https://docs.docker.com/get-docker/"
            return 1
            ;;
    esac
}

# Function to install Docker Compose
install_docker_compose() {
    print_step "Installing Docker Compose..."
    
    # Check if we can install via package manager first
    detect_os
    
    case $OS in
        ubuntu|debian)
            if ! check_root; then
                print_warning "Docker Compose installation requires sudo privileges"
                if ! ask_yes_no "Continue with Docker Compose installation?" "y"; then
                    return 1
                fi
            fi
            
            # Try to install via apt first
            if sudo apt-get install -y docker-compose-plugin; then
                print_success "Docker Compose installed via package manager"
                return 0
            fi
            ;;
        centos|rhel|fedora)
            if ! check_root; then
                print_warning "Docker Compose installation requires sudo privileges"
                if ! ask_yes_no "Continue with Docker Compose installation?" "y"; then
                    return 1
                fi
            fi
            
            # Try to install via yum/dnf first
            if sudo yum install -y docker-compose-plugin 2>/dev/null || sudo dnf install -y docker-compose-plugin 2>/dev/null; then
                print_success "Docker Compose installed via package manager"
                return 0
            fi
            ;;
    esac
    
    # Fallback to manual installation
    print_step "Installing Docker Compose manually..."
    
    # Get latest version
    local latest_version=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    
    if [[ -z "$latest_version" ]]; then
        latest_version="v2.24.1"  # Fallback version
        print_warning "Could not detect latest version, using fallback: $latest_version"
    fi
    
    # Download and install
    sudo curl -L "https://github.com/docker/compose/releases/download/$latest_version/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    
    # Create symlink for docker compose command
    sudo ln -sf /usr/local/bin/docker-compose /usr/local/bin/docker-compose
    
    print_success "Docker Compose installed successfully"
}

# Function to install DNS tools
install_dns_tools() {
    print_step "Installing DNS tools (dig, nslookup)..."
    
    detect_os
    
    case $OS in
        ubuntu|debian)
            if ! check_root; then
                print_warning "DNS tools installation requires sudo privileges"
                if ! ask_yes_no "Continue with DNS tools installation?" "y"; then
                    return 1
                fi
            fi
            
            sudo apt-get update
            sudo apt-get install -y dnsutils
            ;;
        centos|rhel|fedora)
            if ! check_root; then
                print_warning "DNS tools installation requires sudo privileges"
                if ! ask_yes_no "Continue with DNS tools installation?" "y"; then
                    return 1
                fi
            fi
            
            if command -v dnf >/dev/null 2>&1; then
                sudo dnf install -y bind-utils
            else
                sudo yum install -y bind-utils
            fi
            ;;
        *)
            print_error "Unsupported OS: $OS"
            print_error "Please install DNS tools manually"
            return 1
            ;;
    esac
    
    print_success "DNS tools installed successfully"
}

# Function to check and install prerequisites
check_prerequisites() {
    print_header "CHECKING PREREQUISITES"
    
    local missing_tools=()
    local install_needed=false
    
    # Check Docker
    if ! command -v docker >/dev/null 2>&1; then
        print_warning "Docker is not installed"
        missing_tools+=("docker")
        install_needed=true
    else
        print_success "Docker is installed"
        
        # Check if Docker daemon is running
        if ! docker info >/dev/null 2>&1; then
            print_warning "Docker daemon is not running"
            if ask_yes_no "Start Docker daemon?" "y"; then
                if check_root; then
                    systemctl start docker
                else
                    sudo systemctl start docker
                fi
            fi
        fi
    fi
    
    # Check Docker Compose
    if ! command -v docker-compose >/dev/null 2>&1 && ! docker compose version >/dev/null 2>&1; then
        print_warning "Docker Compose is not installed"
        missing_tools+=("docker-compose")
        install_needed=true
    else
        print_success "Docker Compose is installed"
    fi
    
    # Check DNS tools
    if ! command -v dig >/dev/null 2>&1; then
        print_warning "dig (DNS lookup tool) is not installed"
        missing_tools+=("dns-tools")
        install_needed=true
    else
        print_success "DNS tools are installed"
    fi
    
    # Check curl
    if ! command -v curl >/dev/null 2>&1; then
        print_warning "curl is not installed"
        missing_tools+=("curl")
        install_needed=true
    else
        print_success "curl is installed"
    fi
    
    # Install missing tools if needed
    if [[ $install_needed == true ]]; then
        echo
        print_warning "Some required tools are missing: ${missing_tools[*]}"
        
        if ask_yes_no "Install missing prerequisites automatically?" "y"; then
            for tool in "${missing_tools[@]}"; do
                case $tool in
                    docker)
                        install_docker || return 1
                        ;;
                    docker-compose)
                        install_docker_compose || return 1
                        ;;
                    dns-tools)
                        install_dns_tools || return 1
                        ;;
                    curl)
                        print_step "Installing curl..."
                        detect_os
                        case $OS in
                            ubuntu|debian)
                                sudo apt-get update && sudo apt-get install -y curl
                                ;;
                            centos|rhel|fedora)
                                if command -v dnf >/dev/null 2>&1; then
                                    sudo dnf install -y curl
                                else
                                    sudo yum install -y curl
                                fi
                                ;;
                        esac
                        print_success "curl installed successfully"
                        ;;
                esac
            done
            
            print_success "All prerequisites installed successfully"
            
            # Check if Docker group membership requires re-login
            if [[ " ${missing_tools[*]} " =~ " docker " ]]; then
                print_warning "Docker was installed. You may need to log out and log back in for group changes to take effect."
                if ask_yes_no "Continue anyway? (Docker commands may require sudo)" "y"; then
                    return 0
                else
                    print_error "Please log out and log back in, then run the setup again"
                    return 1
                fi
            fi
        else
            print_error "Cannot proceed without required prerequisites"
            print_error "Please install the missing tools manually:"
            for tool in "${missing_tools[@]}"; do
                case $tool in
                    docker)
                        print_error "  - Docker: https://docs.docker.com/get-docker/"
                        ;;
                    docker-compose)
                        print_error "  - Docker Compose: https://docs.docker.com/compose/install/"
                        ;;
                    dns-tools)
                        print_error "  - DNS tools: apt install dnsutils (Ubuntu/Debian) or yum install bind-utils (CentOS/RHEL)"
                        ;;
                    curl)
                        print_error "  - curl: apt install curl (Ubuntu/Debian) or yum install curl (CentOS/RHEL)"
                        ;;
                esac
            done
            return 1
        fi
    else
        print_success "All prerequisites are installed"
    fi
    
    return 0
}

# Function to check if Docker is running
check_docker() {
    print_step "Checking Docker installation..."
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        print_error "Docker is not running. Please start Docker first."
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        print_error "Docker Compose is not available. Please install Docker Compose."
        exit 1
    fi
    
    print_success "Docker is ready"
}

# Function to load existing configuration
load_config() {
    if [[ -f "$ENV_FILE" ]]; then
        print_step "Loading existing configuration..."
        source "$ENV_FILE"
        print_success "Configuration loaded from $ENV_FILE"
        return 0
    else
        print_warning "No existing configuration found. Will create new one."
        return 1
    fi
}

# Function to configure environment variables
configure_environment() {
    print_header "ENVIRONMENT CONFIGURATION"
    
    # Load existing config if available
    local config_exists=false
    if load_config; then
        config_exists=true
        if ask_yes_no "Use existing configuration?" "y"; then
            return 0
        fi
    fi
    
    print_step "Configuring environment variables..."
    
    # Homeserver configuration
    ask_input "Homeserver ID" "${NEXT_PUBLIC_HOMESERVER:-$DEFAULT_HOMESERVER}" "NEXT_PUBLIC_HOMESERVER"
    
    # Nexus configuration
    ask_input "Nexus URL" "${NEXT_PUBLIC_NEXUS:-$DEFAULT_NEXUS}" "NEXT_PUBLIC_NEXUS"
    
    # HTTP Relay configuration
    ask_input "HTTP Relay URL" "${NEXT_PUBLIC_DEFAULT_HTTP_RELAY:-$DEFAULT_HTTP_RELAY}" "NEXT_PUBLIC_DEFAULT_HTTP_RELAY"
    
    # PKARR Relays configuration
    ask_input "PKARR Relays (JSON array)" "${NEXT_PUBLIC_PKARR_RELAYS:-$DEFAULT_PKARR_RELAYS}" "NEXT_PUBLIC_PKARR_RELAYS"
    
    # Testnet configuration
    if ask_yes_no "Enable testnet mode?" "n"; then
        NEXT_PUBLIC_TESTNET="true"
    else
        NEXT_PUBLIC_TESTNET="false"
    fi
    
    # Plausible analytics
    if ask_yes_no "Enable Plausible analytics?" "n"; then
        NEXT_ENABLE_PLAUSIBLE="true"
    else
        NEXT_ENABLE_PLAUSIBLE="false"
    fi
    
    # Git branch and ref for pubky-app
    ask_input "Pubky App Git Branch" "${PUBKY_APP_BRANCH:-dev}" "PUBKY_APP_BRANCH"
    ask_input "Pubky App Git Ref (optional)" "${PUBKY_APP_REF:-}" "PUBKY_APP_REF"
    
    # Generate build date
    PUBKY_APP_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Save configuration
    save_config
}

# Function to save configuration to .env file
save_config() {
    print_step "Saving configuration..."
    
    cat > "$ENV_FILE" << EOF
# Pubky Stack Environment Configuration
# Generated on $(date)

# Homeserver Configuration
NEXT_PUBLIC_HOMESERVER=$NEXT_PUBLIC_HOMESERVER

# Nexus Configuration
NEXT_PUBLIC_NEXUS=$NEXT_PUBLIC_NEXUS

# HTTP Relay Configuration
NEXT_PUBLIC_DEFAULT_HTTP_RELAY=$NEXT_PUBLIC_DEFAULT_HTTP_RELAY

# PKARR Relays Configuration
NEXT_PUBLIC_PKARR_RELAYS=$NEXT_PUBLIC_PKARR_RELAYS

# Application Configuration
NEXT_PUBLIC_TESTNET=$NEXT_PUBLIC_TESTNET
NEXT_ENABLE_PLAUSIBLE=$NEXT_ENABLE_PLAUSIBLE

# Build Configuration
PUBKY_APP_BRANCH=$PUBKY_APP_BRANCH
PUBKY_APP_REF=$PUBKY_APP_REF
PUBKY_APP_DATE=$PUBKY_APP_DATE
EOF
    
    print_success "Configuration saved to $ENV_FILE"
}

# Function to generate docker-compose override
generate_docker_compose_override() {
    print_step "Generating docker-compose override..."
    
    local override_file="$PROJECT_ROOT/docker-compose.override.yml"
    
    cat > "$override_file" << EOF
# Docker Compose Override - Generated by Pubky Stack Setup
# This file overrides the default docker-compose.yml with environment-specific values

services:
  pubky-app:
    build:
      args:
        NEXT_PUBLIC_HOMESERVER: \${NEXT_PUBLIC_HOMESERVER}
        NEXT_PUBLIC_NEXUS: \${NEXT_PUBLIC_NEXUS}
        NEXT_PUBLIC_TESTNET: \${NEXT_PUBLIC_TESTNET}
        NEXT_PUBLIC_DEFAULT_HTTP_RELAY: \${NEXT_PUBLIC_DEFAULT_HTTP_RELAY}
        NEXT_PUBLIC_PKARR_RELAYS: \${NEXT_PUBLIC_PKARR_RELAYS}
        NEXT_ENABLE_PLAUSIBLE: \${NEXT_ENABLE_PLAUSIBLE}
        PUBKY_APP_BRANCH: \${PUBKY_APP_BRANCH}
        PUBKY_APP_REF: \${PUBKY_APP_REF}
        PUBKY_APP_DATE: \${PUBKY_APP_DATE}
    environment:
      - NEXT_PUBLIC_HOMESERVER=\${NEXT_PUBLIC_HOMESERVER}
      - NEXT_PUBLIC_NEXUS=\${NEXT_PUBLIC_NEXUS}
      - NEXT_PUBLIC_TESTNET=\${NEXT_PUBLIC_TESTNET}
      - NEXT_PUBLIC_DEFAULT_HTTP_RELAY=\${NEXT_PUBLIC_DEFAULT_HTTP_RELAY}
      - NEXT_PUBLIC_PKARR_RELAYS=\${NEXT_PUBLIC_PKARR_RELAYS}
      - NEXT_ENABLE_PLAUSIBLE=\${NEXT_ENABLE_PLAUSIBLE}

  homeserver:
    environment:
      - NEXT_PUBLIC_HOMESERVER=\${NEXT_PUBLIC_HOMESERVER}
      - NEXT_PUBLIC_NEXUS=\${NEXT_PUBLIC_NEXUS}
      - NEXT_PUBLIC_DEFAULT_HTTP_RELAY=\${NEXT_PUBLIC_DEFAULT_HTTP_RELAY}
      - NEXT_PUBLIC_PKARR_RELAYS=\${NEXT_PUBLIC_PKARR_RELAYS}
      - NEXT_ENABLE_PLAUSIBLE=\${NEXT_ENABLE_PLAUSIBLE}
EOF
    
    print_success "Docker Compose override generated"
}

# Function to validate DNS records
validate_dns() {
    print_header "DNS VALIDATION"
    
    if ask_yes_no "Do you want to validate DNS records for SSL certificate generation?" "y"; then
        print_step "DNS validation for SSL certificates..."
        
        # Ask for domains to validate
        echo
        print_color $YELLOW "Enter the domains you want to validate (one per line, empty line to finish):"
        
        local domains=()
        while true; do
            read -p "$(echo -e "${YELLOW}Domain: ${NC}")" domain
            if [[ -z "$domain" ]]; then
                break
            fi
            domains+=("$domain")
        done
        
        if [[ ${#domains[@]} -eq 0 ]]; then
            print_warning "No domains provided, skipping DNS validation"
            return 0
        fi
        
        local validation_failed=false
        
        for domain in "${domains[@]}"; do
            print_step "Validating DNS for $domain..."
            
            # Check if domain resolves
            if nslookup "$domain" >/dev/null 2>&1; then
                # Get the IP address
                local resolved_ip=$(nslookup "$domain" | grep -A1 "Name:" | tail -1 | awk '{print $2}' | head -1)
                if [[ -z "$resolved_ip" ]]; then
                    resolved_ip=$(dig +short "$domain" | head -1)
                fi
                
                if [[ -n "$resolved_ip" ]]; then
                    print_success "$domain resolves to $resolved_ip"
                    
                    # Check if it's pointing to this server
                    local server_ip=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "unknown")
                    if [[ "$resolved_ip" == "$server_ip" ]]; then
                        print_success "$domain points to this server ($server_ip)"
                    else
                        print_warning "$domain points to $resolved_ip, but this server is $server_ip"
                        print_color $YELLOW "  Make sure your DNS is correctly configured for SSL certificates"
                    fi
                    
                    # Test HTTP connectivity
                    if command -v curl >/dev/null 2>&1; then
                        if curl -s --connect-timeout 5 "http://$domain" >/dev/null 2>&1; then
                            print_success "$domain is reachable via HTTP"
                        else
                            print_warning "$domain is not reachable via HTTP (this is normal if no server is running yet)"
                        fi
                    fi
                else
                    print_error "$domain does not resolve to an IP address"
                    validation_failed=true
                fi
            else
                print_error "$domain does not resolve"
                validation_failed=true
            fi
            
            # Check for CAA records that might block Let's Encrypt
            if command -v dig >/dev/null 2>&1; then
                local caa_records=$(dig +short CAA "$domain" 2>/dev/null)
                if [[ -n "$caa_records" ]]; then
                    if echo "$caa_records" | grep -q "letsencrypt.org"; then
                        print_success "$domain has CAA records allowing Let's Encrypt"
                    else
                        print_warning "$domain has CAA records that might block Let's Encrypt:"
                        echo "$caa_records" | while read -r line; do
                            print_color $YELLOW "    $line"
                        done
                    fi
                fi
            fi
            
            echo
        done
        
        if [[ "$validation_failed" == "true" ]]; then
            print_error "Some DNS validations failed!"
            echo
            print_color $YELLOW "DNS Issues detected. Recommendations:"
            print_color $CYAN "  1. Ensure all domains point to this server's IP address"
            print_color $CYAN "  2. Wait for DNS propagation (can take up to 48 hours)"
            print_color $CYAN "  3. Check your DNS provider's configuration"
            print_color $CYAN "  4. Verify CAA records allow Let's Encrypt if present"
            echo
            
            if ! ask_yes_no "Continue anyway? (SSL certificates may fail to generate)" "n"; then
                print_error "Deployment cancelled due to DNS issues"
                exit 1
            fi
        else
            print_success "All DNS validations passed!"
        fi
        
        # Save validated domains for Caddy configuration
        if [[ ${#domains[@]} -gt 0 ]]; then
            echo "# Validated domains for SSL certificates" > "$SCRIPT_DIR/.validated_domains"
            printf '%s\n' "${domains[@]}" >> "$SCRIPT_DIR/.validated_domains"
            print_success "Validated domains saved for Caddy configuration"
            
            # Ask if user wants to auto-generate Caddyfile
            if ask_yes_no "Do you want to auto-generate Caddyfile from validated domains?" "y"; then
                generate_caddyfile_from_domains
            fi
        fi
    else
        print_warning "Skipping DNS validation - SSL certificates may fail if DNS is not properly configured"
    fi
}

# Function to generate Caddyfile from validated domains
generate_caddyfile_from_domains() {
    if [[ -f "$SCRIPT_DIR/.validated_domains" ]]; then
        print_step "Generating Caddyfile from validated domains..."
        
        local caddyfile="$SCRIPT_DIR/configs/caddy/Caddyfile"
        local backup_file="$caddyfile.backup.$(date +%Y%m%d_%H%M%S)"
        
        # Backup existing Caddyfile
        if [[ -f "$caddyfile" ]]; then
            cp "$caddyfile" "$backup_file"
            print_success "Existing Caddyfile backed up to $(basename "$backup_file")"
        fi
        
        # Read validated domains
        local domains=()
        while IFS= read -r domain; do
            [[ "$domain" =~ ^#.*$ ]] && continue  # Skip comments
            [[ -n "$domain" ]] && domains+=("$domain")
        done < "$SCRIPT_DIR/.validated_domains"
        
        if [[ ${#domains[@]} -eq 0 ]]; then
            print_warning "No validated domains found, keeping existing Caddyfile"
            return 0
        fi
        
        # Generate new Caddyfile
        cat > "$caddyfile" << EOF
# Auto-generated Caddyfile from validated domains
# Generated on $(date)

# Global options
{
    email {env.CADDY_EMAIL}
    admin off
    log {
        output file /var/log/caddy/access.log
        format json
    }
}

EOF

        # Add each domain configuration
        for domain in "${domains[@]}"; do
            # Determine service based on domain pattern
            local service="pubky-app"
            local port="3000"
            
            if [[ "$domain" =~ nexus\. ]]; then
                service="nexusd"
                port="8080"
            elif [[ "$domain" =~ homeserver\. ]]; then
                service="homeserver"
                port="8000"
            elif [[ "$domain" =~ relay\. ]] || [[ "$domain" =~ httprelay\. ]]; then
                service="httprelay"
                port="8080"
            fi
            
            cat >> "$caddyfile" << EOF
# Configuration for $domain
$domain {
    reverse_proxy $service:$port {
        health_check /health
        health_check_interval 30s
        health_check_timeout 10s
    }
    
    log {
        output file /var/log/caddy/$domain.log
        format json
    }
    
    header {
        # Security headers
        Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
        X-Content-Type-Options "nosniff"
        X-Frame-Options "DENY"
        X-XSS-Protection "1; mode=block"
        Referrer-Policy "strict-origin-when-cross-origin"
        
        # CORS headers for API endpoints
        Access-Control-Allow-Origin "*"
        Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS"
        Access-Control-Allow-Headers "Content-Type, Authorization, X-Requested-With"
    }
    
    # Handle CORS preflight requests
    @options method OPTIONS
    respond @options 204
}

EOF
        done
        
        print_success "Caddyfile generated with ${#domains[@]} domain(s)"
        print_color $CYAN "Configured domains:"
        for domain in "${domains[@]}"; do
            print_color $CYAN "  - $domain"
        done
        
        if ask_yes_no "Do you want to review the generated Caddyfile?" "n"; then
            echo
            print_color $YELLOW "Generated Caddyfile content:"
            echo "----------------------------------------"
            cat "$caddyfile"
            echo "----------------------------------------"
        fi
    fi
}

# Function to setup directories
setup_directories() {
    print_step "Setting up directories..."
    
    # Create necessary directories
    mkdir -p "$SCRIPT_DIR/data/homeserver"
    mkdir -p "$SCRIPT_DIR/data/nexus"
    mkdir -p "$SCRIPT_DIR/data/caddy"
    mkdir -p "$SCRIPT_DIR/configs/caddy"
    mkdir -p "$SCRIPT_DIR/configs/homeserver"
    mkdir -p "$SCRIPT_DIR/configs/nexus"
    mkdir -p "$SCRIPT_DIR/logs"
    
    print_success "Directories created"
}

# Function to copy and configure Caddy
setup_caddy() {
    print_step "Setting up Caddy configuration..."
    
    local caddy_config="$SCRIPT_DIR/configs/caddy/Caddyfile"
    
    if [[ ! -f "$caddy_config" ]]; then
        # Copy default Caddyfile if it doesn't exist
        if [[ -f "$PROJECT_ROOT/caddy/Caddyfile" ]]; then
            cp "$PROJECT_ROOT/caddy/Caddyfile" "$caddy_config"
            print_success "Caddy configuration copied"
        else
            print_warning "No default Caddyfile found, creating basic configuration"
            cat > "$caddy_config" << EOF
# Basic Caddy configuration for Pubky Stack
localhost:80 {
    reverse_proxy pubky-app:4200
}

localhost:8080 {
    reverse_proxy nexusd:8080
}
EOF
        fi
    else
        print_success "Caddy configuration already exists"
    fi
}

# Function to build services
build_services() {
    print_header "BUILDING SERVICES"
    
    if ask_yes_no "Build all services?" "y"; then
        print_step "Building Docker images..."
        
        cd "$PROJECT_ROOT"
        
        # Export environment variables
        export $(cat "$ENV_FILE" | grep -v '^#' | xargs)
        
        # Build services
        if command -v docker-compose &> /dev/null; then
            docker-compose build --no-cache
        else
            docker compose build --no-cache
        fi
        
        print_success "All services built successfully"
    fi
}

# Function to start services
start_services() {
    print_header "STARTING SERVICES"
    
    cd "$PROJECT_ROOT"
    
    # Export environment variables
    export $(cat "$ENV_FILE" | grep -v '^#' | xargs)
    
    print_step "Starting Pubky Stack..."
    
    # Start services
    if command -v docker-compose &> /dev/null; then
        docker-compose up -d
    else
        docker compose up -d
    fi
    
    print_success "Pubky Stack started successfully!"
    
    # Show status
    show_status
}

# Function to stop services
stop_services() {
    print_header "STOPPING SERVICES"
    
    cd "$PROJECT_ROOT"
    
    print_step "Stopping Pubky Stack..."
    
    if command -v docker-compose &> /dev/null; then
        docker-compose down
    else
        docker compose down
    fi
    
    print_success "Pubky Stack stopped"
}

# Function to show status
show_status() {
    print_header "SERVICE STATUS"
    
    cd "$PROJECT_ROOT"
    
    if command -v docker-compose &> /dev/null; then
        docker-compose ps
    else
        docker compose ps
    fi
    
    echo
    print_color $GREEN "Access URLs:"
    print_color $CYAN "  • Pubky App: http://localhost (via Caddy)"
    print_color $CYAN "  • Nexus: http://localhost:8080"
    print_color $CYAN "  • Homeserver: http://localhost:6287"
    echo
}

# Function to show logs
show_logs() {
    print_header "SERVICE LOGS"
    
    cd "$PROJECT_ROOT"
    
    echo "Available services:"
    echo "  1. pubky-app"
    echo "  2. nexusd"
    echo "  3. homeserver"
    echo "  4. caddy"
    echo "  5. httprelay"
    echo "  6. all"
    echo
    
    read -p "$(echo -e "${YELLOW}Select service (1-6): ${NC}")" choice
    
    case $choice in
        1) service="pubky-app";;
        2) service="nexusd";;
        3) service="homeserver";;
        4) service="caddy";;
        5) service="httprelay";;
        6) service="";;
        *) print_error "Invalid choice"; return 1;;
    esac
    
    if command -v docker-compose &> /dev/null; then
        docker-compose logs -f $service
    else
        docker compose logs -f $service
    fi
}

# Function to restart services
restart_services() {
    print_header "RESTARTING SERVICES"
    
    stop_services
    sleep 2
    start_services
}

# Function to clean up
cleanup() {
    print_header "CLEANUP"
    
    if ask_yes_no "Remove all containers and volumes?" "n"; then
        cd "$PROJECT_ROOT"
        
        print_step "Cleaning up..."
        
        if command -v docker-compose &> /dev/null; then
            docker-compose down -v --remove-orphans
        else
            docker compose down -v --remove-orphans
        fi
        
        # Remove images
        if ask_yes_no "Also remove Docker images?" "n"; then
            docker image prune -f
        fi
        
        print_success "Cleanup completed"
    fi
}

# Main menu
show_menu() {
    echo
    print_color $PURPLE "╔══════════════════════════════════════╗"
    print_color $PURPLE "║          PUBKY STACK MANAGER        ║"
    print_color $PURPLE "╚══════════════════════════════════════╝"
    echo
    echo "1. Configure Environment"
    echo "2. Setup & Build Services"
    echo "3. Start Stack"
    echo "4. Stop Stack"
    echo "5. Restart Stack"
    echo "6. Show Status"
    echo "7. Show Logs"
    echo "8. Validate DNS for SSL certificates"
    echo "9. Cleanup"
    echo "10. Exit"
    echo
}

# Main function
main() {
    print_header "PUBKY STACK SETUP"
    
    # Check and install prerequisites
    if ! check_prerequisites; then
        print_error "Prerequisites check failed. Cannot continue."
        exit 1
    fi
    
    # Setup directories
    setup_directories
    
    while true; do
        show_menu
        read -p "$(echo -e "${YELLOW}Select option (1-9): ${NC}")" choice
        
        case $choice in
            1)
                configure_environment
                generate_docker_compose_override
                setup_caddy
                ;;
            2)
                if [[ ! -f "$ENV_FILE" ]]; then
                    print_warning "No configuration found. Please configure environment first."
                    configure_environment
                    generate_docker_compose_override
                    setup_caddy
                fi
                validate_dns
                build_services
                ;;
            3)
                if [[ ! -f "$ENV_FILE" ]]; then
                    print_error "No configuration found. Please configure environment first."
                    continue
                fi
                start_services
                ;;
            4)
                stop_services
                ;;
            5)
                restart_services
                ;;
            6)
                show_status
                ;;
            7)
            show_logs
            ;;
        8)
            validate_dns
            ;;
        9)
            cleanup
            ;;
        10)
            print_success "Goodbye!"
            exit 0
            ;;
        *)
            print_error "Invalid option. Please try again."
            ;;
        esac
        
        echo
        read -p "$(echo -e "${YELLOW}Press Enter to continue...${NC}")"
    done
}

# Run main function
main "$@"