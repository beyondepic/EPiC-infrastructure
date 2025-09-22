# Database Backup Module
# Automated RDS backup solution with S3 storage and cross-region replication

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# S3 bucket for database backups
resource "aws_s3_bucket" "db_backups" {
  bucket        = "${var.project_name}-${var.environment}-db-backups-${random_string.bucket_suffix.result}"
  force_destroy = var.enable_force_destroy

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-db-backups"
      Environment = var.environment
      Module      = "database-backup"
      Purpose     = "Database Backups"
    },
    var.additional_tags
  )
}

resource "aws_s3_bucket_public_access_block" "db_backups" {
  bucket = aws_s3_bucket.db_backups.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "db_backups" {
  bucket = aws_s3_bucket.db_backups.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "db_backups" {
  bucket = aws_s3_bucket.db_backups.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.db_backup.arn
    }
    bucket_key_enabled = true
  }
}

# Lifecycle policy for backup retention
resource "aws_s3_bucket_lifecycle_configuration" "db_backups" {
  bucket = aws_s3_bucket.db_backups.id

  rule {
    id     = "db_backup_lifecycle"
    status = "Enabled"

    # Transition to IA after 30 days
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    # Transition to Glacier after 90 days
    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    # Transition to Deep Archive after 180 days
    transition {
      days          = 180
      storage_class = "DEEP_ARCHIVE"
    }

    # Delete after retention period
    expiration {
      days = var.backup_retention_days
    }

    # Clean up incomplete multipart uploads
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# Cross-region replication bucket (optional)
resource "aws_s3_bucket" "db_backups_replica" {
  count = var.enable_cross_region_replication ? 1 : 0

  provider      = aws.replica
  bucket        = "${var.project_name}-${var.environment}-db-backups-replica-${random_string.bucket_suffix.result}"
  force_destroy = var.enable_force_destroy

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-db-backups-replica"
      Environment = var.environment
      Module      = "database-backup"
      Purpose     = "Database Backup Replica"
    },
    var.additional_tags
  )
}

resource "aws_s3_bucket_versioning" "db_backups_replica" {
  count = var.enable_cross_region_replication ? 1 : 0

  provider = aws.replica
  bucket   = aws_s3_bucket.db_backups_replica[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 bucket replication configuration
resource "aws_s3_bucket_replication_configuration" "db_backups" {
  count = var.enable_cross_region_replication ? 1 : 0

  role   = aws_iam_role.replication[0].arn
  bucket = aws_s3_bucket.db_backups.id

  rule {
    id     = "db_backup_replication"
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.db_backups_replica[0].arn
      storage_class = "STANDARD_IA"

      encryption_configuration {
        replica_kms_key_id = var.replica_kms_key_id
      }
    }
  }

  depends_on = [aws_s3_bucket_versioning.db_backups]
}

# KMS key for backup encryption
resource "aws_kms_key" "db_backup" {
  description             = "KMS key for database backup encryption"
  deletion_window_in_days = var.kms_deletion_window

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow Lambda and RDS to use the key"
        Effect = "Allow"
        Principal = {
          Service = [
            "lambda.amazonaws.com",
            "rds.amazonaws.com"
          ]
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-db-backup-key"
      Environment = var.environment
      Module      = "database-backup"
    },
    var.additional_tags
  )
}

resource "aws_kms_alias" "db_backup" {
  name          = "alias/${var.project_name}-${var.environment}-db-backup"
  target_key_id = aws_kms_key.db_backup.key_id
}

# Lambda function for automated backups
resource "aws_lambda_function" "db_backup" {
  filename         = data.archive_file.db_backup_lambda.output_path
  function_name    = "${var.project_name}-${var.environment}-db-backup"
  role            = aws_iam_role.db_backup_lambda.arn
  handler         = "index.handler"
  runtime         = "python3.11"
  timeout         = 300
  source_code_hash = data.archive_file.db_backup_lambda.output_base64sha256

  environment {
    variables = {
      BACKUP_BUCKET      = aws_s3_bucket.db_backups.bucket
      KMS_KEY_ID         = aws_kms_key.db_backup.key_id
      SNS_TOPIC_ARN      = var.notification_topic_arn
      BACKUP_PREFIX      = var.backup_prefix
      RETENTION_DAYS     = var.backup_retention_days
    }
  }

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-db-backup-lambda"
      Environment = var.environment
      Module      = "database-backup"
    },
    var.additional_tags
  )
}

# Lambda function source code
data "archive_file" "db_backup_lambda" {
  type        = "zip"
  output_path = "/tmp/db_backup_lambda.zip"
  source {
    content = templatefile("${path.module}/lambda/db_backup.py", {
      region = data.aws_region.current.name
    })
    filename = "index.py"
  }
}

# EventBridge rule for scheduled backups
resource "aws_cloudwatch_event_rule" "db_backup_schedule" {
  name                = "${var.project_name}-${var.environment}-db-backup-schedule"
  description         = "Trigger database backup Lambda function"
  schedule_expression = var.backup_schedule

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-db-backup-schedule"
      Environment = var.environment
      Module      = "database-backup"
    },
    var.additional_tags
  )
}

resource "aws_cloudwatch_event_target" "db_backup_lambda" {
  rule      = aws_cloudwatch_event_rule.db_backup_schedule.name
  target_id = "DbBackupLambdaTarget"
  arn       = aws_lambda_function.db_backup.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.db_backup.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.db_backup_schedule.arn
}

# IAM role for Lambda function
resource "aws_iam_role" "db_backup_lambda" {
  name = "${var.project_name}-${var.environment}-db-backup-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-db-backup-lambda-role"
      Environment = var.environment
      Module      = "database-backup"
    },
    var.additional_tags
  )
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.db_backup_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "db_backup_lambda" {
  name = "${var.project_name}-${var.environment}-db-backup-lambda-policy"
  role = aws_iam_role.db_backup_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "rds:DescribeDBInstances",
          "rds:DescribeDBClusters",
          "rds:CreateDBSnapshot",
          "rds:CreateDBClusterSnapshot",
          "rds:DescribeDBSnapshots",
          "rds:DescribeDBClusterSnapshots",
          "rds:CopyDBSnapshot",
          "rds:CopyDBClusterSnapshot"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.db_backups.arn,
          "${aws_s3_bucket.db_backups.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = aws_kms_key.db_backup.arn
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = var.notification_topic_arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
      }
    ]
  })
}

# IAM role for S3 replication
resource "aws_iam_role" "replication" {
  count = var.enable_cross_region_replication ? 1 : 0

  name = "${var.project_name}-${var.environment}-db-backup-replication-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-db-backup-replication-role"
      Environment = var.environment
      Module      = "database-backup"
    },
    var.additional_tags
  )
}

resource "aws_iam_role_policy" "replication" {
  count = var.enable_cross_region_replication ? 1 : 0

  name = "${var.project_name}-${var.environment}-db-backup-replication-policy"
  role = aws_iam_role.replication[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl"
        ]
        Resource = "${aws_s3_bucket.db_backups.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.db_backups.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete"
        ]
        Resource = "${aws_s3_bucket.db_backups_replica[0].arn}/*"
      }
    ]
  })
}

# CloudWatch log group for Lambda
resource "aws_cloudwatch_log_group" "db_backup_lambda" {
  name              = "/aws/lambda/${aws_lambda_function.db_backup.function_name}"
  retention_in_days = var.log_retention_days

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-db-backup-lambda-logs"
      Environment = var.environment
      Module      = "database-backup"
    },
    var.additional_tags
  )
}

# Random string for unique bucket names
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}