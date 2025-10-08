#!/bin/bash

# Test script for automated configuration
cd /home/vincent/Dev/Trae/pubky-homeserver/pubky-stack

# Clean up any existing configuration
rm -f .env

# Create input for the setup script
# Inputs: 1 (Configure Environment), test-domain.com (root domain), 
# default PKARR relays (enter), n (no testnet), n (no Plausible), n (no Nexus build),
# default git branch (enter), default git ref (enter), 6 (Exit)
cat << 'EOF' | bash setup.sh
1
test-domain.com

n
n
n


6
EOF

echo "Configuration test completed."

# Check if .env file was created
if [ -f .env ]; then
    echo "✓ .env file was created successfully"
    echo "Generated configuration:"
    cat .env
else
    echo "✗ .env file was not created"
fi