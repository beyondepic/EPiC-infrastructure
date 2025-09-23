# Variables for Monitoring and Alerting Module

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (shared, staging, production)"
  type        = string
}

variable "alert_topic_arn" {
  description = "SNS topic ARN for alert notifications"
  type        = string
}

# Dashboard Configuration
variable "applications" {
  description = "List of applications to monitor"
  type = list(object({
    name               = string
    load_balancer_name = string
  }))
  default = []
}

# Alarm Thresholds
variable "cpu_alarm_threshold" {
  description = "CPU utilization threshold for alarms (percentage)"
  type        = number
  default     = 80
}

variable "memory_alarm_threshold" {
  description = "Memory utilization threshold for alarms (percentage)"
  type        = number
  default     = 85
}

variable "disk_alarm_threshold" {
  description = "Disk utilization threshold for alarms (percentage)"
  type        = number
  default     = 90
}

variable "response_time_threshold" {
  description = "Response time threshold for ALB alarms (seconds)"
  type        = number
  default     = 5
}

variable "error_rate_threshold" {
  description = "Error rate threshold for ALB alarms (count)"
  type        = number
  default     = 10
}

variable "rds_cpu_threshold" {
  description = "RDS CPU utilization threshold (percentage)"
  type        = number
  default     = 75
}

variable "rds_memory_threshold" {
  description = "RDS freeable memory threshold (bytes)"
  type        = number
  default     = 104857600 # 100MB
}

variable "lambda_error_threshold" {
  description = "Lambda error count threshold"
  type        = number
  default     = 5
}

variable "lambda_duration_threshold" {
  description = "Lambda duration threshold (milliseconds)"
  type        = number
  default     = 30000 # 30 seconds
}

variable "application_error_threshold" {
  description = "Application error count threshold"
  type        = number
  default     = 10
}

variable "security_alert_severity_threshold" {
  description = "Minimum severity level for security alerts (1-10, where 10 is highest)"
  type        = number
  default     = 7
}

# Resource Identifiers
variable "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group to monitor"
  type        = string
  default     = null
}

variable "load_balancer_arn" {
  description = "ARN of the Application Load Balancer to monitor"
  type        = string
  default     = null
}

variable "rds_instance_id" {
  description = "RDS instance identifier to monitor"
  type        = string
  default     = null
}

variable "lambda_functions" {
  description = "Map of Lambda functions to monitor (key = friendly name, value = function name)"
  type        = map(string)
  default     = {}
}

variable "log_group_names" {
  description = "List of CloudWatch log group names to include in dashboards and queries"
  type        = list(string)
  default     = []
}

# Feature Toggles
variable "enable_memory_monitoring" {
  description = "Enable memory utilization monitoring (requires CloudWatch agent)"
  type        = bool
  default     = false
}

variable "enable_disk_monitoring" {
  description = "Enable disk utilization monitoring (requires CloudWatch agent)"
  type        = bool
  default     = false
}

# Advanced monitoring features - reserved for future implementation
# - enable_security_dashboard: Security-specific dashboard
# - enable_application_dashboard: Application-specific dashboard
# - enable_custom_metrics: Custom application metrics
# - cloudwatch_agent_config: CloudWatch agent configuration
# - log_retention_days: Number of days to retain CloudWatch logs
# - enable_cost_alerts: Cost monitoring and alerts
# - monthly_cost_budget: Monthly cost budget for alerts
# - cost_alert_threshold: Cost alert threshold percentage

# Additional tags - reserved for future implementation