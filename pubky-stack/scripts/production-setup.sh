#!/bin/bash

# Production Setup Script for Pubky Stack
# This script sets up the Pubky Stack with DNS validation for production use

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STACK_DIR="$SCRIPT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_header() {
    echo
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE} $1${NC}"
    echo -e "${BLUE}================================${NC}"
    echo
}

print_step() {
    echo -e "${CYAN}[STEP]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

ask_yes_no() {
    local prompt="$1"
    local default="${2:-n}"
    local response
    
    while true; do
        if [[ "$default" == "y" ]]; then
            read -p "$prompt [Y/n]: " response
            response=${response:-y}
        else
            read -p "$prompt [y/N]: " response
            response=${response:-n}
        fi
        
        case "$response" in
            [Yy]|[Yy][Ee][Ss]) return 0 ;;
            [Nn]|[Nn][Oo]) return 1 ;;
            *) echo "Please answer yes or no." ;;
        esac
    done
}

# Check prerequisites
check_prerequisites() {
    print_header "CHECKING PREREQUISITES"
    
    # Check if Docker is installed
    if ! command -v docker >/dev/null 2>&1; then
        print_error "Docker is not installed. Please install Docker first."
        echo "Visit: https://docs.docker.com/get-docker/"
        exit 1
    fi
    print_success "Docker is installed"
    
    # Check if Docker Compose is installed
    if ! command -v docker-compose >/dev/null 2>&1 && ! docker compose version >/dev/null 2>&1; then
        print_error "Docker Compose is not installed. Please install Docker Compose first."
        echo "Visit: https://docs.docker.com/compose/install/"
        exit 1
    fi
    print_success "Docker Compose is installed"
    
    # Check if setup.sh exists
    if [[ ! -f "$SCRIPT_DIR/setup.sh" ]]; then
        print_error "setup.sh not found. Please run this script from the pubky-stack directory."
        exit 1
    fi
    print_success "Setup script found"
    
    # Check DNS tools
    local dns_tools=0
    for tool in nslookup dig curl; do
        if command -v "$tool" >/dev/null 2>&1; then
            ((dns_tools++))
        fi
    done
    
    if [[ $dns_tools -eq 0 ]]; then
        print_warning "No DNS validation tools found. Install nslookup, dig, or curl for better DNS validation."
    else
        print_success "$dns_tools DNS validation tools available"
    fi
}

# Setup environment
setup_environment() {
    print_header "ENVIRONMENT CONFIGURATION"
    
    if [[ ! -f "$SCRIPT_DIR/.env" ]]; then
        print_step "Creating environment file from template..."
        cp "$SCRIPT_DIR/.env.example" "$SCRIPT_DIR/.env"
        print_success "Environment file created"
    else
        print_warning "Environment file already exists"
        if ask_yes_no "Do you want to reconfigure it?" "n"; then
            cp "$SCRIPT_DIR/.env.example" "$SCRIPT_DIR/.env"
            print_success "Environment file recreated"
        fi
    fi
    
    # Configure email for SSL certificates
    echo
    print_step "Configuring SSL certificate email..."
    read -p "Enter your email for Let's Encrypt SSL certificates: " ssl_email
    
    if [[ -n "$ssl_email" ]]; then
        sed -i "s/CADDY_EMAIL=.*/CADDY_EMAIL=$ssl_email/" "$SCRIPT_DIR/.env"
        print_success "SSL email configured: $ssl_email"
    else
        print_warning "No email provided. Using default from template."
    fi
    
    # Set build date
    sed -i "s/PUBKY_APP_DATE=.*/PUBKY_APP_DATE=$(date +%Y%m%d_%H%M%S)/" "$SCRIPT_DIR/.env"
    print_success "Build date set"
}

