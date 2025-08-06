# =============================================================================
# VARIABLES FOR AWS HIGHLY AVAILABLE WEB TIER
# =============================================================================

variable "project_name" {
  description = "The name of the project"
  type        = string
  default     = "app"
}

variable "environment" {
  description = "The environment (e.g., 'dev', 'staging', 'prod')"
  type        = string
  default     = "staging"
}

variable "aws_region" {
  description = "The AWS region to deploy to"
  type        = string
  default     = "us-east-1"
}

# =============================================================================
# NETWORKING CONFIGURATION
# =============================================================================

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.20.0/24"]
}

variable "on_prem_cidr_blocks" {
  description = "CIDR blocks for on-premises database connectivity"
  type        = list(string)
  default     = ["192.168.1.0/24", "172.16.0.0/24"]
}

variable "on_prem_db_ports" {
  description = "Database ports for on-premises connectivity"
  type        = list(number)
  default     = [5432, 1433, 27017] # PostgreSQL, SQL Server, MongoDB
}

# =============================================================================
# APPLICATION CONFIGURATION
# =============================================================================

variable "app_port" {
  description = "The port the application will run on"
  type        = number
  default     = 3000
}

variable "health_check_path" {
  description = "Health check endpoint path"
  type        = string
  default     = "/health"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "min_size" {
  description = "Minimum number of instances in Auto Scaling Group"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum number of instances in Auto Scaling Group"
  type        = number
  default     = 4
}

variable "desired_capacity" {
  description = "Desired number of instances in Auto Scaling Group"
  type        = number
  default     = 2
}

# =============================================================================
# SECURITY CONFIGURATION
# =============================================================================

variable "cross_account_id" {
  description = "AWS Account ID that needs read access to Secrets Manager"
  type        = string
  default     = ""
}

# =============================================================================
# MONITORING & ALERTING
# =============================================================================

variable "alert_phone_number" {
  description = "Phone number for SMS alerts (format: +1234567890)"
  type        = string
  default     = ""
}

# =============================================================================
# DYNAMODB CONFIGURATION
# =============================================================================

variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table for application sessions"
  type        = string
  default     = "app-sessions"
}



# =============================================================================
# CODEDEPLOY CONFIGURATION
# =============================================================================

variable "codedeploy_app_name" {
  description = "The name of the CodeDeploy application"
  type        = string
  default     = "my-app"
}

variable "codedeploy_deployment_group" {
  description = "The name of the CodeDeploy deployment group"
  type        = string
  default     = "my-app-dg"
}

# =============================================================================
# COMMON TAGS
# =============================================================================

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "webapp-ha"
    Environment = "prod"
    ManagedBy   = "terraform"
  }
} 