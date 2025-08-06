#!/bin/bash

# =============================================================================
# CODEDEPLOY: START APPLICATION SCRIPT
# =============================================================================

set -e

echo "Starting application start script..."

# Reload systemd to pick up any changes
systemctl daemon-reload

# Start the webapp service
echo "Starting webapp service..."
systemctl start webapp

# Enable the service to start on boot
systemctl enable webapp

# Wait a moment for the service to start
sleep 5

# Check if the service is running
if systemctl is-active --quiet webapp; then
    echo "Webapp service started successfully!"
else
    echo "Failed to start webapp service!"
    systemctl status webapp
    exit 1
fi

echo "Application start script completed successfully!" 