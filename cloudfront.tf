resource "aws_cloudfront_cache_policy" "dynamic" {
  name        = "${var.project_name}-${var.environment}-dynamic-cache"
  comment     = "Cache policy for dynamic content"
  default_ttl = 0
  max_ttl     = 31536000
  min_ttl     = 0

  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_brotli = true
    enable_accept_encoding_gzip   = true

    cookies_config {
      cookie_behavior = "none"
    }

    headers_config {
      header_behavior = "whitelist"
      headers {
        items = ["Host", "CloudFront-Forwarded-Proto", "CloudFront-Is-Desktop-Viewer", "CloudFront-Is-Mobile-Viewer"]
      }
    }

    query_strings_config {
      query_string_behavior = "all"
    }
  }
}

resource "aws_cloudfront_origin_request_policy" "main" {
  name    = "${var.project_name}-${var.environment}-origin-request"
  comment = "Origin request policy for ${var.project_name}"

  cookies_config {
    cookie_behavior = "all"
  }

  headers_config {
    header_behavior = "whitelist"
    headers {
      items = [
        "Accept",
        "Accept-Language",
        "CloudFront-Forwarded-Proto",
        "Host",
        "User-Agent",
        "X-Forwarded-For"
      ]
    }
  }

  query_strings_config {
    query_string_behavior = "all"
  }
}

resource "aws_cloudfront_response_headers_policy" "main" {
  name    = "${var.project_name}-${var.environment}-response-headers"
  comment = "Response headers policy for ${var.project_name}"

  cors_config {
    access_control_allow_credentials = false

    access_control_allow_headers {
      items = ["*"]
    }

    access_control_allow_methods {
      items = ["GET", "HEAD", "OPTIONS", "PUT", "PATCH", "POST", "DELETE"]
    }

    access_control_allow_origins {
      items = ["*"]
    }

    origin_override = false
  }

  security_headers_config {
    content_type_options {
      override = true
    }

    frame_options {
      frame_option = "DENY"
      override     = true
    }

    referrer_policy {
      referrer_policy = "strict-origin-when-cross-origin"
      override        = true
    }

    strict_transport_security {
      access_control_max_age_sec = 31536000
      include_subdomains         = true
      override                   = true
    }
  }
}

resource "aws_cloudfront_distribution" "main" {
  origin {
    domain_name              = aws_lb.main.dns_name
    origin_id                = "ALB-${aws_lb.main.name}"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CloudFront distribution for ${var.project_name}-${var.environment}"
  # No default_root_object for CRUD API - Node.js handles all routing

  # Default cache behavior for API endpoints
  default_cache_behavior {
    allowed_methods                = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods                 = ["GET", "HEAD"]
    target_origin_id               = "ALB-${aws_lb.main.name}"
    compress                       = true
    viewer_protocol_policy         = "redirect-to-https"
    cache_policy_id                = aws_cloudfront_cache_policy.dynamic.id
    origin_request_policy_id       = aws_cloudfront_origin_request_policy.main.id
    response_headers_policy_id     = aws_cloudfront_response_headers_policy.main.id
    smooth_streaming               = false
    trusted_signers                = []
    trusted_key_groups             = []
    realtime_log_config_arn        = null
  }

  # Price class
  price_class = "PriceClass_100"

  # Geo restrictions (none by default)
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # SSL Certificate configuration - using CloudFront default certificate only
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  # No custom error responses - let Node.js CRUD app handle all errors via JSON

  # Logging configuration
  logging_config {
    include_cookies = false
    bucket          = aws_s3_bucket.cloudfront_logs.bucket_domain_name
    prefix          = "cloudfront-logs/"
  }

  # WAF (optional)
  # web_acl_id = aws_wafv2_web_acl.main.arn

  tags = {
    Name = "${var.project_name}-${var.environment}-cloudfront"
  }

  depends_on = [aws_lb.main]
}


resource "aws_s3_bucket" "cloudfront_logs" {
  bucket = "${var.project_name}-${var.environment}-cloudfront-logs-${random_id.s3_suffix.hex}"

  tags = {
    Name = "${var.project_name}-${var.environment}-cloudfront-logs"
  }
}

resource "aws_s3_bucket_acl" "cloudfront_logs" {
  bucket = aws_s3_bucket.cloudfront_logs.id
  acl    = "private"

  depends_on = [aws_s3_bucket_ownership_controls.cloudfront_logs]
}

resource "aws_s3_bucket_ownership_controls" "cloudfront_logs" {
  bucket = aws_s3_bucket.cloudfront_logs.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "random_id" "s3_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket_versioning" "cloudfront_logs" {
  bucket = aws_s3_bucket.cloudfront_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudfront_logs" {
  bucket = aws_s3_bucket.cloudfront_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "cloudfront_logs" {
  bucket = aws_s3_bucket.cloudfront_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "cloudfront_logs" {
  bucket = aws_s3_bucket.cloudfront_logs.id

  rule {
    id     = "cloudfront_logs_lifecycle"
    status = "Enabled"

    filter {
      prefix = "cloudfront-logs/"
    }

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }
  }
} 