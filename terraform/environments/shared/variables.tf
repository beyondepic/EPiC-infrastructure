# Variables for Shared Environment

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "epic"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "shared"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-4"
}

# Networking Configuration
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_count" {
  description = "Number of public subnets"
  type        = number
  default     = 3
}

variable "private_subnet_count" {
  description = "Number of private subnets"
  type        = number
  default     = 3
}

variable "database_subnet_count" {
  description = "Number of database subnets"
  type        = number
  default     = 3
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway"
  type        = bool
  default     = true
}

variable "nat_gateway_count" {
  description = "Number of NAT Gateways"
  type        = number
  default     = 2
}

variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs"
  type        = bool
  default     = true
}

# Security Configuration
variable "enable_config" {
  description = "Enable AWS Config"
  type        = bool
  default     = true
}

variable "enable_guardduty" {
  description = "Enable AWS GuardDuty"
  type        = bool
  default     = true
}

variable "enable_security_hub" {
  description = "Enable AWS Security Hub"
  type        = bool
  default     = true
}

variable "enable_iam_password_policy" {
  description = "Enable strict IAM password policy"
  type        = bool
  default     = true
}

variable "guardduty_s3_protection" {
  description = "Enable GuardDuty S3 protection"
  type        = bool
  default     = true
}

variable "guardduty_kubernetes_protection" {
  description = "Enable GuardDuty Kubernetes protection"
  type        = bool
  default     = false
}

variable "guardduty_malware_protection" {
  description = "Enable GuardDuty malware protection"
  type        = bool
  default     = true
}

# Notifications
variable "notification_email" {
  description = "Email address for notifications"
  type        = string
}

variable "slack_webhook_url" {
  description = "Slack webhook URL for notifications"
  type        = string
  default     = null
}

variable "enable_slack_notifications" {
  description = "Enable Slack notifications"
  type        = bool
  default     = false
}

variable "additional_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default = {
    Owner     = "Platform Team"
    Purpose   = "Shared Infrastructure"
    Cost      = "Shared"
    Terraform = "true"
  }
}