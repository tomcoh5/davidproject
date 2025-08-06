resource "aws_secretsmanager_secret" "app_secrets" {
  name                    = "${var.project_name}-${var.environment}-app-secrets"
  description             = "Application secrets for ${var.project_name}-${var.environment}"
  recovery_window_in_days = 30

  kms_key_id = aws_kms_key.secrets.arn

  tags = {
    Name = "${var.project_name}-${var.environment}-app-secrets"
  }
}



resource "aws_secretsmanager_secret_version" "app_secrets" {
  secret_id = aws_secretsmanager_secret.app_secrets.id
  
  secret_string = jsonencode({
    database_url          = "postgresql://username:password@on-prem-db.example.com:5432/dbname"
    database_username     = "app_user"
    database_password     = "change_me_in_production"
    api_key              = "your-api-key-here"
    jwt_secret           = "your-jwt-secret-here"
    redis_url            = "redis://redis.example.com:6379"
    third_party_api_key  = "third-party-api-key"
    encryption_key       = "your-encryption-key-here"
    oauth_client_id      = "oauth-client-id"
    oauth_client_secret  = "oauth-client-secret"
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}

resource "aws_kms_key" "secrets" {
  description             = "KMS key for Secrets Manager encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow use of the key by EC2 instances"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.ec2.arn
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      },
      {
        Sid    = "Allow Secrets Manager to use the key"
        Effect = "Allow"
        Principal = {
          Service = "secretsmanager.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-secrets-kms-key"
  }
}

resource "aws_kms_alias" "secrets" {
  name          = "alias/${var.project_name}-${var.environment}-secrets"
  target_key_id = aws_kms_key.secrets.key_id
}


# Resource policy for cross-account access to Secrets Manager
resource "aws_secretsmanager_secret_policy" "app_secrets" {
  count     = var.cross_account_id != "" ? 1 : 0
  secret_arn = aws_secretsmanager_secret.app_secrets.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCrossAccountRead"
        Effect = "Allow"
        Principal = {
          AWS = [
            "arn:aws:iam::${var.cross_account_id}:root"
          ]
        }
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = aws_secretsmanager_secret.app_secrets.arn
        Condition = {
          StringEquals = {
            "secretsmanager:ResourceTag/Environment" = var.environment
          }
        }
      },
      {
        Sid    = "AllowCurrentAccountFullAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "secretsmanager:*"
        Resource = aws_secretsmanager_secret.app_secrets.arn
      }
    ]
  })
}
