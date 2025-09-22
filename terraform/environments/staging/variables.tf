# Staging Environment Variables

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "ap-southeast-4"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "staging"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "epic"
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "EPiC Infrastructure"
    Environment = "staging"
    ManagedBy   = "Terraform"
    Repository  = "EPiC-infrastructure"
  }
}

# Notification Variables
variable "notification_email" {
  description = "Email address for notifications"
  type        = string
  default     = ""
}

variable "application_email" {
  description = "Email address for application notifications"
  type        = string
  default     = ""
}

variable "slack_webhook_url" {
  description = "Slack webhook URL for notifications"
  type        = string
  default     = ""
  sensitive   = true
}

# Staging-specific Variables
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.1.0.0/16"  # Different CIDR for staging
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.small"  # Smaller instances for staging
}

variable "min_size" {
  description = "Minimum number of instances in Auto Scaling Group"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of instances in Auto Scaling Group"
  type        = number
  default     = 2
}

variable "desired_capacity" {
  description = "Desired number of instances in Auto Scaling Group"
  type        = number
  default     = 1
}

# Database Variables
variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"  # Smaller database for staging
}

variable "db_allocated_storage" {
  description = "Allocated storage for RDS instance in GB"
  type        = number
  default     = 20
}

variable "db_backup_retention_period" {
  description = "Number of days to retain automated backups"
  type        = number
  default     = 7  # Shorter retention for staging
}

# Cost Management
variable "budget_limit" {
  description = "Monthly budget limit in USD"
  type        = number
  default     = 200  # Lower budget for staging
}