# Variables for Database Backup Module

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (shared, staging, production)"
  type        = string
}

variable "backup_schedule" {
  description = "Schedule expression for automated backups (EventBridge/CloudWatch Events syntax)"
  type        = string
  default     = "cron(0 2 * * ? *)"  # Daily at 2 AM UTC
}

variable "backup_retention_days" {
  description = "Number of days to retain database backups"
  type        = number
  default     = 30
}

variable "backup_prefix" {
  description = "Prefix for backup files in S3"
  type        = string
  default     = "database-backups"
}

variable "notification_topic_arn" {
  description = "SNS topic ARN for backup notifications"
  type        = string
}

variable "enable_force_destroy" {
  description = "Enable force destroy for S3 buckets (use with caution)"
  type        = bool
  default     = false
}

variable "kms_deletion_window" {
  description = "KMS key deletion window in days"
  type        = number
  default     = 7
}

variable "log_retention_days" {
  description = "CloudWatch log retention period in days"
  type        = number
  default     = 14
}

# Cross-region replication settings
variable "enable_cross_region_replication" {
  description = "Enable cross-region replication for backup bucket"
  type        = bool
  default     = false
}

variable "replica_region" {
  description = "AWS region for backup replication"
  type        = string
  default     = null
}

variable "replica_kms_key_id" {
  description = "KMS key ID for replica bucket encryption"
  type        = string
  default     = null
}

# Backup filtering
variable "db_instance_tags" {
  description = "Tags to filter RDS instances for backup (empty means backup all)"
  type        = map(string)
  default     = {}
}

variable "db_cluster_tags" {
  description = "Tags to filter RDS clusters for backup (empty means backup all)"
  type        = map(string)
  default     = {}
}

variable "excluded_instance_ids" {
  description = "List of RDS instance IDs to exclude from backup"
  type        = list(string)
  default     = []
}

variable "excluded_cluster_ids" {
  description = "List of RDS cluster IDs to exclude from backup"
  type        = list(string)
  default     = []
}

# Lambda configuration
variable "lambda_timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 300
}

variable "lambda_memory_size" {
  description = "Lambda function memory size in MB"
  type        = number
  default     = 256
}

variable "additional_tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}