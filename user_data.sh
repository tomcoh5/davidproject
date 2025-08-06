#!/bin/bash

# =============================================================================
# USER DATA SCRIPT FOR WEB TIER EC2 INSTANCES
# =============================================================================

set -e

# Variables passed from Terraform
APP_PORT="${app_port}"
DYNAMODB_TABLE="${dynamodb_table_name}"
SECRETS_MANAGER_NAME="${secrets_manager_name}"
LOG_GROUP_NAME="${log_group_name}"
AWS_REGION="${aws_region}"
CODEDEPLOY_APP_NAME="${codedeploy_app_name}"
DEPLOYMENT_GROUP="${deployment_group}"

# =============================================================================
# SYSTEM UPDATES AND BASIC SETUP
# =============================================================================

echo "Starting user data script execution..."

# Update system
dnf update -y

# Install basic utilities
dnf install -y \
    wget \
    curl \
    unzip \
    git \
    htop \
    tree \
    jq \
    awscli

# =============================================================================
# NODE.JS INSTALLATION
# =============================================================================

echo "Installing Node.js..."

# Install Node.js 18.x (LTS)
curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
dnf install -y nodejs

# Verify installation
node --version
npm --version

# Install PM2 globally for process management
npm install -g pm2

# =============================================================================
# CLOUDWATCH AGENT INSTALLATION
# =============================================================================

echo "Installing CloudWatch Agent..."

# Download and install CloudWatch agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm

# Create CloudWatch agent configuration
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << EOF
{
    "agent": {
        "metrics_collection_interval": 60,
        "run_as_user": "cwagent"
    },
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/var/log/webapp/app.log",
                        "log_group_name": "${LOG_GROUP_NAME}",
                        "log_stream_name": "{instance_id}/application",
                        "timezone": "UTC",
                        "timestamp_format": "%Y-%m-%d %H:%M:%S"
                    },
                    {
                        "file_path": "/var/log/codedeploy-agent/codedeploy-agent.log",
                        "log_group_name": "${LOG_GROUP_NAME}",
                        "log_stream_name": "{instance_id}/codedeploy-agent",
                        "timezone": "UTC"
                    },
                    {
                        "file_path": "/var/log/messages",
                        "log_group_name": "${LOG_GROUP_NAME}",
                        "log_stream_name": "{instance_id}/system",
                        "timezone": "UTC"
                    }
                ]
            }
        }
    },
    "metrics": {
        "namespace": "WebApp/EC2",
        "metrics_collected": {
            "cpu": {
                "measurement": [
                    "cpu_usage_idle",
                    "cpu_usage_iowait",
                    "cpu_usage_user",
                    "cpu_usage_system"
                ],
                "metrics_collection_interval": 60,
                "totalcpu": false
            },
            "disk": {
                "measurement": [
                    "used_percent"
                ],
                "metrics_collection_interval": 60,
                "resources": [
                    "*"
                ]
            },
            "diskio": {
                "measurement": [
                    "io_time"
                ],
                "metrics_collection_interval": 60,
                "resources": [
                    "*"
                ]
            },
            "mem": {
                "measurement": [
                    "mem_used_percent"
                ],
                "metrics_collection_interval": 60
            },
            "netstat": {
                "measurement": [
                    "tcp_established",
                    "tcp_time_wait"
                ],
                "metrics_collection_interval": 60
            },
            "swap": {
                "measurement": [
                    "swap_used_percent"
                ],
                "metrics_collection_interval": 60
            }
        }
    }
}
EOF

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
    -s



echo "Installing CodeDeploy Agent..."

dnf install -y ruby

cd /home/ec2-user
wget https://aws-codedeploy-${AWS_REGION}.s3.${AWS_REGION}.amazonaws.com/latest/install
chmod +x ./install
./install auto

systemctl start codedeploy-agent
systemctl enable codedeploy-agent

systemctl status codedeploy-agent



echo "Setting up application directories..."

mkdir -p /opt/webapp
mkdir -p /var/log/webapp

