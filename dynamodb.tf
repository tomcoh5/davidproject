resource "aws_dynamodb_table" "app_sessions" {
  name         = "${var.project_name}-${var.environment}-${var.dynamodb_table_name}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "session_id"
  range_key    = "user_id"

  attribute {
    name = "session_id"
    type = "S"
  }

  attribute {
    name = "user_id"
    type = "S"
  }

  attribute {
    name = "created_at"
    type = "S"
  }

  global_secondary_index {
    name            = "UserIdIndex"
    hash_key        = "user_id"
    range_key       = "created_at"
    projection_type = "ALL"
  }

  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }

  # Enable server-side encryption
  server_side_encryption {
    enabled = true
  }

  # Enable point-in-time recovery
  point_in_time_recovery {
    enabled = true
  }

  deletion_protection_enabled = false

  tags = {
    Name = "${var.project_name}-${var.environment}-${var.dynamodb_table_name}"
  }
} 