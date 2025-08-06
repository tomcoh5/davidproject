#!/bin/bash

# =============================================================================
# CODEDEPLOY: STOP APPLICATION SCRIPT
# =============================================================================

echo "Starting application stop script..."

# Stop the webapp service if it's running
if systemctl is-active --quiet webapp; then
    echo "Stopping webapp service..."
    systemctl stop webapp
    echo "Webapp service stopped successfully!"
else
    echo "Webapp service is not running."
fi

# Kill any remaining Node.js processes (safety measure)
pkill -f "node app.js" || true

echo "Application stop script completed successfully!" 