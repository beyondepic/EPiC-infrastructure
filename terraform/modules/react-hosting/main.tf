# React Hosting Module
# Provides options for hosting React applications using either:
# 1. AWS-IA Serverless Streamlit App module (adapted for React/Node.js)
# 2. Traditional S3 + CloudFront static hosting

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Option 1: Serverless hosting using AWS-IA module (for dynamic React apps)
module "serverless_react_app" {
  count = var.hosting_type == "serverless" ? 1 : 0

  source = "aws-ia/serverless-streamlit-app/aws"
  version = "~> 1.1.0"

  app_name    = var.app_name
  environment = var.environment
  app_version = var.app_version

  # VPC Configuration
  create_vpc_resources = var.use_existing_vpc
  vpc_id              = var.use_existing_vpc ? var.vpc_id : null
  alb_subnets         = var.use_existing_vpc ? var.public_subnet_ids : null
  ecs_subnets         = var.use_existing_vpc ? var.private_subnet_ids : null

  # Security Groups
  create_alb_security_group = var.use_existing_vpc ? false : true
  create_ecs_security_group = var.use_existing_vpc ? false : true
  existing_alb_security_groups = var.use_existing_vpc ? [var.alb_security_group_id] : null
  existing_ecs_security_groups = var.use_existing_vpc ? [var.ecs_security_group_id] : null

  # Application Configuration
  container_port = var.container_port
  desired_count  = var.desired_count
  task_cpu       = var.task_cpu
  task_memory    = var.task_memory

  # ECS Configuration
  ecs_cpu_architecture = var.ecs_cpu_architecture
  codebuild_compute_type = var.codebuild_compute_type
  codebuild_image = var.codebuild_image

  # SSL Configuration
  enable_alb_https_listener = var.ssl_certificate_arn != null
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

# CloudFront Distribution for static hosting
resource "aws_cloudfront_distribution" "react_static" {
  count = var.hosting_type == "static" ? 1 : 0

  origin {
    domain_name              = aws_s3_bucket.react_static[0].bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.react_static[0].id
    origin_id                = "S3-${aws_s3_bucket.react_static[0].bucket}"
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CloudFront distribution for ${var.app_name}"
  default_root_object = "index.html"

  aliases = var.domain_names

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.react_static[0].bucket}"

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

  restrictions {
    geo_restriction {
      restriction_type = var.geo_restriction_type
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
  count = var.hosting_type == "static" ? 1 : 0

  length  = 8
  special = false
  upper   = false
}