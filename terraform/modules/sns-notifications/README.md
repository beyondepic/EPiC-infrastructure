# SNS Notifications Module

This Terraform module creates AWS SNS topics and notification infrastructure for EPiC project applications and infrastructure monitoring.

## Features

- **Dual Notification Topics**: Separate topics for infrastructure and application notifications
- **Email Notifications**: Configurable email subscriptions for both topics
- **Slack Integration**: Optional Lambda-based Slack webhook notifications
- **Cross-Service Access**: Proper IAM policies for CloudWatch and Backup services
- **Configurable Retention**: Customizable message and log retention policies

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   CloudWatch    │    │   Backup Service │    │   Application   │
│    Alarms       │    │                  │    │    (Django)     │
└─────────┬───────┘    └─────────┬────────┘    └─────────┬───────┘
          │                      │                       │
          ▼                      ▼                       ▼
┌─────────────────────────────────────────────────────────────────┐
│                        SNS Topics                              │
│  ┌─────────────────┐              ┌─────────────────────────┐   │
│  │ Infrastructure  │              │      Application        │   │
│  │  Notifications  │              │     Notifications       │   │
│  └─────────────────┘              └─────────────────────────┘   │
└─────────┬───────────────────────────────────┬───────────────────┘
          │                                   │
          ▼                                   ▼
┌─────────────────┐              ┌─────────────────────────────┐
│     Email       │              │      Lambda Function        │
│  Subscriptions  │              │    (Slack Integration)      │
└─────────────────┘              └─────────────────────────────┘
```

## Usage

### Basic Usage

```hcl
module "sns_notifications" {
  source = "../../modules/sns-notifications"

  aws_region           = "ap-southeast-4"
  environment          = "production"
  project_name         = "epic"
  notification_email   = "admin@beyondepic.com"
  application_email    = "alerts@beyondepic.com"

  common_tags = {
    Project     = "EPiC Infrastructure"
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}
```

### With Slack Integration

```hcl
module "sns_notifications" {
  source = "../../modules/sns-notifications"

  aws_region           = "ap-southeast-4"
  environment          = "production"
  project_name         = "epic"
  notification_email   = "admin@beyondepic.com"
  application_email    = "alerts@beyondepic.com"
  slack_webhook_url    = var.slack_webhook_url  # Sensitive variable

  # Optional: Customize Lambda configuration
  lambda_timeout       = 60
  lambda_memory_size   = 256
  log_retention_days   = 30

  common_tags = {
    Project     = "EPiC Infrastructure"
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}
```

## Input Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| aws_region | AWS region for resources | `string` | n/a | yes |
| environment | Environment name | `string` | n/a | yes |
| project_name | Name of the project | `string` | n/a | yes |
| common_tags | Common tags to apply to all resources | `map(string)` | `{}` | no |
| notification_email | Email for infrastructure notifications | `string` | `""` | no |
| application_email | Email for application notifications | `string` | `""` | no |
| slack_webhook_url | Slack webhook URL | `string` | `""` | no |
| lambda_timeout | Lambda timeout in seconds | `number` | `30` | no |
| lambda_memory_size | Lambda memory in MB | `number` | `128` | no |
| log_retention_days | CloudWatch log retention days | `number` | `14` | no |

## Output Values

| Name | Description |
|------|-------------|
| infrastructure_topic_arn | ARN of infrastructure notifications topic |
| infrastructure_topic_name | Name of infrastructure notifications topic |
| application_topic_arn | ARN of application notifications topic |
| application_topic_name | Name of application notifications topic |
| slack_notifier_function_arn | ARN of Slack Lambda function (if enabled) |
| email_subscriptions_pending | List of email subscriptions needing confirmation |

## Integration Examples

### Django Application Integration

Add to your Django settings:

```python
# SNS Configuration
AWS_SNS_REGION = 'ap-southeast-4'
AWS_SNS_APPLICATION_TOPIC_ARN = 'arn:aws:sns:ap-southeast-4:123456789012:epic-production-app-notifications'

# Email backend using SNS
EMAIL_BACKEND = 'django_ses.SESBackend'
AWS_SES_REGION_NAME = 'ap-southeast-4'
```

Use in Django views for OTP:

```python
import boto3

def send_otp_notification(user_email, otp_code):
    sns = boto3.client('sns', region_name='ap-southeast-4')
    message = f"Your EPiC verification code is: {otp_code}"

    sns.publish(
        TopicArn=settings.AWS_SNS_APPLICATION_TOPIC_ARN,
        Subject="EPiC Verification Code",
        Message=message
    )
```

### CloudWatch Alarm Integration

```hcl
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "epic-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = [module.sns_notifications.infrastructure_topic_arn]

  dimensions = {
    InstanceId = aws_instance.web.id
  }
}
```

### Backup Job Integration

```hcl
resource "aws_backup_plan" "database_backup" {
  name = "epic-database-backup"

  rule {
    rule_name         = "daily_backup"
    target_vault_name = aws_backup_vault.database.name
    schedule          = "cron(0 5 ? * * *)"

    recovery_point_tags = {
      Environment = var.environment
    }

    lifecycle {
      cold_storage_after = 30
      delete_after       = 120
    }
  }
}

# Backup notifications
resource "aws_backup_notification_plan" "database_backup_notifications" {
  backup_vault_name = aws_backup_vault.database.name

  backup_vault_events = [
    "BACKUP_JOB_COMPLETED",
    "BACKUP_JOB_FAILED",
    "RESTORE_JOB_COMPLETED",
    "RESTORE_JOB_FAILED"
  ]

  sns_topic_arn = module.sns_notifications.infrastructure_topic_arn
}
```

## Cost Considerations

- **SNS Topics**: $0.50 per 1 million requests
- **Email Notifications**: $2.00 per 100,000 notifications
- **Lambda Function**: Minimal cost for short-running functions
- **CloudWatch Logs**: $0.50 per GB ingested

Expected monthly cost for typical usage: $2-5

## Security Features

- **Topic Policies**: Restrict access to specific AWS services
- **Lambda IAM Role**: Minimal required permissions
- **Sensitive Variables**: Slack webhook URL marked as sensitive
- **Cross-Service Integration**: Proper service-to-service authentication

## Requirements

- AWS Provider ~> 5.0
- Terraform >= 1.6
- Valid email addresses for subscriptions
- Slack webhook URL (optional, for Slack integration)

## Notes

- Email subscriptions require manual confirmation
- Slack integration uses Lambda function with Python 3.11 runtime
- Topics support cross-region access for multi-region deployments
- All resources are tagged for cost tracking and management