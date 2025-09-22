# Outputs for Security Baseline Module

# CloudTrail
output "cloudtrail_arn" {
  description = "ARN of the CloudTrail"
  value       = aws_cloudtrail.main.arn
}

output "cloudtrail_bucket_name" {
  description = "Name of the CloudTrail S3 bucket"
  value       = aws_s3_bucket.cloudtrail.bucket
}

output "cloudtrail_kms_key_id" {
  description = "ID of the CloudTrail KMS key"
  value       = aws_kms_key.cloudtrail.key_id
}

output "cloudtrail_kms_key_arn" {
  description = "ARN of the CloudTrail KMS key"
  value       = aws_kms_key.cloudtrail.arn
}

# AWS Config
output "config_recorder_name" {
  description = "Name of the AWS Config recorder"
  value       = var.enable_config ? aws_config_configuration_recorder.main[0].name : null
}

output "config_bucket_name" {
  description = "Name of the AWS Config S3 bucket"
  value       = var.enable_config ? aws_s3_bucket.config[0].bucket : null
}

output "config_role_arn" {
  description = "ARN of the AWS Config IAM role"
  value       = var.enable_config ? aws_iam_role.config[0].arn : null
}

# GuardDuty
output "guardduty_detector_id" {
  description = "ID of the GuardDuty detector"
  value       = var.enable_guardduty ? aws_guardduty_detector.main[0].id : null
}

# Security Hub
output "security_hub_account_id" {
  description = "Security Hub account ID"
  value       = var.enable_security_hub ? aws_securityhub_account.main[0].id : null
}

# IAM Roles
output "ec2_instance_role_arn" {
  description = "ARN of the EC2 instance IAM role"
  value       = aws_iam_role.ec2_instance_role.arn
}

output "ec2_instance_role_name" {
  description = "Name of the EC2 instance IAM role"
  value       = aws_iam_role.ec2_instance_role.name
}

output "ec2_instance_profile_name" {
  description = "Name of the EC2 instance profile"
  value       = aws_iam_instance_profile.ec2_instance_profile.name
}

output "lambda_execution_role_arn" {
  description = "ARN of the Lambda execution IAM role"
  value       = aws_iam_role.lambda_execution_role.arn
}

output "lambda_execution_role_name" {
  description = "Name of the Lambda execution IAM role"
  value       = aws_iam_role.lambda_execution_role.name
}

# Account Information
output "aws_account_id" {
  description = "AWS Account ID"
  value       = data.aws_caller_identity.current.account_id
}

output "aws_region" {
  description = "Current AWS region"
  value       = data.aws_region.current.name
}