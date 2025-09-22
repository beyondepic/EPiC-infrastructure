# Outputs for React Hosting Module

# Serverless Hosting Outputs
output "serverless_app_url" {
  description = "URL of the serverless React application (CloudFront)"
  value       = var.hosting_type == "serverless" ? module.serverless_react_app[0].streamlit_cloudfront_distribution_url : null
}

output "serverless_alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = var.hosting_type == "serverless" ? module.serverless_react_app[0].streamlit_alb_dns_name : null
}

output "serverless_ecr_image_uri" {
  description = "URI of the container image in ECR"
  value       = var.hosting_type == "serverless" ? module.serverless_react_app[0].streamlit_ecr_repo_image_uri : null
}

# Static Hosting Outputs
output "static_bucket_name" {
  description = "Name of the S3 bucket for static hosting"
  value       = var.hosting_type == "static" ? aws_s3_bucket.react_static[0].bucket : null
}

output "static_bucket_domain_name" {
  description = "Domain name of the S3 bucket"
  value       = var.hosting_type == "static" ? aws_s3_bucket.react_static[0].bucket_regional_domain_name : null
}

output "static_cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution"
  value       = var.hosting_type == "static" ? aws_cloudfront_distribution.react_static[0].id : null
}

output "static_cloudfront_domain_name" {
  description = "Domain name of the CloudFront distribution"
  value       = var.hosting_type == "static" ? aws_cloudfront_distribution.react_static[0].domain_name : null
}

output "static_cloudfront_url" {
  description = "URL of the CloudFront distribution"
  value       = var.hosting_type == "static" ? "https://${aws_cloudfront_distribution.react_static[0].domain_name}" : null
}

output "static_cloudfront_hosted_zone_id" {
  description = "Hosted zone ID of the CloudFront distribution"
  value       = var.hosting_type == "static" ? aws_cloudfront_distribution.react_static[0].hosted_zone_id : null
}

# Common Outputs
output "hosting_type" {
  description = "Type of hosting used"
  value       = var.hosting_type
}

output "app_name" {
  description = "Name of the application"
  value       = var.app_name
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "app_version" {
  description = "Version of the application"
  value       = var.app_version
}

# Primary Application URL (automatically selects based on hosting type)
output "application_url" {
  description = "Primary URL to access the React application"
  value = var.hosting_type == "serverless" ? (
    var.hosting_type == "serverless" ? module.serverless_react_app[0].streamlit_cloudfront_distribution_url : null
    ) : (
    var.hosting_type == "static" ? "https://${aws_cloudfront_distribution.react_static[0].domain_name}" : null
  )
}