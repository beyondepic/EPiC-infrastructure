# Cost Optimization Module
# Implements cost monitoring, budgets, and optimization recommendations

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Cost Budget for overall spending
resource "aws_budgets_budget" "monthly_cost" {
  name              = "${var.project_name}-${var.environment}-monthly-budget"
  budget_type       = "COST"
  limit_amount      = var.monthly_budget_limit
  limit_unit        = "USD"
  time_unit         = "MONTHLY"
  time_period_start = formatdate("YYYY-MM-01_00:00", timestamp())

  cost_filter {
    name   = "TagKeyValue"
    values = var.cost_allocation_tags
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = var.budget_alert_threshold
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.notification_emails
    subscriber_sns_topic_arns  = var.notification_topic_arn != null ? [var.notification_topic_arn] : []
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = var.budget_forecast_threshold
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = var.notification_emails
    subscriber_sns_topic_arns  = var.notification_topic_arn != null ? [var.notification_topic_arn] : []
  }

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-monthly-budget"
      Environment = var.environment
      Module      = "cost-optimization"
    },
    var.additional_tags
  )
}

# Service-specific budgets
resource "aws_budgets_budget" "service_budgets" {
  for_each = var.service_budgets

  name              = "${var.project_name}-${var.environment}-${each.key}-budget"
  budget_type       = "COST"
  limit_amount      = each.value.limit
  limit_unit        = "USD"
  time_unit         = "MONTHLY"
  time_period_start = formatdate("YYYY-MM-01_00:00", timestamp())

  cost_filter {
    name   = "Service"
    values = [each.value.service_name]
  }

  cost_filter {
    name   = "TagKeyValue"
    values = var.cost_allocation_tags
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = each.value.alert_threshold
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.notification_emails
    subscriber_sns_topic_arns  = var.notification_topic_arn != null ? [var.notification_topic_arn] : []
  }

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-${each.key}-budget"
      Environment = var.environment
      Module      = "cost-optimization"
      Service     = each.value.service_name
    },
    var.additional_tags
  )
}

# Note: Cost Explorer anomaly detection resources are not available in Terraform AWS provider
# Manual setup required through AWS Console or AWS CLI

# Lambda function for cost optimization recommendations
resource "aws_lambda_function" "cost_optimizer" {
  count = var.enable_cost_recommendations ? 1 : 0

  filename         = data.archive_file.cost_optimizer_lambda[0].output_path
  function_name    = "${var.project_name}-${var.environment}-cost-optimizer"
  role             = aws_iam_role.cost_optimizer_lambda[0].arn
  handler          = "index.handler"
  runtime          = "python3.11"
  timeout          = 300
  memory_size      = 256
  source_code_hash = data.archive_file.cost_optimizer_lambda[0].output_base64sha256

  environment {
    variables = {
      SNS_TOPIC_ARN         = var.notification_topic_arn
      PROJECT_NAME          = var.project_name
      ENVIRONMENT           = var.environment
      COST_THRESHOLD        = var.recommendation_cost_threshold
      UTILIZATION_THRESHOLD = var.recommendation_utilization_threshold
    }
  }

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-cost-optimizer-lambda"
      Environment = var.environment
      Module      = "cost-optimization"
    },
    var.additional_tags
  )
}

# Lambda function source code
data "archive_file" "cost_optimizer_lambda" {
  count = var.enable_cost_recommendations ? 1 : 0

  type        = "zip"
  output_path = "/tmp/cost_optimizer_lambda.zip"
  source {
    content  = file("${path.module}/lambda/cost_optimizer.py")
    filename = "index.py"
  }
}

# EventBridge rule for cost optimization recommendations
resource "aws_cloudwatch_event_rule" "cost_optimizer_schedule" {
  count = var.enable_cost_recommendations ? 1 : 0

  name                = "${var.project_name}-${var.environment}-cost-optimizer-schedule"
  description         = "Trigger cost optimization Lambda function"
  schedule_expression = var.cost_optimization_schedule

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-cost-optimizer-schedule"
      Environment = var.environment
      Module      = "cost-optimization"
    },
    var.additional_tags
  )
}

resource "aws_cloudwatch_event_target" "cost_optimizer_lambda" {
  count = var.enable_cost_recommendations ? 1 : 0

  rule      = aws_cloudwatch_event_rule.cost_optimizer_schedule[0].name
  target_id = "CostOptimizerLambdaTarget"
  arn       = aws_lambda_function.cost_optimizer[0].arn
}

