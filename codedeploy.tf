resource "aws_codedeploy_app" "main" {
  compute_platform = "Server"
  name             = "${var.project_name}-${var.environment}-${var.codedeploy_app_name}"

  tags = {
    Name = "${var.project_name}-${var.environment}-${var.codedeploy_app_name}"
  }
}


resource "aws_codedeploy_deployment_group" "main" {
  app_name              = aws_codedeploy_app.main.name
  deployment_group_name = "${var.project_name}-${var.environment}-${var.codedeploy_deployment_group}"
  service_role_arn      = aws_iam_role.codedeploy.arn

  deployment_config_name = "CodeDeployDefault.EC2AllInstancesBlueGreenFleet"

  blue_green_deployment_config {
    terminate_blue_instances_on_deployment_success {
      action                         = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }

    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }

    green_fleet_provisioning_option {
      action = "COPY_AUTO_SCALING_GROUP"
    }
  }

  auto_scaling_groups = [aws_autoscaling_group.main.name]

  load_balancer_info {
    target_group_info {
      name = aws_lb_target_group.main.name
    }
  }

  ec2_tag_filter {
    key   = "Name"
    type  = "KEY_AND_VALUE"
    value = "${var.project_name}-${var.environment}-asg-instance"
  }

  ec2_tag_filter {
    key   = "Environment"
    type  = "KEY_AND_VALUE"
    value = var.environment
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  alarm_configuration {
    enabled = true
    alarms = [
      aws_cloudwatch_metric_alarm.alb_unhealthy_hosts.alarm_name,
      aws_cloudwatch_metric_alarm.alb_http_5xx.alarm_name
    ]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-${var.codedeploy_deployment_group}"
  }

  depends_on = [aws_iam_role_policy_attachment.codedeploy]
}

resource "aws_codedeploy_deployment_config" "custom" {
  deployment_config_name = "${var.project_name}-${var.environment}-fast-deployment"
  compute_platform       = "Server"

  minimum_healthy_hosts {
    type  = "HOST_COUNT"
    value = 1
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-fast-deployment"
  }
}

resource "aws_s3_bucket" "codedeploy_artifacts" {
  bucket = "${var.project_name}-${var.environment}-codedeploy-artifacts-${random_id.codedeploy_suffix.hex}"

  tags = {
    Name = "${var.project_name}-${var.environment}-codedeploy-artifacts"
  }
}

# Generate random suffix for S3 bucket name
resource "random_id" "codedeploy_suffix" {
  byte_length = 4
}

# S3 bucket versioning
resource "aws_s3_bucket_versioning" "codedeploy_artifacts" {
  bucket = aws_s3_bucket.codedeploy_artifacts.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 bucket server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "codedeploy_artifacts" {
  bucket = aws_s3_bucket.codedeploy_artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 bucket public access block
resource "aws_s3_bucket_public_access_block" "codedeploy_artifacts" {
  bucket = aws_s3_bucket.codedeploy_artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 bucket lifecycle configuration
resource "aws_s3_bucket_lifecycle_configuration" "codedeploy_artifacts" {
  bucket = aws_s3_bucket.codedeploy_artifacts.id

  rule {
    id     = "codedeploy_artifacts_lifecycle"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    expiration {
      days = 90
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

# =============================================================================
# SAMPLE DEPLOYMENT SCRIPTS
# =============================================================================

# Upload sample deployment scripts to S3
resource "aws_s3_object" "appspec" {
  bucket = aws_s3_bucket.codedeploy_artifacts.bucket
  key    = "sample-deployment/appspec.yml"
  content = templatefile("${path.module}/codedeploy-templates/appspec.yml.tpl", {
    app_port = var.app_port
  })
  content_type = "text/yaml"

  tags = {
    Name = "sample-appspec"
  }
}

resource "aws_s3_object" "install_dependencies_script" {
  bucket = aws_s3_bucket.codedeploy_artifacts.bucket
  key    = "sample-deployment/scripts/install_dependencies.sh"
  source = "${path.module}/codedeploy-templates/install_dependencies.sh"
  etag   = filemd5("${path.module}/codedeploy-templates/install_dependencies.sh")

  tags = {
    Name = "install-dependencies-script"
  }
}

resource "aws_s3_object" "start_application_script" {
  bucket = aws_s3_bucket.codedeploy_artifacts.bucket
  key    = "sample-deployment/scripts/start_application.sh"
  source = "${path.module}/codedeploy-templates/start_application.sh"
  etag   = filemd5("${path.module}/codedeploy-templates/start_application.sh")

  tags = {
    Name = "start-application-script"
  }
}

resource "aws_s3_object" "stop_application_script" {
  bucket = aws_s3_bucket.codedeploy_artifacts.bucket
  key    = "sample-deployment/scripts/stop_application.sh"
  source = "${path.module}/codedeploy-templates/stop_application.sh"
  etag   = filemd5("${path.module}/codedeploy-templates/stop_application.sh")

  tags = {
    Name = "stop-application-script"
  }
} 