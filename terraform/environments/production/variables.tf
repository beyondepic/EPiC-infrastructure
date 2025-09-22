# Production Environment Variables

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "ap-southeast-4"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
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
    Environment = "production"
    ManagedBy   = "Terraform"
    Repository  = "EPiC-infrastructure"
  }
}

# Notification Variables
variable "notification_email" {
  description = "Email address for infrastructure notifications"
  type        = string
  default     = ""
}

variable "application_email" {
  description = "Email address for application notifications (OTP, user alerts)"
  type        = string
  default     = ""
}

variable "slack_webhook_url" {
  description = "Slack webhook URL for notifications"
  type        = string
  default     = ""
  sensitive   = true
}

# Production-specific Variables
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16" # Standard CIDR for production
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium" # Larger instances for production
}

variable "min_size" {
  description = "Minimum number of instances in Auto Scaling Group"
  type        = number
  default     = 2 # High availability
}

variable "max_size" {
  description = "Maximum number of instances in Auto Scaling Group"
  type        = number
  default     = 6
}

variable "desired_capacity" {
  description = "Desired number of instances in Auto Scaling Group"
  type        = number
  default     = 2
}

# Database Variables
variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.small" # Production-sized database
}

variable "db_allocated_storage" {
  description = "Allocated storage for RDS instance in GB"
  type        = number
  default     = 100
}

variable "db_max_allocated_storage" {
  description = "Maximum allocated storage for RDS auto scaling in GB"
  type        = number
  default     = 1000
}

variable "db_backup_retention_period" {
  description = "Number of days to retain automated backups"
  type        = number
  default     = 30 # Longer retention for production
}

variable "db_backup_window" {
  description = "Preferred backup window"
  type        = string
  default     = "03:00-04:00" # Early morning UTC
}

variable "db_maintenance_window" {
  description = "Preferred maintenance window"
  type        = string
  default     = "sun:04:00-sun:05:00" # Sunday early morning UTC
}

# Security Variables
variable "enable_deletion_protection" {
  description = "Enable deletion protection for critical resources"
  type        = bool
  default     = true
}

variable "enable_point_in_time_recovery" {
  description = "Enable point-in-time recovery for RDS"
  type        = bool
  default     = true
}

variable "enable_performance_insights" {
  description = "Enable Performance Insights for RDS"
  type        = bool
  default     = true
}

# Cost Management
variable "budget_limit" {
  description = "Monthly budget limit in USD"
  type        = number
  default     = 1000 # Higher budget for production
}

# Monitoring and Alerting
variable "enable_detailed_monitoring" {
  description = "Enable detailed CloudWatch monitoring"
  type        = bool
  default     = true
}

variable "alarm_cpu_threshold" {
  description = "CPU utilization threshold for alarms"
  type        = number
  default     = 80
}

variable "alarm_memory_threshold" {
  description = "Memory utilization threshold for alarms"
  type        = number
  default     = 85
}

variable "alarm_disk_threshold" {
  description = "Disk utilization threshold for alarms"
  type        = number
  default     = 85
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
  default     = 2 # High availability for production
}

variable "max_capacity" {
  description = "Maximum number of instances in Auto Scaling Group"
  type        = number
  default     = 6
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
  default     = 512 # Higher for production
}

variable "serverless_memory" {
  description = "Memory for serverless container"
  type        = number
  default     = 1024 # Higher for production
}

variable "serverless_min_capacity" {
  description = "Minimum capacity for serverless hosting"
  type        = number
  default     = 2 # High availability
}

variable "serverless_max_capacity" {
  description = "Maximum capacity for serverless hosting"
  type        = number
  default     = 10 # Higher scale for production
}

# Database Backup Variables (Phase II)
variable "backup_retention_days" {
  description = "Number of days to retain automated backups"
  type        = number
  default     = 30 # Longer retention for production
}

variable "backup_schedule_expression" {
  description = "Schedule expression for automated backups"
  type        = string
  default     = "cron(0 2 * * ? *)" # Daily at 2 AM UTC
}

variable "enable_cross_region_backup" {
  description = "Enable cross-region backup replication"
  type        = bool
  default     = true # Enabled for production
}

variable "backup_destination_region" {
  description = "Destination region for cross-region backups"
  type        = string
  default     = "ap-southeast-2"
}

# Monitoring and Alerting Variables (Phase II)
variable "cpu_threshold_high" {
  description = "CPU threshold for high utilization alarm"
  type        = number
  default     = 70 # Lower threshold for production
}

variable "memory_threshold_high" {
  description = "Memory threshold for high utilization alarm"
  type        = number
  default     = 75 # Lower threshold for production
}

variable "disk_threshold_high" {
  description = "Disk threshold for high utilization alarm"
  type        = number
  default     = 80 # Lower threshold for production
}

variable "alb_response_time_threshold" {
  description = "ALB response time threshold in seconds"
  type        = number
  default     = 1 # Stricter for production
}

variable "alb_5xx_threshold" {
  description = "ALB 5xx error threshold"
  type        = number
  default     = 5 # Stricter for production
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
  default     = 30 # Longer retention for production
}

# Cost Optimization Variables (Phase II)
variable "monthly_budget_limit" {
  description = "Monthly budget limit in USD"
  type        = number
  default     = 1000 # Higher budget for production
}

variable "budget_alert_threshold" {
  description = "Budget alert threshold percentage"
  type        = number
  default     = 70 # Earlier warning for production
}

variable "budget_forecast_threshold" {
  description = "Budget forecast alert threshold percentage"
  type        = number
  default     = 90 # Earlier forecast warning
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
      limit           = 300
      alert_threshold = 70
    }
    s3 = {
      service_name    = "Amazon Simple Storage Service"
      limit           = 100
      alert_threshold = 70
    }
    rds = {
      service_name    = "Amazon Relational Database Service"
      limit           = 200
      alert_threshold = 70
    }
  }
}

variable "anomaly_threshold_amount" {
  description = "Cost anomaly threshold amount in USD"
  type        = number
  default     = 50 # Higher threshold for production
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
    "Amazon Relational Database Service",
    "Amazon CloudFront",
    "AWS Lambda",
    "Amazon Virtual Private Cloud"
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
  default     = "cron(0 8 * * MON *)" # Every Monday at 8 AM UTC
}

variable "recommendation_cost_threshold" {
  description = "Minimum monthly savings threshold for recommendations (USD)"
  type        = number
  default     = 25 # Higher threshold for production
}

variable "enable_ri_recommendations" {
  description = "Enable Reserved Instance purchase recommendations"
  type        = bool
  default     = true # Enabled for production
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
  default     = "cron(0 6 * * MON,THU *)" # Monday and Thursday at 6 AM UTC (more frequent for production)
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
  default     = true # Enabled for production if needed
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
    backup_enabled = {
      rule_name       = "rds-backup-enabled"
      description     = "Checks if RDS instances have automated backups enabled"
      compliance_type = "NON_COMPLIANT"
      resource_types  = ["AWS::RDS::DBInstance"]
      evaluation_mode = "DETECTIVE"
    }
  }
}