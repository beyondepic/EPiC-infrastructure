# SNS Notifications Module Variables

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
}

variable "environment" {
  description = "Environment name (staging, production, shared, development)"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# Notification Configuration
variable "notification_email" {
  description = "Email address for infrastructure notifications"
  type        = string
  default     = ""

  validation {
    condition     = var.notification_email == "" || can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.notification_email))
    error_message = "Notification email must be a valid email address or empty string."
  }
}

variable "application_email" {
  description = "Email address for application notifications (OTP, user alerts)"
  type        = string
  default     = ""

  validation {
    condition     = var.application_email == "" || can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.application_email))
    error_message = "Application email must be a valid email address or empty string."
  }
}

variable "slack_webhook_url" {
  description = "Slack webhook URL for notifications"
  type        = string
  default     = ""
  sensitive   = true
}

# Configuration placeholders for future features
# These settings will be implemented when Lambda and logging features are added