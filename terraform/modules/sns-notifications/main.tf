# SNS Notifications Module
# Provides email and application notifications for infrastructure events

# Create SNS topic for infrastructure notifications
resource "aws_sns_topic" "infrastructure_notifications" {
  name         = "${var.project_name}-${var.environment}-notifications"
  display_name = "EPiC Infrastructure Notifications - ${title(var.environment)}"

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-notifications"
    Environment = var.environment
    Module      = "sns-notifications"
    Purpose     = "infrastructure-alerts"
  })
}

# Create SNS topic for application notifications (OTP, user alerts)
resource "aws_sns_topic" "application_notifications" {
  name         = "${var.project_name}-${var.environment}-app-notifications"
  display_name = "EPiC Application Notifications - ${title(var.environment)}"

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-app-notifications"
    Environment = var.environment
    Module      = "sns-notifications"
    Purpose     = "application-alerts"
  })
}

# Email subscription for infrastructure notifications
resource "aws_sns_topic_subscription" "infrastructure_email" {
  count     = var.notification_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.infrastructure_notifications.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

# Email subscription for application notifications
resource "aws_sns_topic_subscription" "application_email" {
  count     = var.application_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.application_notifications.arn
  protocol  = "email"
  endpoint  = var.application_email
}

# Lambda function for Slack notifications (if webhook provided)
resource "aws_lambda_function" "slack_notifier" {
  count         = var.slack_webhook_url != "" ? 1 : 0
  filename      = data.archive_file.slack_notifier_zip[0].output_path
  function_name = "${var.project_name}-${var.environment}-slack-notifier"
  role          = aws_iam_role.lambda_sns_role[0].arn
  handler       = "index.handler"
  runtime       = "python3.11"
  timeout       = 30

  source_code_hash = data.archive_file.slack_notifier_zip[0].output_base64sha256

  environment {
    variables = {
      SLACK_WEBHOOK_URL = var.slack_webhook_url
    }
  }

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-slack-notifier"
    Environment = var.environment
    Module      = "sns-notifications"
    Purpose     = "slack-integration"
  })
}

# Lambda function source code
data "archive_file" "slack_notifier_zip" {
  count       = var.slack_webhook_url != "" ? 1 : 0
  type        = "zip"
  output_path = "/tmp/slack_notifier.zip"
  source {
    content = templatefile("${path.module}/templates/slack_notifier.py", {
      webhook_url = var.slack_webhook_url
    })
    filename = "index.py"
  }
}

# IAM role for Lambda function
resource "aws_iam_role" "lambda_sns_role" {
  count = var.slack_webhook_url != "" ? 1 : 0
  name  = "${var.project_name}-${var.environment}-lambda-sns-role"

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

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-lambda-sns-role"
    Environment = var.environment
    Module      = "sns-notifications"
  })
}

# IAM policy for Lambda function
resource "aws_iam_role_policy" "lambda_sns_policy" {
  count = var.slack_webhook_url != "" ? 1 : 0
  name  = "${var.project_name}-${var.environment}-lambda-sns-policy"
  role  = aws_iam_role.lambda_sns_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:*:*"
      }
    ]
  })
}

# SNS subscription for Slack notifications
resource "aws_sns_topic_subscription" "slack_infrastructure" {
  count     = var.slack_webhook_url != "" ? 1 : 0
  topic_arn = aws_sns_topic.infrastructure_notifications.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.slack_notifier[0].arn
}

resource "aws_sns_topic_subscription" "slack_application" {
  count     = var.slack_webhook_url != "" ? 1 : 0
  topic_arn = aws_sns_topic.application_notifications.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.slack_notifier[0].arn
}

# Lambda permission for SNS to invoke function
resource "aws_lambda_permission" "sns_invoke_lambda_infrastructure" {
  count         = var.slack_webhook_url != "" ? 1 : 0
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.slack_notifier[0].function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.infrastructure_notifications.arn
}

resource "aws_lambda_permission" "sns_invoke_lambda_application" {
  count         = var.slack_webhook_url != "" ? 1 : 0
  statement_id  = "AllowExecutionFromSNSApp"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.slack_notifier[0].function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.application_notifications.arn
}

# CloudWatch Log Group for Lambda function
resource "aws_cloudwatch_log_group" "slack_notifier_logs" {
  count             = var.slack_webhook_url != "" ? 1 : 0
  name              = "/aws/lambda/${aws_lambda_function.slack_notifier[0].function_name}"
  retention_in_days = 14

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-slack-notifier-logs"
    Environment = var.environment
    Module      = "sns-notifications"
  })
}

# SNS topic policy for cross-service access
resource "aws_sns_topic_policy" "infrastructure_notifications_policy" {
  arn = aws_sns_topic.infrastructure_notifications.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudWatchAlarmsToPublish"
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.infrastructure_notifications.arn
      },
      {
        Sid    = "AllowBackupServiceToPublish"
        Effect = "Allow"
        Principal = {
          Service = "backup.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.infrastructure_notifications.arn
      }
    ]
  })
}

resource "aws_sns_topic_policy" "application_notifications_policy" {
  arn = aws_sns_topic.application_notifications.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowApplicationToPublish"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.application_notifications.arn
        Condition = {
          StringEquals = {
            "aws:PrincipalTag/Project" = var.project_name
          }
        }
      }
    ]
  })
}

# Data source for current AWS account ID
data "aws_caller_identity" "current" {}