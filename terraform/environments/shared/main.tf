# Shared Environment Configuration
# This environment contains shared infrastructure resources

# Shared Networking Module
module "shared_networking" {
  source = "../../modules/shared-networking"

  project_name = var.project_name
  environment  = var.environment
  vpc_cidr     = var.vpc_cidr

  public_subnet_count   = var.public_subnet_count
  private_subnet_count  = var.private_subnet_count
  database_subnet_count = var.database_subnet_count

  enable_nat_gateway = var.enable_nat_gateway
  nat_gateway_count  = var.nat_gateway_count
  enable_flow_logs   = var.enable_flow_logs

  additional_tags = var.additional_tags
}

# Security Baseline Module
module "security_baseline" {
  source = "../../modules/security-baseline"

  project_name = var.project_name
  environment  = var.environment

  enable_config                   = var.enable_config
  enable_guardduty                = var.enable_guardduty
  enable_security_hub             = var.enable_security_hub
  enable_iam_password_policy      = var.enable_iam_password_policy
  guardduty_s3_protection         = var.guardduty_s3_protection
  guardduty_kubernetes_protection = var.guardduty_kubernetes_protection
  guardduty_malware_protection    = var.guardduty_malware_protection

  additional_tags = var.additional_tags
}

# SNS Topics for Cross-Project Notifications
module "shared_notifications" {
  source = "../../modules/sns-notifications"

  project_name = var.project_name
  environment  = var.environment

  notification_email         = var.notification_email
  slack_webhook_url          = var.slack_webhook_url
  enable_slack_notifications = var.enable_slack_notifications

  additional_tags = var.additional_tags
}