resource "aws_lambda_permission" "allow_eventbridge_cost_optimizer" {
  count = var.enable_cost_recommendations ? 1 : 0

  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cost_optimizer[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cost_optimizer_schedule[0].arn
}

# IAM role for cost optimizer Lambda
resource "aws_iam_role" "cost_optimizer_lambda" {
  count = var.enable_cost_recommendations ? 1 : 0

  name = "${var.project_name}-${var.environment}-cost-optimizer-lambda-role"

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
      Name        = "${var.project_name}-${var.environment}-cost-optimizer-lambda-role"
      Environment = var.environment
      Module      = "cost-optimization"
    },
    var.additional_tags
  )
}

resource "aws_iam_role_policy_attachment" "cost_optimizer_lambda_basic" {
  count = var.enable_cost_recommendations ? 1 : 0

  role       = aws_iam_role.cost_optimizer_lambda[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "cost_optimizer_lambda" {
  count = var.enable_cost_recommendations ? 1 : 0

  name = "${var.project_name}-${var.environment}-cost-optimizer-lambda-policy"
  role = aws_iam_role.cost_optimizer_lambda[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ce:GetCostAndUsage",
          "ce:GetReservationCoverage",
          "ce:GetReservationPurchaseRecommendation",
          "ce:GetReservationUtilization",
          "ce:GetRightsizingRecommendation",
          "ce:ListCostCategoryDefinitions"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeReservedInstances",
          "ec2:DescribeReservedInstancesOfferings",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:GetMetricData"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "rds:DescribeDBInstances",
          "rds:DescribeReservedDBInstances",
          "rds:DescribeReservedDBInstancesOfferings"
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

# CloudWatch Dashboard for Cost Monitoring
resource "aws_cloudwatch_dashboard" "cost_monitoring" {
  dashboard_name = "${var.project_name}-${var.environment}-cost-monitoring"

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
            ["AWS/Billing", "EstimatedCharges", "Currency", "USD"],
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1" # Billing metrics are only available in us-east-1
          title   = "Estimated Monthly Charges"
          period  = 86400
          stat    = "Maximum"
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
            ["AWS/Billing", "EstimatedCharges", "Currency", "USD", "ServiceName", "AmazonEC2"],
            ["AWS/Billing", "EstimatedCharges", "Currency", "USD", "ServiceName", "AmazonS3"],
            ["AWS/Billing", "EstimatedCharges", "Currency", "USD", "ServiceName", "AmazonRDS"],
            ["AWS/Billing", "EstimatedCharges", "Currency", "USD", "ServiceName", "AWSLambda"]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          title   = "Service Costs"
          period  = 86400
          stat    = "Maximum"
        }
      },
      {
        type   = "text"
        x      = 0
        y      = 6
        width  = 24
        height = 3

        properties = {
          markdown = join("\n", [
            "## Cost Optimization Dashboard",
            "",
            "**Budget Limit:** $${var.monthly_budget_limit}",
            "**Alert Threshold:** ${var.budget_alert_threshold}%",
            "**Forecast Threshold:** ${var.budget_forecast_threshold}%",
            "",
            "### Optimization Features:",
            "- 📊 Real-time cost monitoring",
            "- 🚨 Budget alerts and anomaly detection",
            "- 💡 Automated cost recommendations",
            "- 🏷️ Resource tagging for cost allocation"
          ])
        }
      }
    ]
  })

}

# Cost allocation tags
resource "aws_ce_cost_category" "project_categories" {
  count = var.enable_cost_categories ? 1 : 0

  name         = "${var.project_name}-${var.environment}-cost-categories"
  rule_version = "CostCategoryExpression.v1"

  rule {
    value = "Production"
    rule {
      tags {
        key           = "Environment"
        values        = ["production"]
        match_options = ["EQUALS"]
      }
    }
  }

  rule {
    value = "Staging"
    rule {
      tags {
        key           = "Environment"
        values        = ["staging"]
        match_options = ["EQUALS"]
      }
    }
  }

  rule {
    value = "Shared"
    rule {
      tags {
        key           = "Environment"
        values        = ["shared"]
        match_options = ["EQUALS"]
      }
    }
  }

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-cost-categories"
      Environment = var.environment
      Module      = "cost-optimization"
    },
    var.additional_tags
  )
}

# CloudWatch log group for cost optimizer Lambda
resource "aws_cloudwatch_log_group" "cost_optimizer_lambda" {
  count = var.enable_cost_recommendations ? 1 : 0

  name              = "/aws/lambda/${aws_lambda_function.cost_optimizer[0].function_name}"
  retention_in_days = var.log_retention_days

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-cost-optimizer-lambda-logs"
      Environment = var.environment
      Module      = "cost-optimization"
    },
    var.additional_tags
  )
}