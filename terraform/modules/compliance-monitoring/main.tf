# Compliance Monitoring Module
# Implements comprehensive compliance monitoring using AWS Config, Security Hub, and custom rules

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# AWS Config Rules for Security and Compliance
resource "aws_config_config_rule" "s3_bucket_ssl_requests_only" {
  name = "${var.project_name}-${var.environment}-s3-ssl-requests-only"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_SSL_REQUESTS_ONLY"
  }

  depends_on = [var.config_recorder_name]

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-s3-ssl-requests-only"
      Environment = var.environment
      Module      = "compliance-monitoring"
      Compliance  = "Security"
    },
    var.additional_tags
  )
}

resource "aws_config_config_rule" "s3_bucket_public_access_prohibited" {
  name = "${var.project_name}-${var.environment}-s3-public-access-prohibited"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_ACCESS_PROHIBITED"
  }

  depends_on = [var.config_recorder_name]

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-s3-public-access-prohibited"
      Environment = var.environment
      Module      = "compliance-monitoring"
      Compliance  = "Security"
    },
    var.additional_tags
  )
}

resource "aws_config_config_rule" "s3_bucket_server_side_encryption_enabled" {
  name = "${var.project_name}-${var.environment}-s3-encryption-enabled"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED"
  }

  depends_on = [var.config_recorder_name]

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-s3-encryption-enabled"
      Environment = var.environment
      Module      = "compliance-monitoring"
      Compliance  = "Security"
    },
    var.additional_tags
  )
}

resource "aws_config_config_rule" "ec2_security_group_attached_to_eni" {
  name = "${var.project_name}-${var.environment}-ec2-sg-attached"

  source {
    owner             = "AWS"
    source_identifier = "EC2_SECURITY_GROUP_ATTACHED_TO_ENI"
  }

  depends_on = [var.config_recorder_name]

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-ec2-sg-attached"
      Environment = var.environment
      Module      = "compliance-monitoring"
      Compliance  = "Security"
    },
    var.additional_tags
  )
}

resource "aws_config_config_rule" "ec2_instance_managed_by_systems_manager" {
  name = "${var.project_name}-${var.environment}-ec2-ssm-managed"

  source {
    owner             = "AWS"
    source_identifier = "EC2_INSTANCE_MANAGED_BY_SSM"
  }

  depends_on = [var.config_recorder_name]

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-ec2-ssm-managed"
      Environment = var.environment
      Module      = "compliance-monitoring"
      Compliance  = "Management"
    },
    var.additional_tags
  )
}

resource "aws_config_config_rule" "rds_storage_encrypted" {
  name = "${var.project_name}-${var.environment}-rds-encrypted"

  source {
    owner             = "AWS"
    source_identifier = "RDS_STORAGE_ENCRYPTED"
  }

  depends_on = [var.config_recorder_name]

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-rds-encrypted"
      Environment = var.environment
      Module      = "compliance-monitoring"
      Compliance  = "Security"
    },
    var.additional_tags
  )
}

resource "aws_config_config_rule" "rds_instance_public_access_check" {
  name = "${var.project_name}-${var.environment}-rds-no-public-access"

  source {
    owner             = "AWS"
    source_identifier = "RDS_INSTANCE_PUBLIC_ACCESS_CHECK"
  }

  depends_on = [var.config_recorder_name]

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-rds-no-public-access"
      Environment = var.environment
      Module      = "compliance-monitoring"
      Compliance  = "Security"
    },
    var.additional_tags
  )
}

resource "aws_config_config_rule" "iam_password_policy" {
  count = var.enable_iam_compliance_rules ? 1 : 0

  name = "${var.project_name}-${var.environment}-iam-password-policy"

  source {
    owner             = "AWS"
    source_identifier = "IAM_PASSWORD_POLICY"
  }

  input_parameters = jsonencode({
    RequireUppercaseCharacters = "true"
    RequireLowercaseCharacters = "true"
    RequireSymbols             = "true"
    RequireNumbers             = "true"
    MinimumPasswordLength      = var.minimum_password_length
    PasswordReusePrevention    = var.password_reuse_prevention
    MaxPasswordAge             = var.max_password_age
  })

  depends_on = [var.config_recorder_name]

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-iam-password-policy"
      Environment = var.environment
      Module      = "compliance-monitoring"
      Compliance  = "Security"
    },
    var.additional_tags
  )
}

