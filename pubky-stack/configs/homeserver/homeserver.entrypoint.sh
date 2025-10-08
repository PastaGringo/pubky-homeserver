#!/bin/sh

# Pubky Homeserver Entrypoint Script
# This script initializes and starts the homeserver

set -e

echo "Starting Pubky Homeserver..."

# Create necessary directories
mkdir -p /root/.pubky/data
mkdir -p /var/log/homeserver

# Set proper permissions
chmod 755 /root/.pubky/data
chmod 755 /var/log/homeserver

# Print configuration info
echo "Homeserver Configuration:"
echo "  - Host: 0.0.0.0:6287"
echo "  - Data Directory: /root/.pubky/data"
echo "  - Log Directory: /var/log/homeserver"
echo "  - Config File: /root/.pubky/config.toml"

# Print environment variables
echo "Environment Variables:"
echo "  - NEXT_PUBLIC_HOMESERVER: ${NEXT_PUBLIC_HOMESERVER:-not set}"
echo "  - NEXT_PUBLIC_NEXUS: ${NEXT_PUBLIC_NEXUS:-not set}"
echo "  - NEXT_PUBLIC_DEFAULT_HTTP_RELAY: ${NEXT_PUBLIC_DEFAULT_HTTP_RELAY:-not set}"

# Wait for dependencies (optional)
if [ -n "$WAIT_FOR_NEXUS" ]; then
    echo "Waiting for Nexus to be ready..."
    until nc -z nexusd 8080; do
        echo "Nexus not ready, waiting..."
        sleep 2
    done
    echo "Nexus is ready!"
fi

# Start the homeserver
echo "Starting homeserver process..."
exec homeserver --config /root/.pubky/config.toml