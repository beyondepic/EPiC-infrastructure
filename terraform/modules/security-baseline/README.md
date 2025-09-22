# Security Baseline Module

This Terraform module establishes a comprehensive security foundation for AWS environments, implementing security best practices and compliance requirements across multiple AWS security services.

## Features

### Core Security Services
- **AWS CloudTrail** - Comprehensive API logging and audit trail
- **AWS Config** - Configuration compliance monitoring and drift detection
- **Amazon GuardDuty** - Intelligent threat detection and behavioral analysis
- **AWS Security Hub** - Centralized security findings management
- **AWS CloudWatch** - Security event monitoring and alerting

### Identity & Access Management
- **IAM Roles** - Least privilege roles for EC2 and Lambda services
- **IAM Policies** - Custom policies following security best practices
- **Instance Profiles** - Secure service-to-service authentication
- **Cross-Account Roles** - Secure multi-account access patterns

### Encryption & Key Management
- **AWS KMS** - Customer-managed encryption keys
- **Encryption at Rest** - S3, EBS, and RDS encryption
- **Encryption in Transit** - TLS 1.2+ enforcement
- **Key Rotation** - Automated key rotation policies

### Compliance & Auditing
- **CIS Benchmarks** - Industry standard security configurations
- **SOC 2 Controls** - Type II compliance requirements
- **Data Residency** - Region-specific data handling
- **Audit Logging** - Comprehensive activity tracking

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Security Baseline                        │
├─────────────────────────────────────────────────────────────┤
│  CloudTrail  │  Config  │  GuardDuty  │  Security Hub      │
├─────────────────────────────────────────────────────────────┤
│              IAM Roles & Policies                           │
├─────────────────────────────────────────────────────────────┤
│                   KMS Encryption                            │
├─────────────────────────────────────────────────────────────┤
│              CloudWatch Monitoring                          │
└─────────────────────────────────────────────────────────────┘
```

## Usage

### Basic Example

```hcl
module "security_baseline" {
  source = "../../modules/security-baseline"

  # Required Variables
  project_name = "nestedphoenix"
  environment  = "production"

  # Optional Configuration
  enable_guardduty    = true
  enable_config       = true
  enable_security_hub = true

  cloudtrail_retention_days = 90
  config_retention_days     = 90

  additional_tags = {
    Compliance = "SOC2"
    Owner     = "Security Team"
  }
}
```

### Advanced Example with Custom Configuration

```hcl
module "security_baseline" {
  source = "../../modules/security-baseline"

  # Required Variables
  project_name = "nestedphoenix"
  environment  = "production"

  # CloudTrail Configuration
  enable_cloudtrail         = true
  cloudtrail_retention_days = 365
  enable_log_file_validation = true
  enable_cloudtrail_insights = true

  # Config Configuration
  enable_config             = true
  config_retention_days     = 365
  enable_config_rules       = true
  config_delivery_frequency = "Daily"

  # GuardDuty Configuration
  enable_guardduty          = true
  guardduty_finding_format  = "JSON"
  enable_malware_protection = true
  enable_s3_protection      = true

  # Security Hub Configuration
  enable_security_hub       = true
  security_hub_standards = [
    "aws-foundational-security-standard",
    "cis-aws-foundations-benchmark",
    "pci-dss"
  ]

  # KMS Configuration
  kms_key_deletion_window   = 30
  enable_key_rotation      = true

  # IAM Configuration
  password_policy = {
    minimum_password_length        = 14
    require_uppercase_characters   = true
    require_lowercase_characters   = true
    require_numbers               = true
    require_symbols               = true
    allow_users_to_change_password = true
    max_password_age              = 90
    password_reuse_prevention     = 12
  }