resource "aws_config_config_rule" "cloudtrail_enabled" {
  name = "${var.project_name}-${var.environment}-cloudtrail-enabled"

  source {
    owner             = "AWS"
    source_identifier = "CLOUD_TRAIL_ENABLED"
  }

  depends_on = [var.config_recorder_name]

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-cloudtrail-enabled"
      Environment = var.environment
      Module      = "compliance-monitoring"
      Compliance  = "Governance"
    },
    var.additional_tags
  )
}

# Custom Config Rule for required tags
resource "aws_config_config_rule" "required_tags" {
  count = var.enable_tag_compliance ? 1 : 0

  name = "${var.project_name}-${var.environment}-required-tags"

  source {
    owner             = "AWS"
    source_identifier = "REQUIRED_TAGS"
  }

  input_parameters = jsonencode({
    requiredTagKeys = join(",", var.required_tags)
  })

  scope {
    compliance_resource_types = var.tag_compliance_resource_types
  }

  depends_on = [var.config_recorder_name]

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-required-tags"
      Environment = var.environment
      Module      = "compliance-monitoring"
      Compliance  = "Governance"
    },
    var.additional_tags
  )
}

# Lambda function for custom compliance checks
resource "aws_lambda_function" "compliance_checker" {
  count = var.enable_custom_compliance_checks ? 1 : 0

  filename         = data.archive_file.compliance_checker_lambda[0].output_path
  function_name    = "${var.project_name}-${var.environment}-compliance-checker"
  role             = aws_iam_role.compliance_checker_lambda[0].arn
  handler          = "index.handler"
  runtime          = "python3.11"
  timeout          = 300
  memory_size      = 256
  source_code_hash = data.archive_file.compliance_checker_lambda[0].output_base64sha256

  environment {
    variables = {
      SNS_TOPIC_ARN = var.notification_topic_arn
      PROJECT_NAME  = var.project_name
      ENVIRONMENT   = var.environment
    }
  }

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-compliance-checker-lambda"
      Environment = var.environment
      Module      = "compliance-monitoring"
    },
    var.additional_tags
  )
}

# Lambda function source code
data "archive_file" "compliance_checker_lambda" {
  count = var.enable_custom_compliance_checks ? 1 : 0

  type        = "zip"
  output_path = "/tmp/compliance_checker_lambda.zip"
  source {
    content  = file("${path.module}/lambda/compliance_checker.py")
    filename = "index.py"
  }
}

# EventBridge rule for compliance checks
resource "aws_cloudwatch_event_rule" "compliance_checker_schedule" {
  count = var.enable_custom_compliance_checks ? 1 : 0

  name                = "${var.project_name}-${var.environment}-compliance-checker-schedule"
  description         = "Trigger compliance checker Lambda function"
  schedule_expression = var.compliance_check_schedule

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-compliance-checker-schedule"
      Environment = var.environment
      Module      = "compliance-monitoring"
    },
    var.additional_tags
  )
}

resource "aws_cloudwatch_event_target" "compliance_checker_lambda" {
  count = var.enable_custom_compliance_checks ? 1 : 0

  rule      = aws_cloudwatch_event_rule.compliance_checker_schedule[0].name
  target_id = "ComplianceCheckerLambdaTarget"
  arn       = aws_lambda_function.compliance_checker[0].arn
}

resource "aws_lambda_permission" "allow_eventbridge_compliance_checker" {
  count = var.enable_custom_compliance_checks ? 1 : 0

  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.compliance_checker[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.compliance_checker_schedule[0].arn
}

# IAM role for compliance checker Lambda
resource "aws_iam_role" "compliance_checker_lambda" {
  count = var.enable_custom_compliance_checks ? 1 : 0

  name = "${var.project_name}-${var.environment}-compliance-checker-lambda-role"

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
      Name        = "${var.project_name}-${var.environment}-compliance-checker-lambda-role"
      Environment = var.environment
      Module      = "compliance-monitoring"
    },
    var.additional_tags
  )
}

