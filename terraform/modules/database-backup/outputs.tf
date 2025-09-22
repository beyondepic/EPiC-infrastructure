# Outputs for Database Backup Module

# S3 Bucket Outputs
output "backup_bucket_name" {
  description = "Name of the S3 bucket for database backups"
  value       = aws_s3_bucket.db_backups.bucket
}

output "backup_bucket_arn" {
  description = "ARN of the S3 bucket for database backups"
  value       = aws_s3_bucket.db_backups.arn
}

output "backup_bucket_domain_name" {
  description = "Domain name of the S3 bucket"
  value       = aws_s3_bucket.db_backups.bucket_domain_name
}

output "replica_bucket_name" {
  description = "Name of the replica S3 bucket (if cross-region replication is enabled)"
  value       = var.enable_cross_region_replication ? aws_s3_bucket.db_backups_replica[0].bucket : null
}

output "replica_bucket_arn" {
  description = "ARN of the replica S3 bucket (if cross-region replication is enabled)"
  value       = var.enable_cross_region_replication ? aws_s3_bucket.db_backups_replica[0].arn : null
}

# KMS Key Outputs
output "kms_key_id" {
  description = "ID of the KMS key used for backup encryption"
  value       = aws_kms_key.db_backup.key_id
}

output "kms_key_arn" {
  description = "ARN of the KMS key used for backup encryption"
  value       = aws_kms_key.db_backup.arn
}

output "kms_key_alias" {
  description = "Alias of the KMS key used for backup encryption"
  value       = aws_kms_alias.db_backup.name
}

# Lambda Function Outputs
output "lambda_function_name" {
  description = "Name of the backup Lambda function"
  value       = aws_lambda_function.db_backup.function_name
}

output "lambda_function_arn" {
  description = "ARN of the backup Lambda function"
  value       = aws_lambda_function.db_backup.arn
}

output "lambda_function_role_arn" {
  description = "ARN of the Lambda function's IAM role"
  value       = aws_iam_role.db_backup_lambda.arn
}

# EventBridge Rule Outputs
output "backup_schedule_rule_name" {
  description = "Name of the EventBridge rule for backup scheduling"
  value       = aws_cloudwatch_event_rule.db_backup_schedule.name
}

output "backup_schedule_rule_arn" {
  description = "ARN of the EventBridge rule for backup scheduling"
  value       = aws_cloudwatch_event_rule.db_backup_schedule.arn
}

output "backup_schedule" {
  description = "Schedule expression for automated backups"
  value       = var.backup_schedule
}

# CloudWatch Log Group
output "log_group_name" {
  description = "Name of the CloudWatch log group for Lambda function"
  value       = aws_cloudwatch_log_group.db_backup_lambda.name
}

output "log_group_arn" {
  description = "ARN of the CloudWatch log group for Lambda function"
  value       = aws_cloudwatch_log_group.db_backup_lambda.arn
}

# Backup Configuration
output "backup_retention_days" {
  description = "Number of days backups are retained"
  value       = var.backup_retention_days
}

output "backup_prefix" {
  description = "Prefix used for backup files"
  value       = var.backup_prefix
}

# Replication Configuration
output "cross_region_replication_enabled" {
  description = "Whether cross-region replication is enabled"
  value       = var.enable_cross_region_replication
}

output "replica_region" {
  description = "AWS region for backup replication"
  value       = var.replica_region
}