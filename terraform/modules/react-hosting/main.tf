# React Hosting Module
# Provides options for hosting React applications using either:
# 1. AWS-IA Serverless Streamlit App module (adapted for React/Node.js)
# 2. Traditional S3 + CloudFront static hosting

# Data sources - reserved for future use

# Option 1: Serverless hosting using AWS-IA module (for dynamic React apps)
module "serverless_react_app" {
  count = var.hosting_type == "serverless" ? 1 : 0

  source  = "aws-ia/serverless-streamlit-app/aws"
  version = "~> 1.1.0"

  app_name    = var.app_name
  environment = var.environment
  app_version = var.app_version

  # VPC Configuration
  create_vpc_resources = var.use_existing_vpc ? false : true

  # Security Groups
  create_alb_security_group    = var.use_existing_vpc ? false : true
  create_ecs_security_group    = var.use_existing_vpc ? false : true
  existing_alb_security_groups = var.use_existing_vpc ? [var.alb_security_group_id] : null
  existing_ecs_security_groups = var.use_existing_vpc ? [var.ecs_security_group_id] : null

  # Application Configuration
  container_port = var.container_port
  desired_count  = var.desired_count
  task_cpu       = var.task_cpu
  task_memory    = var.task_memory

  # ECS Configuration
  ecs_cpu_architecture   = var.ecs_cpu_architecture
  codebuild_compute_type = var.codebuild_compute_type
  codebuild_image        = var.codebuild_image

  # SSL Configuration
  enable_alb_https_listener        = var.ssl_certificate_arn != null
  existing_alb_https_listener_cert = var.ssl_certificate_arn

  # CloudFront Configuration
  enable_auto_cloudfront_invalidation = var.enable_cloudfront_invalidation

  # Application Source
  path_to_app_dir = var.app_source_path

  tags = merge(
    {
      Module = "react-hosting"
      Type   = "serverless"
    },
    var.additional_tags
  )
}

# Option 2: Static hosting using S3 + CloudFront (for static React apps)
resource "aws_s3_bucket" "react_static" {
  count = var.hosting_type == "static" ? 1 : 0

  bucket        = "${var.app_name}-${var.environment}-static-${random_string.bucket_suffix.result}"
  force_destroy = var.enable_force_destroy

  tags = merge(
    {
      Name        = "${var.app_name}-${var.environment}-static-bucket"
      Environment = var.environment
      Module      = "react-hosting"
      Type        = "static"
    },
    var.additional_tags
  )
}