resource "aws_iam_role_policy_attachment" "compliance_checker_lambda_basic" {
  count = var.enable_custom_compliance_checks ? 1 : 0

  role       = aws_iam_role.compliance_checker_lambda[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "compliance_checker_lambda" {
  count = var.enable_custom_compliance_checks ? 1 : 0

  name = "${var.project_name}-${var.environment}-compliance-checker-lambda-policy"
  role = aws_iam_role.compliance_checker_lambda[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "config:GetComplianceDetailsByConfigRule",
          "config:GetComplianceDetailsByResource",
          "config:GetComplianceSummaryByConfigRule",
          "config:DescribeConfigRules",
          "config:DescribeComplianceByConfigRule"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "securityhub:GetFindings",
          "securityhub:BatchImportFindings"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSnapshots",
          "ec2:DescribeVolumes"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation",
          "s3:GetBucketLogging",
          "s3:GetBucketVersioning",
          "s3:GetEncryptionConfiguration",
          "s3:GetBucketAcl",
          "s3:GetBucketPolicy",
          "s3:ListAllMyBuckets"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "rds:DescribeDBInstances",
          "rds:DescribeDBClusters",
          "rds:DescribeDBSnapshots"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = var.notification_topic_arn
      }
    ]
  })
}

# CloudWatch Dashboard for Compliance
resource "aws_cloudwatch_dashboard" "compliance" {
  dashboard_name = "${var.project_name}-${var.environment}-compliance"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/Config", "ComplianceByConfigRule", { "stat" = "Average" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.id
          title   = "Config Rule Compliance"
          period  = 3600
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/SecurityHub", "Findings", "ComplianceStatus", "PASSED"],
            ["AWS/SecurityHub", "Findings", "ComplianceStatus", "FAILED"],
            ["AWS/SecurityHub", "Findings", "ComplianceStatus", "WARNING"]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.id
          title   = "Security Hub Findings"
          period  = 3600
        }
      },
      {
        type   = "text"
        x      = 0
        y      = 6
        width  = 24
        height = 4

        properties = {
          markdown = join("\n", [
            "## Compliance Dashboard",
            "",
            "### Active Config Rules:",
            "- S3 SSL Requests Only",
            "- S3 Public Access Prohibited",
            "- S3 Server-Side Encryption",
            "- EC2 Security Groups Attached",
            "- EC2 SSM Managed",
            "- RDS Storage Encrypted",
            "- RDS No Public Access",
            "- CloudTrail Enabled",
            var.enable_iam_compliance_rules ? "- IAM Password Policy" : "",
            var.enable_tag_compliance ? "- Required Tags" : "",
            "",
            "### Compliance Standards:",
            "- AWS Security Best Practices",
            "- SOC 2 Type II Controls",
            "- Data Protection Requirements"
          ])
        }
      }
    ]
  })
}

# CloudWatch alarms for compliance violations
resource "aws_cloudwatch_metric_alarm" "config_compliance" {
  alarm_name          = "${var.project_name}-${var.environment}-config-non-compliance"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "ComplianceByConfigRule"
  namespace           = "AWS/Config"
  period              = "3600"
  statistic           = "Average"
  threshold           = var.compliance_threshold
  alarm_description   = "This metric monitors Config rule compliance"
  alarm_actions       = [var.notification_topic_arn]

  treat_missing_data = "breaching"

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-config-compliance-alarm"
      Environment = var.environment
      Module      = "compliance-monitoring"
    },
    var.additional_tags
  )
}

# Config Remediation Configurations (for supported rules)
resource "aws_config_remediation_configuration" "s3_bucket_ssl_requests_only" {
  count = var.enable_auto_remediation ? 1 : 0

  config_rule_name = aws_config_config_rule.s3_bucket_ssl_requests_only.name

  resource_type              = "AWS::S3::Bucket"
  target_type                = "SSM_DOCUMENT"
  target_id                  = "AWD-PublishSNSNotification"
  target_version             = "1"
  maximum_automatic_attempts = 3

  parameter {
    name         = "TopicArn"
    static_value = var.notification_topic_arn
  }

  parameter {
    name         = "Message"
    static_value = "S3 bucket SSL requests compliance violation detected"
  }
}

# CloudWatch log group for compliance checker Lambda
resource "aws_cloudwatch_log_group" "compliance_checker_lambda" {
  count = var.enable_custom_compliance_checks ? 1 : 0

  name              = "/aws/lambda/${aws_lambda_function.compliance_checker[0].function_name}"
  retention_in_days = var.log_retention_days

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-compliance-checker-lambda-logs"
      Environment = var.environment
      Module      = "compliance-monitoring"
    },
    var.additional_tags
  )
}