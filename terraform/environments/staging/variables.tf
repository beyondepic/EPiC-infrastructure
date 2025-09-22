# Staging Environment Variables

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "ap-southeast-4"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "staging"
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
    Environment = "staging"
    ManagedBy   = "Terraform"
    Repository  = "EPiC-infrastructure"
  }
}

# Notification Variables
variable "notification_email" {
  description = "Email address for notifications"
  type        = string
  default     = ""
}

variable "application_email" {
  description = "Email address for application notifications"
  type        = string
  default     = ""
}

variable "slack_webhook_url" {
  description = "Slack webhook URL for notifications"
  type        = string
  default     = ""
  sensitive   = true
}

# Staging-specific Variables
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.1.0.0/16" # Different CIDR for staging
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.small" # Smaller instances for staging
}

variable "min_size" {
  description = "Minimum number of instances in Auto Scaling Group"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of instances in Auto Scaling Group"
  type        = number
  default     = 2
}

variable "desired_capacity" {
  description = "Desired number of instances in Auto Scaling Group"
  type        = number
  default     = 1
}

# Database Variables
variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro" # Smaller database for staging
}

variable "db_allocated_storage" {
  description = "Allocated storage for RDS instance in GB"
  type        = number
  default     = 20
}

variable "db_backup_retention_period" {
  description = "Number of days to retain automated backups"
  type        = number
  default     = 7 # Shorter retention for staging
}

# Additional Tags
variable "additional_tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}

# Web Application Variables
variable "min_capacity" {
  description = "Minimum number of instances in Auto Scaling Group"
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "Maximum number of instances in Auto Scaling Group"
  type        = number
  default     = 2
}

variable "health_check_path" {
  description = "Health check path for ALB"
  type        = string
  default     = "/"
}

variable "application_port" {
  description = "Port on which the application runs"
  type        = number
  default     = 3000
}

variable "ssl_certificate_arn" {
  description = "ARN of SSL certificate for ALB"
  type        = string
  default     = null
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
  default     = null
}

# React Hosting Variables
variable "enable_static_hosting" {
  description = "Enable static hosting with S3 and CloudFront"
  type        = bool
  default     = true
}

variable "react_domain_name" {
  description = "Domain name for React application"
  type        = string
  default     = null
}

variable "react_ssl_certificate_arn" {
  description = "ARN of SSL certificate for React hosting"
  type        = string
  default     = null
}

variable "enable_serverless_hosting" {
  description = "Enable serverless hosting with ECS"
  type        = bool
  default     = false
}

variable "serverless_cpu" {
  description = "CPU units for serverless container"
  type        = number
  default     = 256
}

variable "serverless_memory" {
  description = "Memory for serverless container"
  type        = number
  default     = 512
}

variable "serverless_min_capacity" {
  description = "Minimum capacity for serverless hosting"
  type        = number
  default     = 1
}

variable "serverless_max_capacity" {
  description = "Maximum capacity for serverless hosting"
  type        = number
  default     = 2
}

# Database Backup Variables (Phase II)
variable "backup_retention_days" {
  description = "Number of days to retain automated backups"
  type        = number
  default     = 7
}

variable "backup_schedule_expression" {
  description = "Schedule expression for automated backups"
  type        = string
  default     = "cron(0 2 * * ? *)" # Daily at 2 AM UTC
}

variable "enable_cross_region_backup" {
  description = "Enable cross-region backup replication"
  type        = bool
  default     = false
}

variable "backup_destination_region" {
  description = "Destination region for cross-region backups"
  type        = string
  default     = "ap-southeast-2"
}

variable "enable_point_in_time_recovery" {
  description = "Enable point-in-time recovery for backups"
  type        = bool
  default     = false
}

# Monitoring and Alerting Variables (Phase II)
variable "cpu_threshold_high" {
  description = "CPU threshold for high utilization alarm"
  type        = number
  default     = 80
}

variable "memory_threshold_high" {
  description = "Memory threshold for high utilization alarm"
  type        = number
  default     = 80
}

