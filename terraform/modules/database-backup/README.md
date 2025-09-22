# Database Backup Module

This Terraform module provides automated database backup and disaster recovery capabilities for RDS instances with S3 storage, Lambda-based automation, and comprehensive monitoring.

## Features

### Automated Backup System
- **RDS Snapshot Management** - Automated daily snapshots with retention policies
- **S3 Backup Storage** - Encrypted backup storage with lifecycle management
- **Cross-Region Replication** - Optional cross-region backup replication
- **Point-in-Time Recovery** - Configurable backup windows and retention

### Lambda Automation
- **Backup Orchestration** - Lambda function for backup workflow management
- **Cleanup Automation** - Automatic cleanup of expired backups
- **Notification System** - Success and failure notifications via SNS
- **Error Handling** - Comprehensive error handling and retry logic

### Monitoring & Alerting
- **CloudWatch Metrics** - Backup success/failure tracking
- **Custom Dashboards** - Backup status visualization
- **SNS Integration** - Real-time backup status notifications
- **Audit Logging** - Comprehensive backup activity logging

### Security Features
- **Encryption at Rest** - S3 bucket encryption with customer-managed KMS keys
- **IAM Least Privilege** - Minimal required permissions for backup operations
- **VPC Endpoints** - Secure communication without internet access
- **Access Logging** - S3 access logging for audit trails

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Database Backup                          │
├─────────────────────────────────────────────────────────────┤
│  RDS Instance  →  Lambda Function  →  S3 Bucket            │
├─────────────────────────────────────────────────────────────┤
│              CloudWatch Monitoring                          │
├─────────────────────────────────────────────────────────────┤
│                SNS Notifications                            │
└─────────────────────────────────────────────────────────────┘
```

## Usage

### Basic Example

```hcl
module "database_backup" {
  source = "../../modules/database-backup"

  # Required Variables
  project_name = "nestedphoenix"
  environment  = "production"

  # Database Configuration
  rds_instance_ids = [
    "prod-database-1",
    "prod-database-2"
  ]

  # Backup Configuration
  backup_retention_days = 30
  backup_schedule      = "cron(0 2 * * ? *)"  # Daily at 2 AM

  # Notification
  notification_email = "dba-team@company.com"
}
```

### Advanced Example with Cross-Region Replication

```hcl
module "database_backup" {
  source = "../../modules/database-backup"

  # Required Variables
  project_name = "nestedphoenix"
  environment  = "production"

  # Database Configuration
  rds_instance_ids = [
    "prod-database-1",
    "prod-database-2",
    "prod-read-replica-1"
  ]

  # Backup Configuration
  backup_retention_days     = 90
  backup_schedule          = "cron(0 2 * * ? *)"  # Daily at 2 AM
  enable_cross_region_copy = true
  cross_region_destination = "us-west-2"

  # S3 Configuration
  s3_bucket_name           = "nestedphoenix-prod-db-backups"
  s3_storage_class         = "STANDARD_IA"
  enable_s3_versioning     = true
  s3_lifecycle_rules = {
    transition_to_ia_days      = 30
    transition_to_glacier_days = 90
    transition_to_deep_archive_days = 365
    expiration_days           = 2555  # 7 years
  }

  # Encryption Configuration
  kms_key_id               = module.security_baseline.kms_key_id
  enable_s3_encryption     = true

  # Lambda Configuration
  lambda_timeout          = 900  # 15 minutes
  lambda_memory_size      = 512
  lambda_runtime          = "python3.9"

  # Monitoring Configuration
  enable_cloudwatch_logs  = true
  log_retention_days      = 30
  enable_detailed_monitoring = true

  # Notification Configuration
  notification_email      = "dba-team@company.com"
  slack_webhook_url       = var.slack_webhook_url
  sns_topic_arn          = module.notifications.email_topic_arn

  # Network Configuration
  vpc_id                 = module.shared_networking.vpc_id
  subnet_ids             = module.shared_networking.private_subnet_ids
  enable_vpc_endpoints   = true

