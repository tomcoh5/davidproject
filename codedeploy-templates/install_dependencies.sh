#!/bin/bash

# =============================================================================
# CODEDEPLOY: INSTALL DEPENDENCIES SCRIPT
# =============================================================================

set -e

echo "Starting install dependencies script..."

# Navigate to application directory
cd /opt/webapp

# Install Node.js dependencies
echo "Installing Node.js dependencies..."
sudo -u webapp npm install --production

# Set ownership
chown -R webapp:webapp /opt/webapp

echo "Dependencies installation completed successfully!" 