variable "disk_threshold_high" {
  description = "Disk threshold for high utilization alarm"
  type        = number
  default     = 80
}

variable "alb_response_time_threshold" {
  description = "ALB response time threshold in seconds"
  type        = number
  default     = 2
}

variable "alb_5xx_threshold" {
  description = "ALB 5xx error threshold"
  type        = number
  default     = 10
}

variable "enable_custom_metrics" {
  description = "Enable custom CloudWatch metrics"
  type        = bool
  default     = true
}

variable "enable_log_insights" {
  description = "Enable CloudWatch Log Insights queries"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatch log retention period in days"
  type        = number
  default     = 14
}

# Cost Optimization Variables (Phase II)
variable "monthly_budget_limit" {
  description = "Monthly budget limit in USD"
  type        = number
  default     = 200 # Lower budget for staging
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

variable "service_budgets" {
  description = "Service-specific budget configurations"
  type = map(object({
    service_name    = string
    limit           = number
    alert_threshold = number
  }))
  default = {
    ec2 = {
      service_name    = "Amazon Elastic Compute Cloud - Compute"
      limit           = 50
      alert_threshold = 80
    }
    s3 = {
      service_name    = "Amazon Simple Storage Service"
      limit           = 25
      alert_threshold = 80
    }
  }
}

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
  default = [
    "Amazon Elastic Compute Cloud - Compute",
    "Amazon Simple Storage Service",
    "Amazon Relational Database Service"
  ]
}

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

variable "enable_ri_recommendations" {
  description = "Enable Reserved Instance purchase recommendations"
  type        = bool
  default     = false # Disabled for staging
}

variable "ri_payment_option" {
  description = "Reserved Instance payment option"
  type        = string
  default     = "PARTIAL_UPFRONT"
}

variable "ri_term_years" {
  description = "Reserved Instance term in years"
  type        = string
  default     = "ONE_YEAR"
}

variable "enable_s3_lifecycle_recommendations" {
  description = "Enable S3 lifecycle policy recommendations"
  type        = bool
  default     = true
}

variable "s3_ia_transition_days" {
  description = "Days after which objects transition to IA storage"
  type        = number
  default     = 30
}

variable "s3_glacier_transition_days" {
  description = "Days after which objects transition to Glacier"
  type        = number
  default     = 90
}

# Compliance Monitoring Variables (Phase II)
variable "enable_config_rules" {
  description = "Enable AWS Config rules for compliance monitoring"
  type        = bool
  default     = true
}

variable "enable_security_hub_standards" {
  description = "Enable Security Hub compliance standards"
  type        = bool
  default     = true
}

variable "enable_custom_compliance" {
  description = "Enable custom compliance checks"
  type        = bool
  default     = true
}

variable "compliance_notification_email" {
  description = "Email address for compliance notifications"
  type        = string
  default     = null
}

variable "compliance_check_schedule" {
  description = "Schedule expression for compliance checks"
  type        = string
  default     = "cron(0 8 * * MON *)" # Every Monday at 8 AM UTC
}

variable "cis_benchmark_version" {
  description = "CIS Benchmark version to use"
  type        = string
  default     = "1.2.0"
}

variable "aws_foundational_standard" {
  description = "Enable AWS Foundational Security Standard"
  type        = bool
  default     = true
}

variable "pci_dss_standard" {
  description = "Enable PCI DSS compliance standard"
  type        = bool
  default     = false
}

variable "custom_compliance_rules" {
  description = "Custom compliance rules configuration"
  type = map(object({
    rule_name       = string
    description     = string
    compliance_type = string
    resource_types  = list(string)
    evaluation_mode = string
  }))
  default = {
    encryption_check = {
      rule_name       = "s3-bucket-encryption-enabled"
      description     = "Checks if S3 buckets have encryption enabled"
      compliance_type = "NON_COMPLIANT"
      resource_types  = ["AWS::S3::Bucket"]
      evaluation_mode = "DETECTIVE"
    }
  }
}