  # Additional Tags
  additional_tags = {
    Owner           = "DBA Team"
    BackupType      = "Automated"
    Compliance      = "SOX"
    RetentionPolicy = "7-years"
  }
}
```

## Variables

### Required Variables

| Name | Type | Description |
|------|------|-------------|
| `project_name` | `string` | Name of the project |
| `environment` | `string` | Environment name (staging, production) |
| `rds_instance_ids` | `list(string)` | List of RDS instance identifiers to backup |

### Backup Configuration

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `backup_retention_days` | `number` | `30` | Number of days to retain backups |
| `backup_schedule` | `string` | `"cron(0 2 * * ? *)"` | CloudWatch Events schedule expression |
| `enable_cross_region_copy` | `bool` | `false` | Enable cross-region backup copying |
| `cross_region_destination` | `string` | `null` | Destination region for cross-region copies |
| `backup_window` | `string` | `"02:00-03:00"` | Preferred backup window (UTC) |

### S3 Configuration

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `s3_bucket_name` | `string` | `null` | Custom S3 bucket name (auto-generated if null) |
| `s3_storage_class` | `string` | `"STANDARD"` | Default S3 storage class |
| `enable_s3_versioning` | `bool` | `true` | Enable S3 bucket versioning |
| `s3_lifecycle_rules` | `object` | See below | S3 lifecycle management rules |

#### Default S3 Lifecycle Rules

```hcl
s3_lifecycle_rules = {
  transition_to_ia_days           = 30
  transition_to_glacier_days      = 90
  transition_to_deep_archive_days = 365
  expiration_days                = 2555  # 7 years
}
```

### Lambda Configuration

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `lambda_timeout` | `number` | `300` | Lambda function timeout in seconds |
| `lambda_memory_size` | `number` | `256` | Lambda function memory in MB |
| `lambda_runtime` | `string` | `"python3.9"` | Lambda runtime version |
| `lambda_reserved_concurrency` | `number` | `1` | Reserved concurrency for Lambda |

### Monitoring Configuration

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `enable_cloudwatch_logs` | `bool` | `true` | Enable CloudWatch Logs for Lambda |
| `log_retention_days` | `number` | `14` | CloudWatch Logs retention period |
| `enable_detailed_monitoring` | `bool` | `false` | Enable detailed CloudWatch monitoring |

### Notification Configuration

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `notification_email` | `string` | `null` | Email address for backup notifications |
| `slack_webhook_url` | `string` | `null` | Slack webhook URL for notifications |
| `sns_topic_arn` | `string` | `null` | Existing SNS topic ARN for notifications |

### Security Configuration

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `kms_key_id` | `string` | `null` | KMS key ID for encryption (auto-generated if null) |
| `enable_s3_encryption` | `bool` | `true` | Enable S3 bucket encryption |
| `enable_s3_access_logging` | `bool` | `true` | Enable S3 access logging |

### Network Configuration

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `vpc_id` | `string` | `null` | VPC ID for Lambda function |
| `subnet_ids` | `list(string)` | `[]` | Subnet IDs for Lambda function |
| `enable_vpc_endpoints` | `bool` | `false` | Enable VPC endpoints for AWS services |

## Outputs

### S3 Outputs
| Name | Description |
|------|-------------|
| `s3_bucket_name` | Name of the backup S3 bucket |
| `s3_bucket_arn` | ARN of the backup S3 bucket |
| `s3_bucket_region` | Region of the backup S3 bucket |

### Lambda Outputs
| Name | Description |
|------|-------------|
| `lambda_function_name` | Name of the backup Lambda function |
| `lambda_function_arn` | ARN of the backup Lambda function |
| `lambda_role_arn` | ARN of the Lambda execution role |

### CloudWatch Outputs
| Name | Description |
|------|-------------|
| `cloudwatch_log_group_name` | Name of the CloudWatch Log Group |
| `cloudwatch_log_group_arn` | ARN of the CloudWatch Log Group |

### SNS Outputs
| Name | Description |
|------|-------------|
| `sns_topic_arn` | ARN of the SNS topic for notifications |
| `sns_topic_name` | Name of the SNS topic |

### KMS Outputs
| Name | Description |
|------|-------------|
| `kms_key_id` | ID of the KMS key used for encryption |
| `kms_key_arn` | ARN of the KMS key |

## Backup Process

### 1. Automated Snapshots
The module creates automated RDS snapshots based on the configured schedule:

```python
# Example Lambda function logic
def create_snapshot(rds_instance_id):
    snapshot_id = f"{rds_instance_id}-{datetime.now().strftime('%Y%m%d%H%M%S')}"

    response = rds_client.create_db_snapshot(
        DBSnapshotIdentifier=snapshot_id,
        DBInstanceIdentifier=rds_instance_id
    )

    return response['DBSnapshot']['DBSnapshotArn']
```

### 2. S3 Export (Optional)
For long-term archival, snapshots can be exported to S3:

```python
# Export snapshot to S3
def export_snapshot_to_s3(snapshot_arn, s3_bucket):
    export_task = rds_client.start_export_task(
        ExportTaskIdentifier=f"export-{snapshot_id}",
        SourceArn=snapshot_arn,
        S3BucketName=s3_bucket,
        IamRoleArn=export_role_arn,
        KmsKeyId=kms_key_id
    )

    return export_task['ExportTaskIdentifier']
