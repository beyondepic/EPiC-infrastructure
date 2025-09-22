#!/bin/bash
# User data script for web application instances

# Update system
yum update -y

# Install CloudWatch agent
yum install -y amazon-cloudwatch-agent

# Install SSM agent (usually pre-installed on Amazon Linux 2)
yum install -y amazon-ssm-agent
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent

# Install Docker
yum install -y docker
systemctl enable docker
systemctl start docker
usermod -a -G docker ec2-user

# Install Node.js (for React/Node.js applications)
curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
yum install -y nodejs

# Install nginx
yum install -y nginx
systemctl enable nginx

# Create application directory
mkdir -p /opt/${application_name}
chown ec2-user:ec2-user /opt/${application_name}

# Create basic nginx configuration
cat > /etc/nginx/conf.d/${application_name}.conf << 'EOF'
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
EOF

# Start nginx
systemctl start nginx

# Create CloudWatch agent configuration
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOF'
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
                        "file_path": "/var/log/nginx/access.log",
                        "log_group_name": "/aws/ec2/${application_name}/nginx/access",
                        "log_stream_name": "{instance_id}",
                        "timezone": "UTC"
                    },
                    {
                        "file_path": "/var/log/nginx/error.log",
                        "log_group_name": "/aws/ec2/${application_name}/nginx/error",
                        "log_stream_name": "{instance_id}",
                        "timezone": "UTC"
                    }
                ]
            }
        }
    },
    "metrics": {
        "namespace": "CWAgent",
        "metrics_collected": {
            "cpu": {
                "measurement": [
                    "cpu_usage_idle",
                    "cpu_usage_iowait",
                    "cpu_usage_user",
                    "cpu_usage_system"
                ],
                "metrics_collection_interval": 60,
                "resources": [
                    "*"
                ],
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

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config -m ec2 -s \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

# Create systemd service for application (placeholder)
cat > /etc/systemd/system/${application_name}.service << 'EOF'
[Unit]
Description=${application_name} Application
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/opt/${application_name}
ExecStart=/usr/bin/node server.js
Restart=always
RestartSec=10
Environment=NODE_ENV=${environment}
Environment=PORT=3000

[Install]
WantedBy=multi-user.target
EOF

# Enable the service (will start when application is deployed)
systemctl enable ${application_name}

# Create deployment script
cat > /opt/${application_name}/deploy.sh << 'EOF'
#!/bin/bash
# Deployment script for application updates

APP_DIR="/opt/${application_name}"
BACKUP_DIR="/opt/${application_name}/backups"

# Create backup directory if it doesn't exist
mkdir -p $BACKUP_DIR

# Stop the application
systemctl stop ${application_name}

# Create backup of current version
if [ -f "$APP_DIR/package.json" ]; then
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    tar -czf "$BACKUP_DIR/backup_$TIMESTAMP.tar.gz" -C "$APP_DIR" --exclude=backups --exclude=node_modules .

    # Keep only last 5 backups
    cd $BACKUP_DIR
    ls -t backup_*.tar.gz | tail -n +6 | xargs -r rm
fi

# Application deployment logic would go here
# This would typically be handled by a CI/CD pipeline

# Start the application
systemctl start ${application_name}

# Check if service started successfully
sleep 5
if systemctl is-active --quiet ${application_name}; then
    echo "Application started successfully"
    exit 0
else
    echo "Application failed to start"
    exit 1
fi
EOF

chmod +x /opt/${application_name}/deploy.sh

# Signal that user data script is complete
/opt/aws/bin/cfn-signal -e $? --stack ${AWS::StackName} --resource AutoScalingGroup --region ${AWS::Region}

echo "User data script completed successfully"