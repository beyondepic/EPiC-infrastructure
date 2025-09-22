# SNS Notifications for Staging Environment

module "sns_notifications" {
  source = "../../modules/sns-notifications"

  # Environment Configuration
  aws_region   = var.aws_region
  environment  = var.environment
  project_name = var.project_name
  common_tags  = var.common_tags

  # Email Configuration
  notification_email = var.notification_email
  application_email  = var.notification_email # Use same email for staging

  # Slack Configuration (optional)
  slack_webhook_url = var.slack_webhook_url

  # Staging-specific Configuration
  lambda_timeout     = 30
  lambda_memory_size = 128
  log_retention_days = 7 # Shorter retention for staging
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