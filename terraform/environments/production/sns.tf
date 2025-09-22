# SNS Notifications for Production Environment

module "sns_notifications" {
  source = "../../modules/sns-notifications"

  # Environment Configuration
  aws_region   = var.aws_region
  environment  = var.environment
  project_name = var.project_name
  common_tags  = var.common_tags

  # Email Configuration
  notification_email = var.notification_email
  application_email  = var.application_email  # Separate email for production apps

  # Slack Configuration (optional)
  slack_webhook_url = var.slack_webhook_url

  # Production-specific Configuration
  lambda_timeout     = 60
  lambda_memory_size = 256
  log_retention_days = 30  # Longer retention for production
}

# Output topic ARNs for use by other modules
output "infrastructure_topic_arn" {
  description = "ARN of the infrastructure notifications SNS topic"
  value       = module.sns_notifications.infrastructure_topic_arn
}

output "application_topic_arn" {
  description = "ARN of the application notifications SNS topic"
  value       = module.sns_notifications.application_topic_arn
}