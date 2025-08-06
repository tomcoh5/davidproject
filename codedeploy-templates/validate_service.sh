#!/bin/bash

# =============================================================================
# CODEDEPLOY: VALIDATE SERVICE SCRIPT
# =============================================================================

set -e

echo "Starting service validation script..."

# Get the application port from environment or use default
APP_PORT=${PORT:-3000}

# Wait for the service to be fully ready
echo "Waiting for application to be ready..."
sleep 10

# Check if the webapp service is running
if ! systemctl is-active --quiet webapp; then
    echo "ERROR: Webapp service is not running!"
    systemctl status webapp
    exit 1
fi

# Check if the application is responding to HTTP requests
echo "Testing application health endpoint..."
for i in {1..30}; do
    if curl -f http://localhost:${APP_PORT}/health > /dev/null 2>&1; then
        echo "Application health check passed!"
        break
    fi
    
    if [ $i -eq 30 ]; then
        echo "ERROR: Application health check failed after 30 attempts!"
        echo "Service status:"
        systemctl status webapp
        echo "Application logs:"
        journalctl -u webapp --no-pager -n 20
        exit 1
    fi
    
    echo "Attempt $i: Health check failed, retrying in 2 seconds..."
    sleep 2
done

# Additional validation: Check if the application is listening on the correct port
if ! netstat -tuln | grep ":${APP_PORT}" > /dev/null; then
    echo "ERROR: Application is not listening on port ${APP_PORT}!"
    netstat -tuln
    exit 1
fi

echo "Service validation completed successfully!"
echo "Application is running on port ${APP_PORT} and responding to health checks." 