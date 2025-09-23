# Variables for React Hosting Module

variable "app_name" {
  description = "Name of the React application"
  type        = string
}

variable "environment" {
  description = "Environment name (staging, production)"
  type        = string
}

variable "hosting_type" {
  description = "Type of hosting: 'static' for S3+CloudFront or 'serverless' for ECS+ALB+CloudFront"
  type        = string
  default     = "static"
  validation {
    condition     = contains(["static", "serverless"], var.hosting_type)
    error_message = "Hosting type must be either 'static' or 'serverless'."
  }
}

# Common Configuration
variable "app_version" {
  description = "Version of the application"
  type        = string
  default     = "v1.0.0"
}

variable "ssl_certificate_arn" {
  description = "ARN of the SSL certificate for HTTPS"
  type        = string
  default     = null
}

variable "domain_names" {
  description = "List of domain names for the CloudFront distribution"
  type        = list(string)
  default     = []
}

# VPC Configuration (for serverless hosting)
variable "use_existing_vpc" {
  description = "Use existing VPC infrastructure"
  type        = bool
  default     = true
}

# Network configuration - reserved for future VPC integration

variable "alb_security_group_id" {
  description = "Security group ID for the ALB"
  type        = string
  default     = null
}

variable "ecs_security_group_id" {
  description = "Security group ID for ECS tasks"
  type        = string
  default     = null
}

# Serverless Configuration
variable "container_port" {
  description = "Port for the application container"
  type        = number
  default     = 3000
}

variable "desired_count" {
  description = "Desired number of ECS tasks"
  type        = number
  default     = 2
}

variable "task_cpu" {
  description = "CPU units for ECS task"
  type        = number
  default     = 256
}

variable "task_memory" {
  description = "Memory (MiB) for ECS task"
  type        = number
  default     = 512
}

variable "ecs_cpu_architecture" {
  description = "ECS CPU architecture"
  type        = string
  default     = "ARM64"
}

variable "codebuild_compute_type" {
  description = "CodeBuild compute type"
  type        = string
  default     = "BUILD_GENERAL1_SMALL"
}

variable "codebuild_image" {
  description = "CodeBuild Docker image"
  type        = string
  default     = "aws/codebuild/amazonlinux2-aarch64-standard:3.0"
}

variable "app_source_path" {
  description = "Path to the application source code"
  type        = string
  default     = null
}

# Static Configuration
variable "enable_force_destroy" {
  description = "Enable force destroy for S3 bucket"
  type        = bool
  default     = false
}

variable "cloudfront_price_class" {
  description = "CloudFront price class"
  type        = string
  default     = "PriceClass_100"
}

variable "geo_restriction_type" {
  description = "Type of geo restriction"
  type        = string
  default     = "none"
}

variable "geo_restriction_locations" {
  description = "List of country codes for geo restriction"
  type        = list(string)
  default     = []
}

variable "api_cache_behaviors" {
  description = "List of cache behaviors for API routes"
  type = list(object({
    path_pattern           = string
    allowed_methods        = list(string)
    cached_methods         = list(string)
    target_origin_id       = string
    forward_query_string   = bool
    forward_headers        = list(string)
    forward_cookies        = string
    viewer_protocol_policy = string
    min_ttl                = number
    default_ttl            = number
    max_ttl                = number
    compress               = bool
  }))
  default = []
}

variable "enable_cloudfront_invalidation" {
  description = "Enable automatic CloudFront invalidations"
  type        = bool
  default     = true
}

variable "additional_tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "enable_waf" {
  description = "Enable WAF for CloudFront distribution"
  type        = bool
  default     = true
}

variable "waf_rate_limit" {
  description = "Rate limit for WAF rule (requests per 5 minutes)"
  type        = number
  default     = 2000
}

variable "enable_cloudfront_logging" {
  description = "Enable CloudFront access logging"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Number of days to retain CloudFront logs"
  type        = number
  default     = 30
}

variable "enable_origin_failover" {
  description = "Enable origin failover for CloudFront"
  type        = bool
  default     = false
}

variable "failover_bucket_name" {
  description = "Name of the failover S3 bucket"
  type        = string
  default     = null
}