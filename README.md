# AWS Highly Available Web Tier Infrastructure

This Terraform project creates a production-ready, highly available web tier on AWS with the following architecture:

```
Internet → CloudFront → ALB → Auto Scaling EC2 (private subnets)
                                  ↓
                              DynamoDB + Secrets Manager
                                  ↓
                            On-premises Database
```

## Architecture Overview

### Components

- **CloudFront CDN**: Global content delivery with caching and security headers
- **Application Load Balancer (ALB)**: Distributes traffic across multiple AZs
- **Auto Scaling Group**: EC2 instances in private subnets across 2+ AZs
- **DynamoDB**: Application state and session storage
- **Secrets Manager**: Secure credential storage with cross-account access
- **CloudWatch**: Monitoring, logging, and alerting
- **CodeDeploy**: Blue/green deployment for Node.js applications
- **VPC Endpoints**: Secure access to AWS services without NAT Gateway egress

### Security Features

- Private subnets for application instances
- No SSH access (SSM Session Manager for debugging)
- Encrypted storage (EBS, DynamoDB, Secrets Manager)
- Security groups with least privilege
- VPC Flow Logs for network monitoring
- Cross-account Secrets Manager access policies

## Quick Start

### Prerequisites

1. **AWS CLI configured** with appropriate permissions
2. **Terraform >= 1.0** installed
3. **Domain name** (optional) for custom SSL certificates

### Deployment

1. Clone this repository:
   ```bash
   git clone <repository-url>
   cd aws-ha-web-tier
   ```

2. Create a `terraform.tfvars` file:
   ```hcl
   # Required variables
   alert_phone_number = "+1234567890"
   
   # Optional variables
   project_name = "my-webapp"
   environment = "prod"
   domain_name = "example.com"
   cross_account_id = "123456789012"
   
   # On-premises connectivity
   on_prem_cidr_blocks = ["192.168.1.0/24", "10.10.0.0/16"]
   on_prem_db_ports = [5432, 1433, 27017]
   ```

3. Initialize and deploy:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

4. Access your application:
   - **ALB DNS**: Use the output `alb_dns_name`
   - **CloudFront**: Use the output `cloudfront_domain_name`

## Configuration Variables

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `alert_phone_number` | Phone number for SMS alerts | "+1234567890" |

### Optional Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `project_name` | Project name for resource naming | "webapp-ha" |
| `environment` | Environment (dev/staging/prod) | "prod" |
| `aws_region` | AWS deployment region | "us-east-1" |
| `vpc_cidr` | VPC CIDR block | "10.0.0.0/16" |
| `domain_name` | Custom domain for SSL certificates | "" |
| `cross_account_id` | AWS Account ID for Secrets Manager access | "" |
| `on_prem_cidr_blocks` | On-premises IP ranges | ["192.168.1.0/24"] |
| `instance_type` | EC2 instance type | "t3.medium" |
| `min_size` | Minimum instances in ASG | 2 |
| `max_size` | Maximum instances in ASG | 4 |

## Monitoring and Alerting

### CloudWatch Alarms

The infrastructure includes comprehensive monitoring with automatic SMS alerts for:

- **ALB Metrics**: Response time, 5xx errors, unhealthy targets
- **EC2 Metrics**: CPU utilization (auto scaling triggers)
- **DynamoDB Metrics**: Throttled requests, system errors
- **CloudFront Metrics**: Origin latency, error rates

### CloudWatch Dashboard

Access the dashboard at: AWS Console → CloudWatch → Dashboards → `{project-name}-{environment}-dashboard`

### Log Groups

- `/aws/ec2/{project-name}-{environment}` - Application logs
- `/aws/elasticloadbalancing/{project-name}-{environment}` - ALB access logs
- `/aws/vpc/{project-name}-{environment}/flowlogs` - VPC Flow Logs

## Application Deployment

### CodeDeploy Configuration

The infrastructure includes CodeDeploy setup for Node.js applications:

1. **Application**: `{project-name}-{environment}-nodejs-webapp`
2. **Deployment Group**: `{project-name}-{environment}-production`
3. **Strategy**: Blue/Green with automatic rollback on health check failures

### Sample Application

