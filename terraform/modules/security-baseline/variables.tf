# Variables for Security Baseline Module

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (shared, staging, production)"
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

# AWS Config
variable "enable_config" {
  description = "Enable AWS Config for compliance monitoring"
  type        = bool
  default     = true
}

# GuardDuty
variable "enable_guardduty" {
  description = "Enable AWS GuardDuty for threat detection"
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

# Security Hub
variable "enable_security_hub" {
  description = "Enable AWS Security Hub"
  type        = bool
  default     = true
}

# IAM Password Policy
variable "enable_iam_password_policy" {
  description = "Enable strict IAM password policy"
  type        = bool
  default     = true
}

variable "password_min_length" {
  description = "Minimum password length"
  type        = number
  default     = 14
}

variable "password_max_age" {
  description = "Maximum password age in days"
  type        = number
  default     = 90
}

variable "password_reuse_prevention" {
  description = "Number of previous passwords to prevent reuse"
  type        = number
  default     = 12
}

variable "additional_tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}