  # Additional Tags
  additional_tags = {
    Compliance    = "SOC2-PCI-DSS"
    Owner        = "Security Team"
    Environment  = "production"
    CostCenter   = "Security"
  }
}
```

## Variables

### Required Variables

| Name | Type | Description |
|------|------|-------------|
| `project_name` | `string` | Name of the project |
| `environment` | `string` | Environment name (shared, staging, production) |

### CloudTrail Configuration

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `enable_cloudtrail` | `bool` | `true` | Enable AWS CloudTrail |
| `cloudtrail_retention_days` | `number` | `90` | CloudTrail log retention in days |
| `enable_log_file_validation` | `bool` | `true` | Enable CloudTrail log file validation |
| `enable_cloudtrail_insights` | `bool` | `false` | Enable CloudTrail Insights for unusual activity |
| `cloudtrail_s3_bucket_name` | `string` | `null` | Custom S3 bucket for CloudTrail logs |

### Config Configuration

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `enable_config` | `bool` | `true` | Enable AWS Config |
| `config_retention_days` | `number` | `90` | Config history retention in days |
| `enable_config_rules` | `bool` | `true` | Enable Config compliance rules |
| `config_delivery_frequency` | `string` | `"Daily"` | Config delivery frequency |

### GuardDuty Configuration

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `enable_guardduty` | `bool` | `true` | Enable Amazon GuardDuty |
| `guardduty_finding_format` | `string` | `"JSON"` | GuardDuty finding publishing format |
| `enable_malware_protection` | `bool` | `true` | Enable GuardDuty malware protection |
| `enable_s3_protection` | `bool` | `true` | Enable GuardDuty S3 protection |

### Security Hub Configuration

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `enable_security_hub` | `bool` | `true` | Enable AWS Security Hub |
| `security_hub_standards` | `list(string)` | `["aws-foundational-security-standard"]` | Security standards to enable |

### KMS Configuration

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `kms_key_deletion_window` | `number` | `30` | KMS key deletion window in days |
| `enable_key_rotation` | `bool` | `true` | Enable automatic KMS key rotation |

### IAM Configuration

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `password_policy` | `object` | See below | IAM password policy configuration |

#### Default Password Policy

```hcl
password_policy = {
  minimum_password_length        = 12
  require_uppercase_characters   = true
  require_lowercase_characters   = true
  require_numbers               = true
  require_symbols               = true
  allow_users_to_change_password = true
  max_password_age              = 90
  password_reuse_prevention     = 12
}
```

## Outputs

### CloudTrail Outputs
| Name | Description |
|------|-------------|
| `cloudtrail_arn` | ARN of the CloudTrail |
| `cloudtrail_s3_bucket_name` | Name of the CloudTrail S3 bucket |
| `cloudtrail_kms_key_id` | ID of the CloudTrail KMS key |

### Config Outputs
| Name | Description |
|------|-------------|
| `config_configuration_recorder_name` | Name of the Config configuration recorder |
| `config_delivery_channel_name` | Name of the Config delivery channel |
| `config_s3_bucket_name` | Name of the Config S3 bucket |

### GuardDuty Outputs
| Name | Description |
|------|-------------|
| `guardduty_detector_id` | ID of the GuardDuty detector |
| `guardduty_detector_arn` | ARN of the GuardDuty detector |

### Security Hub Outputs
| Name | Description |
|------|-------------|
| `security_hub_account_id` | Security Hub account ID |
| `security_hub_standards_subscriptions` | List of enabled standards |

### KMS Outputs
| Name | Description |
|------|-------------|
| `kms_key_id` | ID of the customer-managed KMS key |
| `kms_key_arn` | ARN of the customer-managed KMS key |
| `kms_key_alias` | Alias of the customer-managed KMS key |

### IAM Outputs
| Name | Description |
|------|-------------|
| `ec2_instance_profile_name` | Name of the EC2 instance profile |
| `ec2_instance_profile_arn` | ARN of the EC2 instance profile |
| `lambda_execution_role_arn` | ARN of the Lambda execution role |

## Security Best Practices

### 1. Least Privilege Access
- IAM roles and policies follow the principle of least privilege
- Regular access reviews and policy auditing
- Temporary credentials preferred over long-term access keys

### 2. Encryption Everywhere
- All data encrypted at rest using customer-managed KMS keys
- TLS 1.2+ required for all data in transit
- Encryption key rotation enabled by default

### 3. Comprehensive Monitoring
- CloudTrail logs all API activity
- Config monitors configuration changes
- GuardDuty provides threat detection
- Security Hub centralizes findings

### 4. Compliance Automation
- Automated compliance checking with Config rules
- Security standards from CIS, AWS, and PCI-DSS
- Regular compliance reporting and remediation

### 5. Incident Response
- Automated alerting for security events
- Integration with SNS for notifications
- Structured logging for forensic analysis

## Compliance Standards

### Supported Standards
- **AWS Foundational Security Standard** - AWS security best practices
- **CIS AWS Foundations Benchmark** - Industry security standard
- **PCI DSS** - Payment card industry compliance
- **SOC 2 Type II** - Service organization controls

### Compliance Features
- Automated policy enforcement
- Continuous compliance monitoring
- Audit trail generation
- Evidence collection and retention

## Monitoring and Alerting

### CloudWatch Integration
```hcl
# Example CloudWatch alarm for GuardDuty findings
resource "aws_cloudwatch_metric_alarm" "guardduty_findings" {
  alarm_name          = "${var.project_name}-${var.environment}-guardduty-findings"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name        = "FindingCount"
  namespace          = "AWS/GuardDuty"
  period             = "300"
  statistic          = "Sum"
  threshold          = "0"
  alarm_description  = "This metric monitors GuardDuty findings"
  alarm_actions      = [aws_sns_topic.security_alerts.arn]
}
```

### SNS Integration
The module can be integrated with the `sns-notifications` module for security alerting:

```hcl
module "security_notifications" {
  source = "../../modules/sns-notifications"

