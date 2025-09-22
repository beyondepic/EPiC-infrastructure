# Production Environment Variables

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "ap-southeast-4"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
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
    Environment = "production"
    ManagedBy   = "Terraform"
    Repository  = "EPiC-infrastructure"
  }
}

# Notification Variables
variable "notification_email" {
  description = "Email address for infrastructure notifications"
  type        = string
  default     = ""
}

variable "application_email" {
  description = "Email address for application notifications (OTP, user alerts)"
  type        = string
  default     = ""
}

variable "slack_webhook_url" {
  description = "Slack webhook URL for notifications"
  type        = string
  default     = ""
  sensitive   = true
}

# Production-specific Variables
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"  # Standard CIDR for production
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"  # Larger instances for production
}

variable "min_size" {
  description = "Minimum number of instances in Auto Scaling Group"
  type        = number
  default     = 2  # High availability
}

variable "max_size" {
  description = "Maximum number of instances in Auto Scaling Group"
  type        = number
  default     = 6
}

variable "desired_capacity" {
  description = "Desired number of instances in Auto Scaling Group"
  type        = number
  default     = 2
}

# Database Variables
variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.small"  # Production-sized database
}

variable "db_allocated_storage" {
  description = "Allocated storage for RDS instance in GB"
  type        = number
  default     = 100
}

variable "db_max_allocated_storage" {
  description = "Maximum allocated storage for RDS auto scaling in GB"
  type        = number
  default     = 1000
}

variable "db_backup_retention_period" {
  description = "Number of days to retain automated backups"
  type        = number
  default     = 30  # Longer retention for production
}

variable "db_backup_window" {
  description = "Preferred backup window"
  type        = string
  default     = "03:00-04:00"  # Early morning UTC
}

variable "db_maintenance_window" {
  description = "Preferred maintenance window"
  type        = string
  default     = "sun:04:00-sun:05:00"  # Sunday early morning UTC
}

# Security Variables
variable "enable_deletion_protection" {
  description = "Enable deletion protection for critical resources"
  type        = bool
  default     = true
}

variable "enable_point_in_time_recovery" {
  description = "Enable point-in-time recovery for RDS"
  type        = bool
  default     = true
}

variable "enable_performance_insights" {
  description = "Enable Performance Insights for RDS"
  type        = bool
  default     = true
}

# Cost Management
variable "budget_limit" {
  description = "Monthly budget limit in USD"
  type        = number
  default     = 1000  # Higher budget for production
}

# Monitoring and Alerting
variable "enable_detailed_monitoring" {
  description = "Enable detailed CloudWatch monitoring"
  type        = bool
  default     = true
}

variable "alarm_cpu_threshold" {
  description = "CPU utilization threshold for alarms"
  type        = number
  default     = 80
}

variable "alarm_memory_threshold" {
  description = "Memory utilization threshold for alarms"
  type        = number
  default     = 85
}

variable "alarm_disk_threshold" {
  description = "Disk utilization threshold for alarms"
  type        = number
  default     = 85
}