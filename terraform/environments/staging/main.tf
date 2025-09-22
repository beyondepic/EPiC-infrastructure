# Staging Environment Configuration
# This environment is used for testing infrastructure changes before production

# Data source to get shared networking outputs
data "terraform_remote_state" "shared" {
  backend = "s3"
  config = {
    bucket = "${var.project_name}-terraform-state"
    key    = "shared/terraform.tfstate"
    region = var.aws_region
  }
}

# Web Application Module
module "web_application" {
  source = "../../modules/web-application"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = data.terraform_remote_state.shared.outputs.vpc_id
  subnet_ids   = data.terraform_remote_state.shared.outputs.private_subnet_ids

  instance_type     = var.instance_type
  min_capacity      = var.min_capacity
  max_capacity      = var.max_capacity
  desired_capacity  = var.desired_capacity
  health_check_path = var.health_check_path
  application_port  = var.application_port

  ssl_certificate_arn = var.ssl_certificate_arn
  domain_name         = var.domain_name

  additional_tags = var.additional_tags
}

# React Hosting Module
module "react_hosting" {
  source = "../../modules/react-hosting"

  project_name = var.project_name
  environment  = var.environment

  # Static hosting configuration
  enable_static_hosting = var.enable_static_hosting
  domain_name           = var.react_domain_name
  ssl_certificate_arn   = var.react_ssl_certificate_arn

  # Serverless hosting configuration
  enable_serverless_hosting = var.enable_serverless_hosting
  vpc_id                    = data.terraform_remote_state.shared.outputs.vpc_id
  subnet_ids                = data.terraform_remote_state.shared.outputs.private_subnet_ids
  alb_security_group_id     = module.web_application.alb_security_group_id

  serverless_cpu          = var.serverless_cpu
  serverless_memory       = var.serverless_memory
  serverless_min_capacity = var.serverless_min_capacity
  serverless_max_capacity = var.serverless_max_capacity

  additional_tags = var.additional_tags
}

# Database Backup Module (Phase II)
module "database_backup" {
  source = "../../modules/database-backup"

  project_name = var.project_name
  environment  = var.environment

  backup_retention_days         = var.backup_retention_days
  backup_schedule_expression    = var.backup_schedule_expression
  enable_cross_region_backup    = var.enable_cross_region_backup
  backup_destination_region     = var.backup_destination_region
  enable_point_in_time_recovery = var.enable_point_in_time_recovery

  notification_email = var.notification_email
  sns_topic_arn      = data.terraform_remote_state.shared.outputs.notification_topic_arn

  additional_tags = var.additional_tags
}

# Monitoring and Alerting Module (Phase II)
module "monitoring_alerting" {
  source = "../../modules/monitoring-alerting"

  project_name = var.project_name
  environment  = var.environment

  # Infrastructure monitoring
  autoscaling_group_name = module.web_application.autoscaling_group_name
  alb_arn                = module.web_application.alb_arn
  alb_target_group_arn   = module.web_application.alb_target_group_arn

  # CloudFront monitoring
  cloudfront_distribution_id = module.react_hosting.cloudfront_distribution_id

  # Notification configuration
  notification_email = var.notification_email
  sns_topic_arn      = data.terraform_remote_state.shared.outputs.notification_topic_arn

  # Thresholds
  cpu_threshold_high          = var.cpu_threshold_high
  memory_threshold_high       = var.memory_threshold_high
  disk_threshold_high         = var.disk_threshold_high
  alb_response_time_threshold = var.alb_response_time_threshold
  alb_5xx_threshold           = var.alb_5xx_threshold

  enable_custom_metrics = var.enable_custom_metrics
  enable_log_insights   = var.enable_log_insights
  log_retention_days    = var.log_retention_days

  additional_tags = var.additional_tags
}

# Cost Optimization Module (Phase II)
module "cost_optimization" {
  source = "../../modules/cost-optimization"

  project_name = var.project_name
  environment  = var.environment

  # Budget configuration
  monthly_budget_limit      = var.monthly_budget_limit
  budget_alert_threshold    = var.budget_alert_threshold
  budget_forecast_threshold = var.budget_forecast_threshold
  notification_emails       = var.notification_emails
  notification_topic_arn    = data.terraform_remote_state.shared.outputs.notification_topic_arn

  # Service budgets
  service_budgets = var.service_budgets

  # Cost anomaly detection
  anomaly_threshold_amount = var.anomaly_threshold_amount
  cost_anomaly_email       = var.cost_anomaly_email
  monitored_services       = var.monitored_services

  # Cost optimization features
  enable_cost_recommendations   = var.enable_cost_recommendations
  cost_optimization_schedule    = var.cost_optimization_schedule
  recommendation_cost_threshold = var.recommendation_cost_threshold

  # Reserved Instance recommendations
  enable_ri_recommendations = var.enable_ri_recommendations
  ri_payment_option         = var.ri_payment_option
  ri_term_years             = var.ri_term_years

  # S3 optimization
  enable_s3_lifecycle_recommendations = var.enable_s3_lifecycle_recommendations
  s3_ia_transition_days               = var.s3_ia_transition_days
  s3_glacier_transition_days          = var.s3_glacier_transition_days

  additional_tags = var.additional_tags
}

# Compliance Monitoring Module (Phase II)
module "compliance_monitoring" {
  source = "../../modules/compliance-monitoring"

  project_name = var.project_name
  environment  = var.environment

  # Compliance configuration
  enable_config_rules           = var.enable_config_rules
  enable_security_hub_standards = var.enable_security_hub_standards
  enable_custom_compliance      = var.enable_custom_compliance

  # Notification configuration
  compliance_notification_email = var.compliance_notification_email
  sns_topic_arn                 = data.terraform_remote_state.shared.outputs.notification_topic_arn

  # Schedule for compliance checks
  compliance_check_schedule = var.compliance_check_schedule

  # Compliance standards
  cis_benchmark_version     = var.cis_benchmark_version
  aws_foundational_standard = var.aws_foundational_standard
  pci_dss_standard          = var.pci_dss_standard

  # Custom compliance rules
  custom_compliance_rules = var.custom_compliance_rules

  additional_tags = var.additional_tags
}