  project_name = var.project_name
  environment  = var.environment

  notification_email = "security-team@company.com"
  slack_webhook_url  = var.slack_webhook_url
}

# Reference SNS topic in security baseline
security_notifications_topic_arn = module.security_notifications.email_topic_arn
```

## Cost Optimization

### Cost Considerations
- CloudTrail data events can generate significant costs
- Config rule evaluations are charged per evaluation
- GuardDuty pricing based on data volume analyzed
- KMS key usage charges apply

### Cost Optimization Tips
1. **Selective Data Events** - Only enable data events for critical resources
2. **Log Retention** - Set appropriate retention periods for logs
3. **Regional Deployment** - Deploy only in required regions
4. **Resource Filtering** - Use Config rules selectively

## Troubleshooting

### Common Issues

1. **CloudTrail Not Logging**
   - Check S3 bucket permissions
   - Verify KMS key permissions
   - Ensure CloudTrail is enabled in the correct region

2. **Config Rules Failing**
   - Verify IAM permissions for Config service
   - Check resource types are supported
   - Review Config rule parameters

3. **GuardDuty No Findings**
   - GuardDuty requires 7-14 days to establish baselines
   - Check data sources are enabled
   - Verify network and DNS logging

4. **Security Hub Import Errors**
   - Ensure all enabled standards are supported in the region
   - Check Security Hub service permissions
   - Verify integration with other AWS security services

### Monitoring Health

Monitor the security baseline using:
- CloudWatch dashboards for service status
- Config compliance dashboard
- Security Hub findings dashboard
- Cost and usage reports

## Dependencies

This module requires:
- AWS provider with appropriate permissions
- S3 buckets for log storage (created automatically)
- KMS keys for encryption (created automatically)

## Examples

See the `examples/` directory for complete working examples:
- `basic-security/` - Basic security baseline setup
- `enterprise-security/` - Enterprise-grade security configuration
- `compliance-focused/` - PCI-DSS and SOC 2 compliant setup

## Version History

- **v2.0.0** - Enhanced compliance support and Security Hub integration
- **v1.2.0** - Added GuardDuty malware protection and S3 monitoring
- **v1.1.0** - Added Config rules and CloudTrail insights
- **v1.0.0** - Initial implementation with core security services