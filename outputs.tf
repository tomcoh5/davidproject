# =============================================================================
# OUTPUTS FOR AWS HIGHLY AVAILABLE WEB TIER
# =============================================================================

# =============================================================================
# NETWORKING OUTPUTS
# =============================================================================

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "nat_gateway_ids" {
  description = "IDs of the NAT Gateways"
  value       = aws_nat_gateway.main[*].id
}

# =============================================================================
# LOAD BALANCER OUTPUTS
# =============================================================================

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = aws_lb.main.zone_id
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.main.arn
}

output "target_group_arn" {
  description = "ARN of the Target Group"
  value       = aws_lb_target_group.main.arn
}

# =============================================================================
# CLOUDFRONT OUTPUTS
# =============================================================================

output "cloudfront_distribution_id" {
  description = "ID of the CloudFront Distribution"
  value       = aws_cloudfront_distribution.main.id
}

output "cloudfront_domain_name" {
  description = "Domain name of the CloudFront Distribution"
  value       = aws_cloudfront_distribution.main.domain_name
}

output "cloudfront_hosted_zone_id" {
  description = "CloudFront Distribution hosted zone ID"
  value       = aws_cloudfront_distribution.main.hosted_zone_id
}

# =============================================================================
# AUTO SCALING OUTPUTS
# =============================================================================

output "autoscaling_group_arn" {
  description = "ARN of the Auto Scaling Group"
  value       = aws_autoscaling_group.main.arn
}

output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.main.name
}

output "launch_template_id" {
  description = "ID of the Launch Template"
  value       = aws_launch_template.main.id
}

output "launch_template_latest_version" {
  description = "Latest version of the Launch Template"
  value       = aws_launch_template.main.latest_version
}

# =============================================================================
# SECURITY GROUP OUTPUTS
# =============================================================================

output "alb_security_group_id" {
  description = "ID of the ALB Security Group"
  value       = aws_security_group.alb.id
}

output "app_security_group_id" {
  description = "ID of the Application Security Group"
  value       = aws_security_group.app.id
}

# =============================================================================
# DYNAMODB OUTPUTS
# =============================================================================

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table"
  value       = aws_dynamodb_table.app_sessions.name
}

output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table"
  value       = aws_dynamodb_table.app_sessions.arn
}

# =============================================================================
# SECRETS MANAGER OUTPUTS
# =============================================================================

output "secrets_manager_secret_arn" {
  description = "ARN of the Secrets Manager secret"
  value       = aws_secretsmanager_secret.app_secrets.arn
}

output "secrets_manager_secret_name" {
  description = "Name of the Secrets Manager secret"
  value       = aws_secretsmanager_secret.app_secrets.name
}

# =============================================================================
# CODEDEPLOY OUTPUTS
# =============================================================================

output "codedeploy_application_name" {
  description = "Name of the CodeDeploy application"
  value       = aws_codedeploy_app.main.name
}

output "codedeploy_deployment_group_name" {
  description = "Name of the CodeDeploy deployment group"
  value       = aws_codedeploy_deployment_group.main.deployment_group_name
}

output "codedeploy_s3_bucket" {
  description = "The name of the S3 bucket for CodeDeploy artifacts"
  value       = aws_s3_bucket.codedeploy_artifacts.id
}

# =============================================================================
# IAM OUTPUTS
# =============================================================================

output "ec2_instance_profile_name" {
  description = "Name of the EC2 instance profile"
  value       = aws_iam_instance_profile.ec2.name
}

output "codedeploy_service_role_arn" {
  description = "ARN of the CodeDeploy service role"
  value       = aws_iam_role.codedeploy.arn
}

# =============================================================================
# MONITORING OUTPUTS
# =============================================================================

output "sns_topic_arn" {
  description = "ARN of the SNS topic for alerts"
  value       = aws_sns_topic.alerts.arn
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.app.name
}

# =============================================================================
# SSL/TLS OUTPUTS
# =============================================================================

# =============================================================================
# VPC ENDPOINTS OUTPUTS
# =============================================================================

output "vpc_endpoint_s3_id" {
  description = "ID of the S3 VPC endpoint"
  value       = aws_vpc_endpoint.s3.id
}

output "vpc_endpoint_ssm_id" {
  description = "ID of the SSM VPC endpoint"
  value       = aws_vpc_endpoint.ssm.id
}

# =============================================================================
# DEPLOYMENT INFORMATION
# =============================================================================

output "deployment_summary" {
  description = "Summary of deployed resources"
  value = {
    region                    = var.aws_region
    vpc_cidr                 = var.vpc_cidr
    availability_zones       = var.availability_zones
    alb_dns_name            = aws_lb.main.dns_name
    cloudfront_domain_name  = aws_cloudfront_distribution.main.domain_name
    dynamodb_table          = aws_dynamodb_table.app_sessions.name
    codedeploy_application  = aws_codedeploy_app.main.name
    auto_scaling_group      = aws_autoscaling_group.main.name
  }
} 