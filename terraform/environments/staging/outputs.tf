# Staging Environment Outputs

# Web Application Outputs
output "web_application_url" {
  description = "URL of the web application"
  value       = module.web_application.alb_dns_name
}

output "web_application_alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = module.web_application.alb_arn
}

output "web_application_target_group_arn" {
  description = "ARN of the ALB target group"
  value       = module.web_application.alb_target_group_arn
}

output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group"
  value       = module.web_application.autoscaling_group_name
}

# React Hosting Outputs
output "react_static_website_url" {
  description = "URL of the static React website"
  value       = module.react_hosting.static_website_url
}

output "react_cloudfront_distribution_id" {
  description = "CloudFront distribution ID for React hosting"
  value       = module.react_hosting.cloudfront_distribution_id
}

output "react_s3_bucket_name" {
  description = "S3 bucket name for React hosting"
  value       = module.react_hosting.s3_bucket_name
}

output "react_serverless_url" {
  description = "URL of the serverless React application"
  value       = module.react_hosting.serverless_app_url
}

# Database Backup Outputs (Phase II)
output "backup_s3_bucket_name" {
  description = "Name of the backup S3 bucket"
  value       = module.database_backup.backup_bucket_name
}

output "backup_lambda_function_name" {
  description = "Name of the backup Lambda function"
  value       = module.database_backup.backup_lambda_function_name
}

output "backup_schedule_rule_arn" {
  description = "ARN of the backup schedule EventBridge rule"
  value       = module.database_backup.backup_schedule_rule_arn
}

# Monitoring and Alerting Outputs (Phase II)
output "infrastructure_dashboard_name" {
  description = "Name of the infrastructure monitoring dashboard"
  value       = module.monitoring_alerting.infrastructure_dashboard_name
}

output "security_dashboard_name" {
  description = "Name of the security monitoring dashboard"
  value       = module.monitoring_alerting.security_dashboard_name
}

output "application_dashboard_name" {
  description = "Name of the application monitoring dashboard"
  value       = module.monitoring_alerting.application_dashboard_name
}

output "monitoring_log_group_names" {
  description = "Names of CloudWatch log groups"
  value       = module.monitoring_alerting.log_group_names
}

# Cost Optimization Outputs (Phase II)
output "monthly_budget_name" {
  description = "Name of the monthly budget"
  value       = module.cost_optimization.monthly_budget_name
}

output "cost_anomaly_detector_arn" {
  description = "ARN of the cost anomaly detector"
  value       = module.cost_optimization.cost_anomaly_detector_arn
}

output "cost_optimizer_function_name" {
  description = "Name of the cost optimization Lambda function"
  value       = module.cost_optimization.cost_optimizer_function_name
}

output "cost_dashboard_url" {
  description = "URL to the cost monitoring dashboard"
  value       = module.cost_optimization.cost_dashboard_url
}

# Compliance Monitoring Outputs (Phase II)
output "compliance_config_rules" {
  description = "List of AWS Config rules for compliance"
  value       = module.compliance_monitoring.config_rule_names
}

output "compliance_checker_function_name" {
  description = "Name of the compliance checker Lambda function"
  value       = module.compliance_monitoring.compliance_checker_function_name
}

output "compliance_dashboard_name" {
  description = "Name of the compliance monitoring dashboard"
  value       = module.compliance_monitoring.compliance_dashboard_name
}

# URLs and Links
output "aws_console_links" {
  description = "Useful AWS console links for this environment"
  value = {
    ec2_instances         = "https://ap-southeast-4.console.aws.amazon.com/ec2/home?region=ap-southeast-4#Instances:"
    load_balancers        = "https://ap-southeast-4.console.aws.amazon.com/ec2/home?region=ap-southeast-4#LoadBalancers:"
    cloudfront            = "https://console.aws.amazon.com/cloudfront/v3/home#/distributions"
    cloudwatch_dashboards = "https://ap-southeast-4.console.aws.amazon.com/cloudwatch/home?region=ap-southeast-4#dashboards:"
    s3_buckets            = "https://s3.console.aws.amazon.com/s3/buckets?region=ap-southeast-4"
    cost_explorer         = "https://console.aws.amazon.com/cost-management/home#/cost-explorer"
    security_hub          = "https://ap-southeast-4.console.aws.amazon.com/securityhub/home?region=ap-southeast-4#/summary"
    config_dashboard      = "https://ap-southeast-4.console.aws.amazon.com/config/home?region=ap-southeast-4#/dashboard"
  }
}

# Environment Summary
output "staging_environment_summary" {
  description = "Summary of staging environment resources"
  value = {
    environment               = var.environment
    region                    = var.aws_region
    web_application_enabled   = true
    react_hosting_enabled     = var.enable_static_hosting || var.enable_serverless_hosting
    database_backup_enabled   = true
    monitoring_enabled        = true
    cost_optimization_enabled = true
    compliance_enabled        = true
    monthly_budget_limit      = var.monthly_budget_limit
    instance_type             = var.instance_type
    min_capacity              = var.min_capacity
    max_capacity              = var.max_capacity
  }
}