```

### 3. Cleanup Process
Expired snapshots are automatically cleaned up:

```python
# Cleanup old snapshots
def cleanup_old_snapshots(retention_days):
    cutoff_date = datetime.now() - timedelta(days=retention_days)

    snapshots = rds_client.describe_db_snapshots(
        SnapshotType='manual',
        IncludeShared=False
    )

    for snapshot in snapshots['DBSnapshots']:
        if snapshot['SnapshotCreateTime'] < cutoff_date:
            rds_client.delete_db_snapshot(
                DBSnapshotIdentifier=snapshot['DBSnapshotIdentifier']
            )
```

## Monitoring and Alerting

### CloudWatch Metrics

The module creates custom CloudWatch metrics:

| Metric Name | Description | Unit |
|-------------|-------------|------|
| `BackupSuccess` | Number of successful backups | Count |
| `BackupFailure` | Number of failed backups | Count |
| `BackupDuration` | Time taken for backup | Seconds |
| `SnapshotAge` | Age of latest snapshot | Hours |

### CloudWatch Alarms

```hcl
# Example alarm for backup failures
resource "aws_cloudwatch_metric_alarm" "backup_failure" {
  alarm_name          = "${var.project_name}-${var.environment}-backup-failure"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name        = "BackupFailure"
  namespace          = "CustomMetrics/DatabaseBackup"
  period             = "300"
  statistic          = "Sum"
  threshold          = "0"
  alarm_description  = "Database backup failure detected"
  alarm_actions      = [aws_sns_topic.notifications.arn]
}
```

### Dashboard Integration

```hcl
# CloudWatch Dashboard widget
widget {
  type   = "metric"
  x      = 0
  y      = 0
  width  = 12
  height = 6

  properties = {
    metrics = [
      ["CustomMetrics/DatabaseBackup", "BackupSuccess"],
      [".", "BackupFailure"]
    ]
    period = 300
    stat   = "Sum"
    region = var.aws_region
    title  = "Database Backup Status"
  }
}
```

## Disaster Recovery

### Recovery Procedures

1. **Point-in-Time Recovery**
   ```bash
   # Restore from automated backup
   aws rds restore-db-instance-to-point-in-time \
     --target-db-instance-identifier restored-db \
     --source-db-instance-identifier original-db \
     --restore-time 2023-12-01T10:00:00.000Z
   ```

2. **Snapshot Recovery**
   ```bash
   # Restore from manual snapshot
   aws rds restore-db-instance-from-db-snapshot \
     --db-instance-identifier restored-db \
     --db-snapshot-identifier snapshot-id
   ```

3. **Cross-Region Recovery**
   ```bash
   # Copy snapshot to another region
   aws rds copy-db-snapshot \
     --source-db-snapshot-identifier arn:aws:rds:us-east-1:123456789012:snapshot:snapshot-id \
     --target-db-snapshot-identifier copied-snapshot \
     --region us-west-2
   ```

## Cost Optimization

### Cost Factors
- RDS snapshot storage costs
- S3 storage costs (varies by storage class)
- Lambda execution costs
- Data transfer costs (cross-region)

### Optimization Strategies
1. **Lifecycle Policies** - Transition to cheaper storage classes
2. **Retention Policies** - Balance compliance with cost
3. **Regional Strategy** - Minimize cross-region transfers
4. **Compression** - Use compression for S3 exports

## Security Best Practices

### 1. Encryption
- All backups encrypted using customer-managed KMS keys
- S3 bucket encryption enabled by default
- TLS 1.2+ for all data in transit

### 2. Access Control
- IAM roles with minimal required permissions
- S3 bucket policies restricting access
- VPC endpoints for secure communication

### 3. Audit and Compliance
- CloudTrail logging for all backup operations
- S3 access logging for audit trails
- Compliance with data retention requirements

## Troubleshooting

### Common Issues

1. **Backup Failures**
   - Check IAM permissions for Lambda function
   - Verify RDS instance is in available state
   - Review CloudWatch Logs for error details

2. **S3 Upload Issues**
   - Check S3 bucket permissions
   - Verify KMS key permissions
   - Check network connectivity

3. **Lambda Timeouts**
   - Increase Lambda timeout setting
   - Optimize backup process
   - Consider splitting large databases

### Monitoring Health

Monitor backup health using:
- CloudWatch dashboards
- SNS notifications
- Regular recovery testing
- Cost monitoring

## Dependencies

This module requires:
- RDS instances to backup
- S3 bucket permissions
- KMS key for encryption
- IAM roles and policies

## Examples

See the `examples/` directory for complete working examples:
- `basic-backup/` - Simple backup setup
- `enterprise-backup/` - Production backup with cross-region replication
- `compliance-backup/` - Long-term retention for compliance

## Version History

- **v2.0.0** - Fixed critical region interpolation bugs and enhanced monitoring
- **v1.2.0** - Added cross-region replication and S3 lifecycle management
- **v1.1.0** - Added CloudWatch integration and custom metrics
- **v1.0.0** - Initial implementation with basic RDS snapshot functionality