useradd -r -s /bin/false webapp || true
chown -R webapp:webapp /opt/webapp
chown -R webapp:webapp /var/log/webapp



echo "Setting up application environment..."

cat > /opt/webapp/.env << EOF
NODE_ENV=production
PORT=${APP_PORT}
AWS_REGION=${AWS_REGION}
DYNAMODB_TABLE=${DYNAMODB_TABLE}
SECRETS_MANAGER_NAME=${SECRETS_MANAGER_NAME}
LOG_GROUP_NAME=${LOG_GROUP_NAME}
EOF

chown webapp:webapp /opt/webapp/.env
chmod 600 /opt/webapp/.env


echo "Creating sample Node.js application..."

# Create a simple Express.js application
cat > /opt/webapp/package.json << 'EOF'
{
  "name": "webapp-ha",
  "version": "1.0.0",
  "description": "Highly Available Web Application",
  "main": "app.js",
  "scripts": {
    "start": "node app.js",
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "dependencies": {
    "express": "^4.18.2",
    "aws-sdk": "^2.1490.0",
    "winston": "^3.11.0"
  },
  "keywords": [],
  "author": "",
  "license": "ISC"
}
EOF

cat > /opt/webapp/app.js << 'EOF'
const express = require('express');
const AWS = require('aws-sdk');
const winston = require('winston');
const fs = require('fs');

const app = express();
const port = process.env.PORT || 3000;

// Configure AWS SDK
AWS.config.update({ region: process.env.AWS_REGION });

// Configure logging
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.File({ filename: '/var/log/webapp/app.log' }),
    new winston.transports.Console()
  ]
});

app.use(express.json());

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ 
    status: 'OK', 
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  });
});

// Root endpoint
app.get('/', (req, res) => {
  logger.info('Root endpoint accessed');
  res.json({ 
    message: 'Welcome to the Highly Available Web Application!',
    instance: process.env.HOSTNAME || 'unknown',
    timestamp: new Date().toISOString()
  });
});

// API endpoint with DynamoDB interaction
app.get('/api/sessions', async (req, res) => {
  try {
    const dynamodb = new AWS.DynamoDB.DocumentClient();
    
    const params = {
      TableName: process.env.DYNAMODB_TABLE,
      Limit: 10
    };
    
    const result = await dynamodb.scan(params).promise();
    
    logger.info(`Retrieved ${result.Items.length} sessions from DynamoDB`);
    res.json({ sessions: result.Items });
  } catch (error) {
    logger.error('Error retrieving sessions:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Start server
app.listen(port, () => {
  logger.info(`Server running on port ${port}`);
  console.log(`Server running on port ${port}`);
});
EOF

# Set ownership
chown -R webapp:webapp /opt/webapp

# Install dependencies
cd /opt/webapp
sudo -u webapp npm install

# =============================================================================
# SYSTEMD SERVICE SETUP
# =============================================================================

echo "Setting up systemd service..."

cat > /etc/systemd/system/webapp.service << EOF
[Unit]
Description=Node.js Web Application
After=network.target

[Service]
Type=simple
User=webapp
WorkingDirectory=/opt/webapp
Environment=NODE_ENV=production
EnvironmentFile=/opt/webapp/.env
ExecStart=/usr/bin/node app.js
Restart=always
RestartSec=10
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=webapp

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
systemctl daemon-reload
systemctl enable webapp
systemctl start webapp

# =============================================================================
# FINAL SETUP AND VERIFICATION
# =============================================================================

echo "Performing final setup..."

# Note: Application deployment files (appspec.yml and scripts) are now managed
# by CodeDeploy and stored in S3. This separation ensures clean deployments
# and avoids conflicts between infrastructure setup and application deployment.

# Verify services are running
systemctl status webapp
systemctl status codedeploy-agent
systemctl status amazon-cloudwatch-agent

echo "User data script execution completed successfully!"

# Test the application
curl -f http://localhost:${APP_PORT}/health || echo "Application health check failed"

echo "Instance setup complete. Application should be available on port ${APP_PORT}" 