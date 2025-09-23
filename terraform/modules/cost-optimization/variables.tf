# Variables for Cost Optimization Module

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (shared, staging, production)"
  type        = string
}

# Budget Configuration
variable "monthly_budget_limit" {
  description = "Monthly budget limit in USD"
  type        = number
  default     = 100
}

variable "budget_alert_threshold" {
  description = "Budget alert threshold percentage"
  type        = number
  default     = 80
}

variable "budget_forecast_threshold" {
  description = "Budget forecast alert threshold percentage"
  type        = number
  default     = 100
}

variable "notification_emails" {
  description = "List of email addresses for budget notifications"
  type        = list(string)
  default     = []
}

variable "notification_topic_arn" {
  description = "SNS topic ARN for cost notifications"
  type        = string
  default     = null
}

# Service-specific budgets
variable "service_budgets" {
  description = "Service-specific budget configurations"
  type = map(object({
    service_name    = string
    limit           = number
    alert_threshold = number
  }))
  default = {}
}

# Cost Anomaly Detection
variable "anomaly_threshold_amount" {
  description = "Cost anomaly threshold amount in USD"
  type        = number
  default     = 25
}

variable "cost_anomaly_email" {
  description = "Email address for cost anomaly notifications"
  type        = string
  default     = null
}

variable "monitored_services" {
  description = "List of AWS services to monitor for cost anomalies"
  type        = list(string)
  default     = ["Amazon Elastic Compute Cloud - Compute", "Amazon Simple Storage Service", "Amazon Relational Database Service"]
}

# Cost Allocation
variable "cost_allocation_tags" {
  description = "Tags used for cost allocation"
  type        = map(string)
  default = {
    Project     = ""
    Environment = ""
  }
}

variable "enable_cost_categories" {
  description = "Enable AWS Cost Categories for cost allocation"
  type        = bool
  default     = false
}

# Cost Optimization Features
variable "enable_cost_recommendations" {
  description = "Enable automated cost optimization recommendations"
  type        = bool
  default     = true
}

variable "cost_optimization_schedule" {
  description = "Schedule expression for cost optimization analysis"
  type        = string
  default     = "cron(0 9 * * MON *)" # Every Monday at 9 AM UTC
}

variable "recommendation_cost_threshold" {
  description = "Minimum monthly savings threshold for recommendations (USD)"
  type        = number
  default     = 10
}

variable "recommendation_utilization_threshold" {
  description = "Maximum utilization threshold for downsizing recommendations (%)"
  type        = number
  default     = 20
}

# Reserved Instance Configuration
variable "enable_ri_recommendations" {
  description = "Enable Reserved Instance purchase recommendations"
  type        = bool
  default     = true
}

# S3 Cost Optimization
variable "enable_s3_lifecycle_recommendations" {
  description = "Enable S3 lifecycle policy recommendations"
  type        = bool
  default     = true
}

variable "s3_glacier_transition_days" {
  description = "Days after which objects transition to Glacier"
  type        = number
  default     = 90
}

# Lambda Configuration
variable "lambda_timeout" {
  description = "Timeout for cost optimization Lambda function"
  type        = number
  default     = 300
}

variable "log_retention_days" {
  description = "CloudWatch log retention period in days"
  type        = number
  default     = 14
}

# Right-sizing Configuration
variable "enable_rightsizing_recommendations" {
  description = "Enable EC2 right-sizing recommendations"
  type        = bool
  default     = true
}

# Cost Dashboard Configuration
# Note: dashboard_widgets variable reserved for future use

variable "additional_tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}