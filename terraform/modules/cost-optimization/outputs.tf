# Outputs for Cost Optimization Module

# Budget Outputs
output "monthly_budget_name" {
  description = "Name of the monthly budget"
  value       = aws_budgets_budget.monthly_cost.name
}

output "monthly_budget_arn" {
  description = "ARN of the monthly budget"
  value       = aws_budgets_budget.monthly_cost.arn
}

output "service_budget_names" {
  description = "Names of service-specific budgets"
  value       = { for k, v in aws_budgets_budget.service_budgets : k => v.name }
}

output "service_budget_arns" {
  description = "ARNs of service-specific budgets"
  value       = { for k, v in aws_budgets_budget.service_budgets : k => v.arn }
}

# Cost Anomaly Detection
output "cost_anomaly_detector_arn" {
  description = "ARN of the cost anomaly detector"
  value       = aws_ce_anomaly_detector.cost_anomaly.arn
}

output "cost_anomaly_subscription_arn" {
  description = "ARN of the cost anomaly subscription"
  value       = aws_ce_anomaly_subscription.cost_anomaly.arn
}

# Lambda Function Outputs
output "cost_optimizer_function_name" {
  description = "Name of the cost optimization Lambda function"
  value       = var.enable_cost_recommendations ? aws_lambda_function.cost_optimizer[0].function_name : null
}

output "cost_optimizer_function_arn" {
  description = "ARN of the cost optimization Lambda function"
  value       = var.enable_cost_recommendations ? aws_lambda_function.cost_optimizer[0].arn : null
}

output "cost_optimizer_role_arn" {
  description = "ARN of the cost optimization Lambda function's IAM role"
  value       = var.enable_cost_recommendations ? aws_iam_role.cost_optimizer_lambda[0].arn : null
}

# EventBridge Rule
output "cost_optimizer_schedule_rule_name" {
  description = "Name of the EventBridge rule for cost optimization"
  value       = var.enable_cost_recommendations ? aws_cloudwatch_event_rule.cost_optimizer_schedule[0].name : null
}

output "cost_optimizer_schedule_rule_arn" {
  description = "ARN of the EventBridge rule for cost optimization"
  value       = var.enable_cost_recommendations ? aws_cloudwatch_event_rule.cost_optimizer_schedule[0].arn : null
}

# Dashboard
output "cost_dashboard_name" {
  description = "Name of the cost monitoring dashboard"
  value       = aws_cloudwatch_dashboard.cost_monitoring.dashboard_name
}

output "cost_dashboard_url" {
  description = "URL to the cost monitoring dashboard"
  value       = "https://us-east-1.console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=${aws_cloudwatch_dashboard.cost_monitoring.dashboard_name}"
}

# Cost Categories
output "cost_category_arn" {
  description = "ARN of the cost category"
  value       = var.enable_cost_categories ? aws_ce_cost_category.project_categories[0].arn : null
}

# Log Group
output "cost_optimizer_log_group_name" {
  description = "Name of the CloudWatch log group for cost optimizer"
  value       = var.enable_cost_recommendations ? aws_cloudwatch_log_group.cost_optimizer_lambda[0].name : null
}

output "cost_optimizer_log_group_arn" {
  description = "ARN of the CloudWatch log group for cost optimizer"
  value       = var.enable_cost_recommendations ? aws_cloudwatch_log_group.cost_optimizer_lambda[0].arn : null
}

# Configuration Summary
output "cost_optimization_summary" {
  description = "Summary of cost optimization configuration"
  value = {
    monthly_budget_limit         = var.monthly_budget_limit
    budget_alert_threshold       = var.budget_alert_threshold
    anomaly_threshold_amount     = var.anomaly_threshold_amount
    cost_recommendations_enabled = var.enable_cost_recommendations
    service_budgets_count        = length(var.service_budgets)
    monitored_services_count     = length(var.monitored_services)
    optimization_schedule        = var.cost_optimization_schedule
  }
}

# Notification Configuration
output "notification_configuration" {
  description = "Cost notification configuration"
  value = {
    email_addresses = var.notification_emails
    sns_topic_arn   = var.notification_topic_arn
    anomaly_email   = var.cost_anomaly_email
  }
  sensitive = true
}

# URLs and Links
output "aws_cost_explorer_url" {
  description = "URL to AWS Cost Explorer"
  value       = "https://console.aws.amazon.com/cost-management/home#/cost-explorer"
}

output "aws_budgets_url" {
  description = "URL to AWS Budgets console"
  value       = "https://console.aws.amazon.com/billing/home#/budgets"
}

output "aws_cost_anomaly_url" {
  description = "URL to AWS Cost Anomaly Detection console"
  value       = "https://console.aws.amazon.com/cost-management/home#/anomaly-detection"
}