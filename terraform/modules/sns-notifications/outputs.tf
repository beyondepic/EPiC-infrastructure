# SNS Notifications Module Outputs

# Infrastructure Notifications Topic
output "infrastructure_topic_arn" {
  description = "ARN of the infrastructure notifications SNS topic"
  value       = aws_sns_topic.infrastructure_notifications.arn
}

output "infrastructure_topic_name" {
  description = "Name of the infrastructure notifications SNS topic"
  value       = aws_sns_topic.infrastructure_notifications.name
}

# Application Notifications Topic
output "application_topic_arn" {
  description = "ARN of the application notifications SNS topic"
  value       = aws_sns_topic.application_notifications.arn
}

output "application_topic_name" {
  description = "Name of the application notifications SNS topic"
  value       = aws_sns_topic.application_notifications.name
}

# Lambda Function (if created)
output "slack_notifier_function_arn" {
  description = "ARN of the Slack notifier Lambda function"
  value       = var.slack_webhook_url != "" ? aws_lambda_function.slack_notifier[0].arn : null
  sensitive   = true
}

output "slack_notifier_function_name" {
  description = "Name of the Slack notifier Lambda function"
  value       = var.slack_webhook_url != "" ? aws_lambda_function.slack_notifier[0].function_name : null
  sensitive   = true
}

# Topic URLs for publishing
output "infrastructure_topic_endpoint" {
  description = "HTTPS endpoint for publishing to infrastructure notifications topic"
  value       = "https://sns.${var.aws_region}.amazonaws.com/${aws_sns_topic.infrastructure_notifications.arn}"
}

output "application_topic_endpoint" {
  description = "HTTPS endpoint for publishing to application notifications topic"
  value       = "https://sns.${var.aws_region}.amazonaws.com/${aws_sns_topic.application_notifications.arn}"
}

# Subscription Status
output "email_subscriptions_pending" {
  description = "List of email subscriptions that require confirmation"
  value = concat(
    var.notification_email != "" ? [var.notification_email] : [],
    var.application_email != "" ? [var.application_email] : []
  )
}

# Module Information
output "module_info" {
  description = "Information about the SNS notifications module"
  value = {
    module_name         = "sns-notifications"
    environment         = var.environment
    project_name        = var.project_name
    topics_created      = 2
    slack_enabled       = var.slack_webhook_url != ""
    email_notifications = var.notification_email != "" || var.application_email != ""
  }
  sensitive = true
}