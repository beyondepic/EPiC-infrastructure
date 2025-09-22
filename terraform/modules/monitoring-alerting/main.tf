# Monitoring and Alerting Module
# Creates CloudWatch dashboards, alarms, and comprehensive monitoring

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# CloudWatch Dashboard for Infrastructure Overview
resource "aws_cloudwatch_dashboard" "infrastructure_overview" {
  dashboard_name = "${var.project_name}-${var.environment}-infrastructure"

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
            ["AWS/EC2", "CPUUtilization", { "stat" = "Average" }],
            ["AWS/ApplicationELB", "TargetResponseTime", { "stat" = "Average" }],
            ["AWS/ApplicationELB", "RequestCount", { "stat" = "Sum" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.id
          title   = "Application Performance"
          period  = 300
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
            ["AWS/RDS", "CPUUtilization", { "stat" = "Average" }],
            ["AWS/RDS", "DatabaseConnections", { "stat" = "Average" }],
            ["AWS/RDS", "FreeableMemory", { "stat" = "Average" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.id
          title   = "Database Performance"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 8
        height = 6

        properties = {
          metrics = [
            ["AWS/S3", "BucketSizeBytes", "StorageType", "StandardStorage", { "stat" = "Average" }],
            ["AWS/S3", "NumberOfObjects", "StorageType", "AllStorageTypes", { "stat" = "Average" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.id
          title   = "Storage Usage"
          period  = 86400
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 6
        width  = 8
        height = 6

        properties = {
          metrics = [
            ["AWS/Lambda", "Duration", { "stat" = "Average" }],
            ["AWS/Lambda", "Errors", { "stat" = "Sum" }],
            ["AWS/Lambda", "Invocations", { "stat" = "Sum" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.id
          title   = "Lambda Functions"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 6
        width  = 8
        height = 6

        properties = {
          metrics = [
            ["AWS/CloudFront", "Requests", { "stat" = "Sum" }],
            ["AWS/CloudFront", "BytesDownloaded", { "stat" = "Sum" }],
            ["AWS/CloudFront", "4xxErrorRate", { "stat" = "Average" }],
            ["AWS/CloudFront", "5xxErrorRate", { "stat" = "Average" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.id
          title   = "CloudFront CDN"
          period  = 300
        }
      }
    ]
  })

}

# Security Dashboard
resource "aws_cloudwatch_dashboard" "security" {
  dashboard_name = "${var.project_name}-${var.environment}-security"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "log"
        x      = 0
        y      = 0
        width  = 24
        height = 6

        properties = {
          query   = "SOURCE '/aws/events/rule/guardduty' | fields @timestamp, detail.type, detail.severity\n| filter detail.severity > ${var.security_alert_severity_threshold}\n| sort @timestamp desc\n| limit 100"
          region  = data.aws_region.current.id
          title   = "Recent Security Findings (GuardDuty)"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/Config", "ComplianceByConfigRule", "RuleName", { "stat" = "Average" }],
            ["AWS/Config", "ComplianceByResourceType", "ResourceType", { "stat" = "Average" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.id
          title   = "Compliance Status"
          period  = 3600
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/CloudTrail", "DataEvents", { "stat" = "Sum" }],
            ["AWS/CloudTrail", "ManagementEvents", { "stat" = "Sum" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.id
          title   = "API Activity (CloudTrail)"
          period  = 3600
        }
      }
    ]
  })

}

# Application-specific dashboard
resource "aws_cloudwatch_dashboard" "application" {
  count = length(var.applications) > 0 ? 1 : 0

  dashboard_name = "${var.project_name}-${var.environment}-applications"

  dashboard_body = jsonencode({
    widgets = concat([
      for idx, app in var.applications : {
        type   = "metric"
        x      = (idx % 3) * 8
        y      = floor(idx / 3) * 6
        width  = 8
        height = 6

        properties = {
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", app.load_balancer_name, { "stat" = "Average" }],
            ["AWS/ApplicationELB", "HTTPCode_Target_2XX_Count", "LoadBalancer", app.load_balancer_name, { "stat" = "Sum" }],
            ["AWS/ApplicationELB", "HTTPCode_Target_4XX_Count", "LoadBalancer", app.load_balancer_name, { "stat" = "Sum" }],
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", app.load_balancer_name, { "stat" = "Sum" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.id
          title   = "${app.name} - Load Balancer"
          period  = 300
        }
      }
    ])
  })

}

# High CPU utilization alarm
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.project_name}-${var.environment}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = var.cpu_alarm_threshold
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = [var.alert_topic_arn]
  ok_actions          = [var.alert_topic_arn]

  dimensions = {
    AutoScalingGroupName = var.autoscaling_group_name
  }

  treat_missing_data = "notBreaching"

}

# High memory utilization alarm
resource "aws_cloudwatch_metric_alarm" "high_memory" {
  count = var.enable_memory_monitoring ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-high-memory"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "CWAgent"
  period              = "300"
  statistic           = "Average"
  threshold           = var.memory_alarm_threshold
  alarm_description   = "This metric monitors memory utilization"
  alarm_actions       = [var.alert_topic_arn]
  ok_actions          = [var.alert_topic_arn]

  treat_missing_data = "notBreaching"

}

# High disk utilization alarm
resource "aws_cloudwatch_metric_alarm" "high_disk" {
  count = var.enable_disk_monitoring ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-high-disk"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DiskSpaceUtilization"
  namespace           = "CWAgent"
  period              = "300"
  statistic           = "Average"
  threshold           = var.disk_alarm_threshold
  alarm_description   = "This metric monitors disk space utilization"
  alarm_actions       = [var.alert_topic_arn]
  ok_actions          = [var.alert_topic_arn]

  treat_missing_data = "notBreaching"

}

# ALB response time alarm
resource "aws_cloudwatch_metric_alarm" "alb_response_time" {
  count = var.load_balancer_arn != null ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-alb-response-time"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Average"
  threshold           = var.response_time_threshold
  alarm_description   = "This metric monitors ALB response time"
  alarm_actions       = [var.alert_topic_arn]
  ok_actions          = [var.alert_topic_arn]

  dimensions = {
    LoadBalancer = split("/", var.load_balancer_arn)[1]
  }

  treat_missing_data = "notBreaching"

}

# ALB 5xx error rate alarm
resource "aws_cloudwatch_metric_alarm" "alb_5xx_errors" {
  count = var.load_balancer_arn != null ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-alb-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Sum"
  threshold           = var.error_rate_threshold
  alarm_description   = "This metric monitors ALB 5xx error rate"
  alarm_actions       = [var.alert_topic_arn]
  ok_actions          = [var.alert_topic_arn]

  dimensions = {
    LoadBalancer = split("/", var.load_balancer_arn)[1]
  }

  treat_missing_data = "notBreaching"

}

# RDS CPU utilization alarm
resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  count = var.rds_instance_id != null ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-rds-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = var.rds_cpu_threshold
  alarm_description   = "This metric monitors RDS CPU utilization"
  alarm_actions       = [var.alert_topic_arn]
  ok_actions          = [var.alert_topic_arn]

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }

  treat_missing_data = "notBreaching"

}

# RDS freeable memory alarm
resource "aws_cloudwatch_metric_alarm" "rds_memory" {
  count = var.rds_instance_id != null ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-rds-memory"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "FreeableMemory"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = var.rds_memory_threshold
  alarm_description   = "This metric monitors RDS freeable memory"
  alarm_actions       = [var.alert_topic_arn]
  ok_actions          = [var.alert_topic_arn]

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }

  treat_missing_data = "notBreaching"

}

# Lambda error rate alarm
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  for_each = var.lambda_functions

  alarm_name          = "${var.project_name}-${var.environment}-lambda-${each.key}-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = var.lambda_error_threshold
  alarm_description   = "This metric monitors Lambda function errors"
  alarm_actions       = [var.alert_topic_arn]
  ok_actions          = [var.alert_topic_arn]

  dimensions = {
    FunctionName = each.value
  }

  treat_missing_data = "notBreaching"

}

# Lambda duration alarm
resource "aws_cloudwatch_metric_alarm" "lambda_duration" {
  for_each = var.lambda_functions

  alarm_name          = "${var.project_name}-${var.environment}-lambda-${each.key}-duration"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Average"
  threshold           = var.lambda_duration_threshold
  alarm_description   = "This metric monitors Lambda function duration"
  alarm_actions       = [var.alert_topic_arn]

  dimensions = {
    FunctionName = each.value
  }

  treat_missing_data = "notBreaching"

}

# CloudWatch log insights saved queries
resource "aws_cloudwatch_query_definition" "error_analysis" {
  name = "${var.project_name}-${var.environment}-error-analysis"

  log_group_names = var.log_group_names

  query_string = <<EOF
fields @timestamp, @message
| filter @message like /ERROR/
| sort @timestamp desc
| limit 100
EOF
}

resource "aws_cloudwatch_query_definition" "performance_analysis" {
  name = "${var.project_name}-${var.environment}-performance-analysis"

  log_group_names = var.log_group_names

  query_string = <<EOF
fields @timestamp, @duration, @requestId
| filter @type = "REPORT"
| sort @duration desc
| limit 50
EOF
}

# Custom metric filter for application errors
resource "aws_cloudwatch_log_metric_filter" "application_errors" {
  count = length(var.log_group_names) > 0 ? 1 : 0

  name           = "${var.project_name}-${var.environment}-application-errors"
  log_group_name = var.log_group_names[0]
  pattern        = "[timestamp, request_id, ERROR, ...]"

  metric_transformation {
    name      = "ApplicationErrors"
    namespace = "${var.project_name}/${var.environment}/Application"
    value     = "1"
  }
}

# Alarm for application errors
resource "aws_cloudwatch_metric_alarm" "application_errors" {
  count = length(var.log_group_names) > 0 ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-application-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "ApplicationErrors"
  namespace           = "${var.project_name}/${var.environment}/Application"
  period              = "300"
  statistic           = "Sum"
  threshold           = var.application_error_threshold
  alarm_description   = "This metric monitors application errors"
  alarm_actions       = [var.alert_topic_arn]

  treat_missing_data = "notBreaching"

}