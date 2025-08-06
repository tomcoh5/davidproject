resource "aws_codedeploy_app" "main" {
  compute_platform = "Server"
  name             = "${var.project_name}-${var.environment}-${var.codedeploy_app_name}"

  tags = {
    Name = "${var.project_name}-${var.environment}-${var.codedeploy_app_name}"
  }
}


resource "aws_codedeploy_deployment_group" "main" {
  app_name               = aws_codedeploy_app.main.name
  deployment_group_name  = "${var.project_name}-${var.environment}-dg"
  service_role_arn       = aws_iam_role.codedeploy.arn
  deployment_config_name = aws_codedeploy_deployment_config.custom.id

  ec2_tag_set {
    ec2_tag_filter {
      key   = "Name"
      type  = "KEY_AND_VALUE"
      value = "${var.project_name}-${var.environment}-app"
    }
  }

  trigger_configuration {
    trigger_name       = "deployment-failure"
    trigger_target_arn = aws_sns_topic.alerts.arn
    trigger_events     = ["DeploymentFailure"]
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

  autoscaling_groups = [aws_autoscaling_group.main.name]
}

# CodeDeploy Custom Deployment Configuration
resource "aws_codedeploy_deployment_config" "custom" {
  deployment_config_name = "${var.project_name}-${var.environment}-custom-deployment"
  compute_platform       = "Server"

  minimum_healthy_hosts {
    type  = "FLEET_PERCENT"
    value = 50
  }
}

# S3 bucket for CodeDeploy artifacts
resource "aws_s3_bucket" "codedeploy_artifacts" {
  bucket = "${var.project_name}-${var.environment}-codedeploy-artifacts-${random_id.codedeploy_suffix.hex}"

  tags = {
    Name = "${var.project_name}-${var.environment}-codedeploy-artifacts"
  }
}

resource "random_id" "codedeploy_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket_versioning" "codedeploy_artifacts" {
  bucket = aws_s3_bucket.codedeploy_artifacts.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "codedeploy_artifacts" {
  bucket = aws_s3_bucket.codedeploy_artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

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

    filter {
      prefix = "/"
    }

    expiration {
      days = 7
    }

    noncurrent_version_expiration {
      noncurrent_days = 7
    }
  }
}



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