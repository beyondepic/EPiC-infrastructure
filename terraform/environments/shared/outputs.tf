# Outputs for Shared Environment

# Networking Outputs
output "vpc_id" {
  description = "ID of the shared VPC"
  value       = module.shared_networking.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the shared VPC"
  value       = module.shared_networking.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.shared_networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.shared_networking.private_subnet_ids
}

output "database_subnet_ids" {
  description = "IDs of the database subnets"
  value       = module.shared_networking.database_subnet_ids
}

output "web_security_group_id" {
  description = "ID of the web security group"
  value       = module.shared_networking.web_security_group_id
}

output "application_security_group_id" {
  description = "ID of the application security group"
  value       = module.shared_networking.application_security_group_id
}

output "database_security_group_id" {
  description = "ID of the database security group"
  value       = module.shared_networking.database_security_group_id
}

output "db_subnet_group_name" {
  description = "Name of the database subnet group"
  value       = module.shared_networking.db_subnet_group_name
}

# Security Outputs
output "cloudtrail_arn" {
  description = "ARN of the CloudTrail"
  value       = module.security_baseline.cloudtrail_arn
}

output "ec2_instance_role_arn" {
  description = "ARN of the EC2 instance IAM role"
  value       = module.security_baseline.ec2_instance_role_arn
}

output "ec2_instance_profile_name" {
  description = "Name of the EC2 instance profile"
  value       = module.security_baseline.ec2_instance_profile_name
}

output "lambda_execution_role_arn" {
  description = "ARN of the Lambda execution IAM role"
  value       = module.security_baseline.lambda_execution_role_arn
}

output "guardduty_detector_id" {
  description = "ID of the GuardDuty detector"
  value       = module.security_baseline.guardduty_detector_id
}

# Notification Outputs
output "notification_topic_arn" {
  description = "ARN of the notification SNS topic"
  value       = module.shared_notifications.sns_topic_arn
}

output "alert_topic_arn" {
  description = "ARN of the alert SNS topic"
  value       = module.shared_notifications.alert_topic_arn
}

# Account Information
output "aws_account_id" {
  description = "AWS Account ID"
  value       = module.security_baseline.aws_account_id
}

output "aws_region" {
  description = "Current AWS region"
  value       = module.security_baseline.aws_region
}