resource "aws_s3_bucket_public_access_block" "react_static" {
  count = var.hosting_type == "static" ? 1 : 0

  bucket = aws_s3_bucket.react_static[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "react_static" {
  count = var.hosting_type == "static" ? 1 : 0

  bucket = aws_s3_bucket.react_static[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "react_static" {
  count = var.hosting_type == "static" ? 1 : 0

  bucket = aws_s3_bucket.react_static[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Origin Access Control for CloudFront
resource "aws_cloudfront_origin_access_control" "react_static" {
  count = var.hosting_type == "static" ? 1 : 0

  name                              = "${var.app_name}-${var.environment}-oac"
  description                       = "OAC for ${var.app_name} static site"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# S3 bucket for CloudFront logs
resource "aws_s3_bucket" "cloudfront_logs" {
  count = var.hosting_type == "static" && var.enable_cloudfront_logging ? 1 : 0

  bucket        = "${var.app_name}-${var.environment}-cf-logs-${random_string.bucket_suffix.result}"
  force_destroy = var.enable_force_destroy

  tags = merge(
    {
      Name        = "${var.app_name}-${var.environment}-cloudfront-logs"
      Environment = var.environment
      Module      = "react-hosting"
      Type        = "logs"
    },
    var.additional_tags
  )
}

resource "aws_s3_bucket_public_access_block" "cloudfront_logs" {
  count = var.hosting_type == "static" && var.enable_cloudfront_logging ? 1 : 0

  bucket = aws_s3_bucket.cloudfront_logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudfront_logs" {
  count = var.hosting_type == "static" && var.enable_cloudfront_logging ? 1 : 0

  bucket = aws_s3_bucket.cloudfront_logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "cloudfront_logs" {
  count = var.hosting_type == "static" && var.enable_cloudfront_logging ? 1 : 0

  bucket = aws_s3_bucket.cloudfront_logs[0].id

  rule {
    id = "expire-old-logs"

    filter {
      prefix = "cf-logs/"
    }

    expiration {
      days = var.log_retention_days
    }

    status = "Enabled"
  }
}

# WAF Web ACL for CloudFront
resource "aws_wafv2_web_acl" "cloudfront" {
  count = var.hosting_type == "static" && var.enable_waf ? 1 : 0

  name  = "${var.app_name}-${var.environment}-cloudfront-waf"
  scope = "CLOUDFRONT"

  default_action {
    allow {}
  }

  # AWS Managed Core Rule Set
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.app_name}${var.environment}CommonRuleSetMetric"
      sampled_requests_enabled   = true
    }
  }

  # Rate Limiting Rule
  rule {
    name     = "RateLimitRule"
    priority = 2

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = var.waf_rate_limit
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.app_name}${var.environment}RateLimitMetric"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.app_name}${var.environment}CloudFrontWebACL"
    sampled_requests_enabled   = true
  }

  tags = merge(
    {
      Name        = "${var.app_name}-${var.environment}-cloudfront-waf"
      Environment = var.environment
      Module      = "react-hosting"
    },
    var.additional_tags
  )
}

# CloudFront Distribution for static hosting
resource "aws_cloudfront_distribution" "react_static" {
  count = var.hosting_type == "static" ? 1 : 0

  web_acl_id = var.enable_waf ? aws_wafv2_web_acl.cloudfront[0].arn : null

  origin {
    domain_name              = aws_s3_bucket.react_static[0].bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.react_static[0].id
    origin_id                = "S3-Primary-${aws_s3_bucket.react_static[0].bucket}"
  }

  # Origin group for failover (optional)
  dynamic "origin_group" {
    for_each = var.enable_origin_failover ? [1] : []
    content {
      origin_id = "S3-OriginGroup"

      failover_criteria {
        status_codes = [403, 404, 500, 502, 503, 504]
      }

      member {
        origin_id = "S3-Primary-${aws_s3_bucket.react_static[0].bucket}"
      }

      member {
        origin_id = "S3-Failover-${aws_s3_bucket.react_static[0].bucket}"
      }
    }
  }

  # Failover origin (if enabled)
  dynamic "origin" {
    for_each = var.enable_origin_failover && var.failover_bucket_name != null ? [1] : []
    content {
      domain_name = "${var.failover_bucket_name}.s3.amazonaws.com"
      origin_id   = "S3-Failover-${aws_s3_bucket.react_static[0].bucket}"

      s3_origin_config {
        origin_access_identity = ""
      }
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CloudFront distribution for ${var.app_name}"
  default_root_object = "index.html"

  aliases = var.domain_names

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = var.enable_origin_failover ? "S3-OriginGroup" : "S3-Primary-${aws_s3_bucket.react_static[0].bucket}"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = var.ssl_certificate_arn != null ? "redirect-to-https" : "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
  }

  # Cache behavior for API routes (if any)
  dynamic "ordered_cache_behavior" {
    for_each = var.api_cache_behaviors
    content {
      path_pattern     = ordered_cache_behavior.value.path_pattern
      allowed_methods  = ordered_cache_behavior.value.allowed_methods
      cached_methods   = ordered_cache_behavior.value.cached_methods
      target_origin_id = ordered_cache_behavior.value.target_origin_id

      forwarded_values {
        query_string = ordered_cache_behavior.value.forward_query_string
        headers      = ordered_cache_behavior.value.forward_headers
        cookies {
          forward = ordered_cache_behavior.value.forward_cookies
        }
      }

      viewer_protocol_policy = ordered_cache_behavior.value.viewer_protocol_policy
      min_ttl                = ordered_cache_behavior.value.min_ttl
      default_ttl            = ordered_cache_behavior.value.default_ttl
      max_ttl                = ordered_cache_behavior.value.max_ttl
      compress               = ordered_cache_behavior.value.compress
    }
  }

  # Custom error responses for React Router
  custom_error_response {
    error_caching_min_ttl = 0
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
  }

  custom_error_response {
    error_caching_min_ttl = 0
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
  }

  price_class = var.cloudfront_price_class

  # Logging configuration
  dynamic "logging_config" {
    for_each = var.enable_cloudfront_logging ? [1] : []
    content {
      include_cookies = false
      bucket          = aws_s3_bucket.cloudfront_logs[0].bucket_domain_name
      prefix          = "cf-logs/"
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = var.geo_restriction_type != "" ? var.geo_restriction_type : "none"
      locations        = var.geo_restriction_locations
    }
  }

  dynamic "viewer_certificate" {
    for_each = var.ssl_certificate_arn != null ? [1] : []
    content {
      acm_certificate_arn      = var.ssl_certificate_arn
      ssl_support_method       = "sni-only"
      minimum_protocol_version = "TLSv1.2_2021"
    }
  }

  dynamic "viewer_certificate" {
    for_each = var.ssl_certificate_arn == null ? [1] : []
    content {
      cloudfront_default_certificate = true
    }
  }

  tags = merge(
    {
      Name        = "${var.app_name}-${var.environment}-cloudfront"
      Environment = var.environment
      Module      = "react-hosting"
      Type        = "static"
    },
    var.additional_tags
  )
}

# S3 bucket policy for CloudFront
resource "aws_s3_bucket_policy" "react_static" {
  count = var.hosting_type == "static" ? 1 : 0

  bucket = aws_s3_bucket.react_static[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipal"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.react_static[0].arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.react_static[0].arn
          }
        }
      }
    ]
  })
}

# Random string for unique bucket names
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}