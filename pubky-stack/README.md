# Pubky Stack

An interactive setup and management system for the complete Pubky infrastructure stack.

## Overview

The Pubky Stack provides a simplified way to configure, build, and run the entire Pubky ecosystem using Docker and Docker Compose. It includes:

- **Pubky App**: The main web application
- **Nexus**: The Pubky nexus service
- **Homeserver**: The Pubky homeserver
- **Caddy**: Reverse proxy and load balancer
- **HTTP Relay**: HTTP relay service

## Quick Start

### Development Setup

For rapid deployment with default settings:

```bash
cd pubky-stack
./scripts/quick-start.sh
```

This will:
- Copy `.env.example` to `.env`
- Build all Docker services
- Start the stack
- Display access URLs

### Production Setup

For production deployment with DNS validation and SSL certificates:

```bash
cd pubky-stack
./scripts/production-setup.sh
```

This will:
- Check prerequisites (Docker, Docker Compose)
- Configure environment variables
- Validate DNS records for SSL certificates
- Auto-generate Caddyfile from validated domains
- Deploy the stack with proper SSL configuration
- Provide management commands and access information

### Interactive Setup

1. **Run the interactive setup script:**
   ```bash
   ./setup.sh
   ```

2. **Follow the interactive prompts to:**
   - Configure environment variables
   - Set up service configurations
   - Build Docker images
   - Start the stack

## Manual Setup

If you prefer manual configuration:

1. **Copy the environment template:**
   ```bash
   cp .env.example .env
   ```

2. **Edit the `.env` file** with your configuration values

3. **Start the stack:**
   ```bash
   docker-compose up -d
   ```

## Configuration

### Environment Variables

The stack uses the following key environment variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `NEXT_PUBLIC_HOMESERVER` | Homeserver ID | `e9qbrpxu7bdfiq863bny1xdfs4patdem8fp1grq5qe5tafep7a7o` |
| `NEXT_PUBLIC_NEXUS` | Nexus URL | `https://nexus.pubky.fractalized.net` |
| `NEXT_PUBLIC_DEFAULT_HTTP_RELAY` | HTTP Relay URL | `https://httprelay.pubky.fractalized.net/link` |
| `NEXT_PUBLIC_PKARR_RELAYS` | PKARR Relays (JSON) | `["https://pkarr.pubky.app","https://pkarr.pubky.org"]` |
| `NEXT_PUBLIC_TESTNET` | Enable testnet mode | `false` |
| `NEXT_ENABLE_PLAUSIBLE` | Enable analytics | `false` |

### Service Configuration

Each service has its own configuration directory:

- **Caddy**: `configs/caddy/Caddyfile`
- **Homeserver**: `configs/homeserver/`
- **Nexus**: `configs/nexus/config.toml`

### DNS Configuration for SSL Certificates

For automatic SSL certificate generation with Let's Encrypt, ensure your domains are properly configured:

#### DNS Requirements

- Domains must resolve to your server's public IP address
- Ports 80 and 443 must be accessible from the internet
- CAA records (if present) must allow Let's Encrypt
- DNS propagation may take up to 48 hours

#### DNS Validation

Use the built-in DNS validation feature to verify your domain configuration:

```bash
./setup.sh
# Select option 8: "Validate DNS for SSL certificates"
```

The validation process will:
- Check if domains resolve to IP addresses
- Verify domains point to your server
- Test HTTP connectivity
- Check CAA records for Let's Encrypt compatibility
- Save validated domains for automatic Caddyfile generation

#### Automatic Caddyfile Generation

After DNS validation, the script can auto-generate Caddy configuration based on validated domains:

**Supported Domain Patterns:**
- `nexus.*` → Routes to Nexus service (port 8080)
- `homeserver.*` → Routes to Homeserver service (port 8000)
- `relay.*` or `httprelay.*` → Routes to HTTP Relay service (port 8080)
- All other domains → Routes to Pubky App (port 3000)

**Required Environment Variable:**
```bash
CADDY_EMAIL=your-email@domain.com  # Required for Let's Encrypt
```

## Services and Ports

| Service | Internal Port | External Port | URL |
|---------|---------------|---------------|-----|
| Pubky App | 4200 | 80 (via Caddy) | http://localhost |
| Nexus | 8080 | 8080 | http://localhost:8080 |
| Homeserver | 6287 | 6287 | http://localhost:6287 |
| HTTP Relay | 15412 | 15412 | http://localhost:15412 |
| Caddy Admin | 2019 | 2019 | http://localhost:2019 |

## Directory Structure

```
pubky-stack/
├── setup.sh                 # Interactive setup script
├── docker-compose.yml       # Docker Compose configuration
├── .env.example             # Environment template
├── .env                     # Your environment configuration
├── configs/                 # Service configurations
│   ├── caddy/
│   │   └── Caddyfile
│   ├── homeserver/
│   │   ├── homeserver.config.toml
│   │   └── homeserver.entrypoint.sh
│   └── nexus/
│       └── config.toml
├── data/                    # Persistent data
│   ├── caddy/
│   ├── homeserver/
│   └── nexus/
├── logs/                    # Service logs
└── scripts/                 # Additional scripts
```

## Usage

### Interactive Menu

The setup script provides an interactive menu with the following options:

1. **Configure Environment** - Set up environment variables
2. **Setup & Build Services** - Build Docker images
3. **Start Stack** - Start all services
4. **Stop Stack** - Stop all services
5. **Restart Stack** - Restart all services
6. **Show Status** - Display service status
7. **Show Logs** - View service logs
8. **Cleanup** - Remove containers and volumes

### Command Line Usage

You can also use Docker Compose directly:

```bash
# Start the stack
docker-compose up -d

# Stop the stack
docker-compose down

# View logs
docker-compose logs -f

# Check status
docker-compose ps

# Rebuild services
docker-compose build --no-cache

# Clean up
docker-compose down -v --remove-orphans
```

## Health Checks

All services include health checks to ensure they're running properly:

- **Pubky App**: HTTP check on port 4200
- **Nexus**: HTTP check on `/health` endpoint
- **Homeserver**: HTTP check on `/health` endpoint
- **Caddy**: Admin API check
- **HTTP Relay**: TCP check on port 15412

## Logging

Logs are stored in the `logs/` directory and include:

- Service-specific logs
- Caddy access and error logs
- Docker Compose logs

## Troubleshooting

### Common Issues

1. **Port conflicts**: Ensure ports 80, 443, 6287, 8080, 15412, and 2019 are available
2. **Docker not running**: Make sure Docker daemon is started
3. **Permission issues**: Ensure the setup script is executable (`chmod +x setup.sh`)
4. **Build failures**: Check Docker logs and ensure all source directories exist

### Debugging

1. **Check service status:**
   ```bash
   docker-compose ps
   ```

2. **View service logs:**
   ```bash
   docker-compose logs [service-name]
   ```

3. **Access service containers:**
   ```bash
   docker-compose exec [service-name] /bin/sh
   ```

## Development

For development purposes:

1. **Use the development configuration** in `.env`
2. **Enable debug logging** in service configurations
3. **Use volume mounts** for live code reloading
4. **Access Caddy admin interface** at http://localhost:2019

## Security

- All services run in an isolated Docker network
- Caddy handles SSL termination and reverse proxy
- CORS is properly configured for API services
- Admin interfaces are restricted to local access

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with the setup script
5. Submit a pull request

## License

This project is licensed under the same license as the Pubky project.