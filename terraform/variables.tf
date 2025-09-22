# Global Variables for EPiC Infrastructure
# These variables are used across all environments and modules

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "ap-southeast-4"

  validation {
    condition = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.aws_region))
    error_message = "AWS region must be in the format: xx-xxxxx-x (e.g., ap-southeast-4)."
  }
}

variable "environment" {
  description = "Environment name (staging, production, shared)"
  type        = string

  validation {
    condition = contains(["staging", "production", "shared", "development"], var.environment)
    error_message = "Environment must be one of: staging, production, shared, development."
  }
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "epic"

  validation {
    condition = can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.project_name))
    error_message = "Project name must start with a letter, contain only lowercase letters, numbers, and hyphens, and end with a letter or number."
  }
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# Networking Variables
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["ap-southeast-4a", "ap-southeast-4b", "ap-southeast-4c"]
}

# Security Variables
variable "enable_flow_logs" {
  description = "Enable VPC flow logs"
  type        = bool
  default     = true
}

variable "enable_config" {
  description = "Enable AWS Config"
  type        = bool
  default     = true
}

variable "enable_guardduty" {
  description = "Enable GuardDuty"
  type        = bool
  default     = true
}

# Cost Management Variables
variable "cost_center" {
  description = "Cost center for billing"
  type        = string
  default     = "infrastructure"
}

variable "budget_limit" {
  description = "Monthly budget limit in USD"
  type        = number
  default     = 1000
}

# Backup Variables
variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 30

  validation {
    condition = var.backup_retention_days >= 1 && var.backup_retention_days <= 365
    error_message = "Backup retention must be between 1 and 365 days."
  }
}

# Notification Variables
variable "notification_email" {
  description = "Email address for notifications"
  type        = string
  default     = ""

  validation {
    condition = var.notification_email == "" || can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.notification_email))
    error_message = "Notification email must be a valid email address or empty string."
  }
}

variable "slack_webhook_url" {
  description = "Slack webhook URL for notifications"
  type        = string
  default     = ""
  sensitive   = true
}