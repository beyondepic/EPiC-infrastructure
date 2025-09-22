# Compliance Monitoring Module Variables

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., staging, production)"
  type        = string
}

variable "config_recorder_name" {
  description = "Name of the AWS Config recorder to depend on"
  type        = string
}

variable "compliance_threshold" {
  description = "Threshold for compliance percentage alarm"
  type        = number
  default     = 90
}

variable "notification_topic_arn" {
  description = "ARN of SNS topic for compliance notifications"
  type        = string
}

variable "enable_auto_remediation" {
  description = "Enable automatic remediation for compliance violations"
  type        = bool
  default     = false
}

variable "enable_custom_compliance_checks" {
  description = "Enable custom compliance check Lambda function"
  type        = bool
  default     = true
}

variable "enable_iam_compliance_rules" {
  description = "Enable IAM-related compliance rules"
  type        = bool
  default     = true
}

variable "enable_tag_compliance" {
  description = "Enable tag compliance monitoring"
  type        = bool
  default     = true
}

variable "compliance_check_schedule" {
  description = "Schedule expression for compliance check Lambda"
  type        = string
  default     = "rate(24 hours)"
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 14
}

variable "max_password_age" {
  description = "Maximum password age in days for IAM password policy"
  type        = number
  default     = 90
}

variable "minimum_password_length" {
  description = "Minimum password length for IAM password policy"
  type        = number
  default     = 14
}

variable "password_reuse_prevention" {
  description = "Number of previous passwords to prevent reuse"
  type        = number
  default     = 24
}

variable "required_tags" {
  description = "List of required tag keys for resources"
  type        = list(string)
  default     = ["Environment", "Project", "Owner"]
}

variable "tag_compliance_resource_types" {
  description = "List of resource types to check for tag compliance"
  type        = list(string)
  default = [
    "AWS::EC2::Instance",
    "AWS::EC2::Volume",
    "AWS::S3::Bucket",
    "AWS::RDS::DBInstance"
  ]
}

variable "additional_tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}