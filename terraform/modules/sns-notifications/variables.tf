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
    condition = var.notification_email == "" || can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.notification_email))
    error_message = "Notification email must be a valid email address or empty string."
  }
}

variable "application_email" {
  description = "Email address for application notifications (OTP, user alerts)"
  type        = string
  default     = ""

  validation {
    condition = var.application_email == "" || can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.application_email))
    error_message = "Application email must be a valid email address or empty string."
  }
}

variable "slack_webhook_url" {
  description = "Slack webhook URL for notifications"
  type        = string
  default     = ""
  sensitive   = true
}

# Topic Configuration
variable "enable_delivery_status_logging" {
  description = "Enable delivery status logging for SNS topics"
  type        = bool
  default     = false
}

variable "message_retention_hours" {
  description = "Number of hours to retain messages in case of delivery failure"
  type        = number
  default     = 24

  validation {
    condition = var.message_retention_hours >= 1 && var.message_retention_hours <= 168
    error_message = "Message retention must be between 1 and 168 hours (1 week)."
  }
}

# Lambda Configuration
variable "lambda_timeout" {
  description = "Timeout for Lambda function in seconds"
  type        = number
  default     = 30

  validation {
    condition = var.lambda_timeout >= 1 && var.lambda_timeout <= 900
    error_message = "Lambda timeout must be between 1 and 900 seconds."
  }
}

variable "lambda_memory_size" {
  description = "Memory size for Lambda function in MB"
  type        = number
  default     = 128

  validation {
    condition = var.lambda_memory_size >= 128 && var.lambda_memory_size <= 10240
    error_message = "Lambda memory size must be between 128 and 10240 MB."
  }
}

# Logging Configuration
variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 14

  validation {
    condition = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.log_retention_days)
    error_message = "Log retention days must be one of the supported CloudWatch values."
  }
}