A sample Node.js Express application is automatically deployed with:

- Health check endpoint: `/health`
- Session API: `/api/sessions` (integrates with DynamoDB)
- Structured logging to CloudWatch

### Deploying Your Application

1. **Prepare your application** with the required structure:
   ```
   your-app/
   ├── appspec.yml
   ├── app.js (or your main file)
   ├── package.json
   └── scripts/
       ├── install_dependencies.sh
       ├── start_application.sh
       ├── stop_application.sh
       └── validate_service.sh
   ```

2. **Create deployment package**:
   ```bash
   zip -r deployment.zip .
   ```

3. **Upload to S3** (use the CodeDeploy artifacts bucket from outputs):
   ```bash
   aws s3 cp deployment.zip s3://{codedeploy-bucket}/my-app/deployment.zip
   ```

4. **Create deployment**:
   ```bash
   aws deploy create-deployment \
     --application-name {codedeploy-app-name} \
     --deployment-group-name {deployment-group-name} \
     --s3-location bucket={codedeploy-bucket},key=my-app/deployment.zip,bundleType=zip
   ```

## Security Best Practices

### Implemented Security Measures

- ✅ **Network Isolation**: Private subnets for application tier
- ✅ **Encryption**: All data encrypted at rest and in transit
- ✅ **Access Control**: IAM roles with least privilege
- ✅ **Monitoring**: VPC Flow Logs and CloudWatch monitoring
- ✅ **Secret Management**: AWS Secrets Manager with cross-account policies
- ✅ **Auto Scaling**: Health-based instance replacement

### Additional Recommendations

- **WAF**: Consider adding AWS WAF to CloudFront for additional protection
- **GuardDuty**: Enable for threat detection
- **Config**: Enable for compliance monitoring
- **Certificate Management**: Use ACM for SSL certificate lifecycle management

## Cost Optimization

### Included Cost Optimizations

- **VPC Endpoints**: Reduce NAT Gateway data transfer costs
- **GP3 EBS**: Cost-effective storage with better performance
- **CloudFront**: Reduce origin load and improve performance
- **DynamoDB On-Demand**: Automatic scaling, pay only for what you use
- **Log Retention**: Configured retention periods for cost management

### Additional Optimizations

- **Reserved Instances**: Consider for predictable workloads
- **Spot Instances**: For fault-tolerant applications
- **S3 Lifecycle Policies**: Automatic transition to cheaper storage classes

## Troubleshooting

### Common Issues

1. **SSL Certificate Validation**:
   - Ensure domain ownership verification for ACM certificates
   - CloudFront certificates must be in us-east-1

2. **Health Check Failures**:
   - Verify application responds on `/health` endpoint
   - Check security group rules for ALB → EC2 connectivity

3. **CodeDeploy Failures**:
   - Check CloudWatch Logs for deployment script errors
   - Verify IAM permissions for CodeDeploy service role

### Debugging Commands

```bash
# Check instance health
aws elbv2 describe-target-health --target-group-arn {target-group-arn}

# View deployment status
aws deploy get-deployment --deployment-id {deployment-id}

# Check CloudWatch logs
aws logs tail /aws/ec2/{project-name}-{environment} --follow

# SSM Session Manager access
aws ssm start-session --target {instance-id}
```

## Outputs Reference

After deployment, Terraform provides these key outputs:

| Output | Description |
|--------|-------------|
| `alb_dns_name` | Application Load Balancer DNS name |
| `cloudfront_domain_name` | CloudFront distribution domain |
| `dynamodb_table_name` | DynamoDB table for sessions |
| `secrets_manager_secret_name` | Secrets Manager secret name |
| `codedeploy_application_name` | CodeDeploy application name |
| `sns_topic_arn` | SNS topic for alerts |

## Contributing

1. Follow Terraform best practices
2. Update documentation for any changes
3. Test in a separate environment first
4. Use semantic versioning for releases

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues and questions:

1. Check the troubleshooting section
2. Review CloudWatch logs and metrics
3. Create an issue in the repository

---

**Note**: This infrastructure is designed for production use. Always review and customize security settings, monitoring thresholds, and cost optimizations based on your specific requirements. 