# DNS validation and Caddyfile generation
setup_dns() {
    print_header "DNS VALIDATION & SSL CONFIGURATION"
    
    if ask_yes_no "Do you want to validate DNS records for SSL certificate generation?" "y"; then
        print_step "Starting DNS validation..."
        
        # Collect domains
        echo
        print_step "Enter your domains (one per line, empty line to finish):"
        
        local domains=()
        while true; do
            read -p "Domain: " domain
            if [[ -z "$domain" ]]; then
                break
            fi
            domains+=("$domain")
        done
        
        if [[ ${#domains[@]} -eq 0 ]]; then
            print_warning "No domains provided. Skipping DNS validation."
            return 0
        fi
        
        # Save domains for validation
        echo "# Production domains for SSL certificates" > "$SCRIPT_DIR/.validated_domains"
        printf '%s\n' "${domains[@]}" >> "$SCRIPT_DIR/.validated_domains"
        
        print_success "Domains saved for validation"
        print_step "Use './setup.sh' and select option 8 to validate these domains"
        
        # Ask about Caddyfile generation
        if ask_yes_no "Do you want to auto-generate Caddyfile from these domains?" "y"; then
            print_step "Generating Caddyfile..."
            
            # Run the setup script's DNS validation function
            cd "$SCRIPT_DIR"
            echo "8" | timeout 10 ./setup.sh >/dev/null 2>&1 || true
            
            if [[ -f "$SCRIPT_DIR/configs/caddy/Caddyfile" ]] && grep -q "Auto-generated" "$SCRIPT_DIR/configs/caddy/Caddyfile" 2>/dev/null; then
                print_success "Caddyfile generated successfully"
            else
                print_warning "Caddyfile generation may have failed. Please run './setup.sh' manually."
            fi
        fi
    else
        print_warning "Skipping DNS validation. SSL certificates may fail if DNS is not properly configured."
    fi
}

# Deploy the stack
deploy_stack() {
    print_header "DEPLOYING PUBKY STACK"
    
    cd "$SCRIPT_DIR"
    
    print_step "Building Docker images..."
    if docker-compose build; then
        print_success "Docker images built successfully"
    else
        print_error "Failed to build Docker images"
        exit 1
    fi
    
    print_step "Starting services..."
    if docker-compose up -d; then
        print_success "Services started successfully"
    else
        print_error "Failed to start services"
        exit 1
    fi
    
    # Wait for services to be ready
    print_step "Waiting for services to be ready..."
    sleep 10
    
    # Check service health
    print_step "Checking service health..."
    local healthy_services=0
    local total_services=0
    
    for service in pubky-app nexusd homeserver httprelay caddy; do
        ((total_services++))
        if docker-compose ps "$service" | grep -q "Up"; then
            print_success "$service is running"
            ((healthy_services++))
        else
            print_warning "$service may not be running properly"
        fi
    done
    
    if [[ $healthy_services -eq $total_services ]]; then
        print_success "All services are running!"
    else
        print_warning "$healthy_services/$total_services services are running"
    fi
}

# Show deployment information
show_deployment_info() {
    print_header "DEPLOYMENT COMPLETE"
    
    echo -e "${GREEN}🎉 Pubky Stack has been deployed successfully!${NC}"
    echo
    
    print_step "Access URLs:"
    if [[ -f "$SCRIPT_DIR/.validated_domains" ]]; then
        echo -e "${CYAN}Your configured domains:${NC}"
        while IFS= read -r domain; do
            [[ "$domain" =~ ^#.*$ ]] && continue
            [[ -n "$domain" ]] && echo -e "  ${GREEN}https://$domain${NC}"
        done < "$SCRIPT_DIR/.validated_domains"
    else
        echo -e "  ${CYAN}Local access:${NC}"
        echo -e "    Pubky App: ${GREEN}http://localhost${NC}"
        echo -e "    Nexus: ${GREEN}http://localhost:8080${NC}"
        echo -e "    Homeserver: ${GREEN}http://localhost:6287${NC}"
        echo -e "    HTTP Relay: ${GREEN}http://localhost:15412${NC}"
    fi
    
    echo
    print_step "Management commands:"
    echo -e "  View logs: ${CYAN}docker-compose logs -f${NC}"
    echo -e "  Stop stack: ${CYAN}docker-compose down${NC}"
    echo -e "  Restart stack: ${CYAN}docker-compose restart${NC}"
    echo -e "  Interactive setup: ${CYAN}./setup.sh${NC}"
    
    echo
    print_step "Important notes:"
    echo -e "  ${YELLOW}• SSL certificates may take a few minutes to generate${NC}"
    echo -e "  ${YELLOW}• Check logs if services are not accessible${NC}"
    echo -e "  ${YELLOW}• Ensure ports 80 and 443 are open for SSL certificates${NC}"
    
    if [[ -f "$SCRIPT_DIR/.validated_domains" ]]; then
        echo -e "  ${YELLOW}• Validate your DNS configuration with: ./setup.sh (option 8)${NC}"
    fi
}

# Main execution
main() {
    print_header "PUBKY STACK PRODUCTION SETUP"
    
    echo -e "${CYAN}This script will set up the Pubky Stack for production use with:${NC}"
    echo -e "  • Environment configuration"
    echo -e "  • DNS validation for SSL certificates"
    echo -e "  • Automatic Caddyfile generation"
    echo -e "  • Docker deployment"
    echo
    
    if ! ask_yes_no "Do you want to continue?" "y"; then
        print_warning "Setup cancelled by user"
        exit 0
    fi
    
    # Source the main setup script for prerequisite functions
    source "$STACK_DIR/setup.sh"
    
    # Check prerequisites
    print_step "Checking prerequisites..."
    if ! check_prerequisites; then
        print_error "Prerequisites check failed. Cannot continue."
        exit 1
    fi
    setup_environment
    setup_dns
    deploy_stack
    show_deployment_info
    
    echo
    print_success "Production setup complete! 🚀"
}

# Run main function
main "$@"