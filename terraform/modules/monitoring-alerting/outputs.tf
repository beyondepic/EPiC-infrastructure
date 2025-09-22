# Outputs for Monitoring and Alerting Module

# Dashboard Outputs
output "infrastructure_dashboard_url" {
  description = "URL to the infrastructure overview dashboard"
  value       = "https://${data.aws_region.current.name}.console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#dashboards:name=${aws_cloudwatch_dashboard.infrastructure_overview.dashboard_name}"
}

output "security_dashboard_url" {
  description = "URL to the security dashboard"
  value       = "https://${data.aws_region.current.name}.console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#dashboards:name=${aws_cloudwatch_dashboard.security.dashboard_name}"
}

output "application_dashboard_url" {
  description = "URL to the application dashboard"
  value       = length(var.applications) > 0 ? "https://${data.aws_region.current.name}.console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#dashboards:name=${aws_cloudwatch_dashboard.application[0].dashboard_name}" : null
}

# Dashboard Names
output "infrastructure_dashboard_name" {
  description = "Name of the infrastructure dashboard"
  value       = aws_cloudwatch_dashboard.infrastructure_overview.dashboard_name
}

output "security_dashboard_name" {
  description = "Name of the security dashboard"
  value       = aws_cloudwatch_dashboard.security.dashboard_name
}

output "application_dashboard_name" {
  description = "Name of the application dashboard"
  value       = length(var.applications) > 0 ? aws_cloudwatch_dashboard.application[0].dashboard_name : null
}

# Alarm ARNs
output "high_cpu_alarm_arn" {
  description = "ARN of the high CPU utilization alarm"
  value       = aws_cloudwatch_metric_alarm.high_cpu.arn
}

output "high_memory_alarm_arn" {
  description = "ARN of the high memory utilization alarm"
  value       = var.enable_memory_monitoring ? aws_cloudwatch_metric_alarm.high_memory[0].arn : null
}

output "high_disk_alarm_arn" {
  description = "ARN of the high disk utilization alarm"
  value       = var.enable_disk_monitoring ? aws_cloudwatch_metric_alarm.high_disk[0].arn : null
}

output "alb_response_time_alarm_arn" {
  description = "ARN of the ALB response time alarm"
  value       = var.load_balancer_arn != null ? aws_cloudwatch_metric_alarm.alb_response_time[0].arn : null
}

output "alb_5xx_errors_alarm_arn" {
  description = "ARN of the ALB 5xx errors alarm"
  value       = var.load_balancer_arn != null ? aws_cloudwatch_metric_alarm.alb_5xx_errors[0].arn : null
}

output "rds_cpu_alarm_arn" {
  description = "ARN of the RDS CPU utilization alarm"
  value       = var.rds_instance_id != null ? aws_cloudwatch_metric_alarm.rds_cpu[0].arn : null
}

output "rds_memory_alarm_arn" {
  description = "ARN of the RDS memory alarm"
  value       = var.rds_instance_id != null ? aws_cloudwatch_metric_alarm.rds_memory[0].arn : null
}

output "lambda_error_alarm_arns" {
  description = "ARNs of the Lambda error alarms"
  value       = { for k, v in aws_cloudwatch_metric_alarm.lambda_errors : k => v.arn }
}

output "lambda_duration_alarm_arns" {
  description = "ARNs of the Lambda duration alarms"
  value       = { for k, v in aws_cloudwatch_metric_alarm.lambda_duration : k => v.arn }
}

output "application_errors_alarm_arn" {
  description = "ARN of the application errors alarm"
  value       = length(var.log_group_names) > 0 ? aws_cloudwatch_metric_alarm.application_errors[0].arn : null
}

# Saved Queries
output "error_analysis_query_name" {
  description = "Name of the error analysis saved query"
  value       = aws_cloudwatch_query_definition.error_analysis.name
}

output "performance_analysis_query_name" {
  description = "Name of the performance analysis saved query"
  value       = aws_cloudwatch_query_definition.performance_analysis.name
}

# Metric Filters
output "application_errors_metric_filter_name" {
  description = "Name of the application errors metric filter"
  value       = length(var.log_group_names) > 0 ? aws_cloudwatch_log_metric_filter.application_errors[0].name : null
}

# Alarm States (for status monitoring)
output "alarm_names" {
  description = "List of all alarm names created by this module"
  value = compact([
    aws_cloudwatch_metric_alarm.high_cpu.alarm_name,
    var.enable_memory_monitoring ? aws_cloudwatch_metric_alarm.high_memory[0].alarm_name : null,
    var.enable_disk_monitoring ? aws_cloudwatch_metric_alarm.high_disk[0].alarm_name : null,
    var.load_balancer_arn != null ? aws_cloudwatch_metric_alarm.alb_response_time[0].alarm_name : null,
    var.load_balancer_arn != null ? aws_cloudwatch_metric_alarm.alb_5xx_errors[0].alarm_name : null,
    var.rds_instance_id != null ? aws_cloudwatch_metric_alarm.rds_cpu[0].alarm_name : null,
    var.rds_instance_id != null ? aws_cloudwatch_metric_alarm.rds_memory[0].alarm_name : null,
    length(var.log_group_names) > 0 ? aws_cloudwatch_metric_alarm.application_errors[0].alarm_name : null
  ])
}

# Monitoring Configuration Summary
output "monitoring_summary" {
  description = "Summary of monitoring configuration"
  value = {
    dashboards_created = compact([
      aws_cloudwatch_dashboard.infrastructure_overview.dashboard_name,
      aws_cloudwatch_dashboard.security.dashboard_name,
      length(var.applications) > 0 ? aws_cloudwatch_dashboard.application[0].dashboard_name : null
    ])
    alarms_created = length(compact([
      aws_cloudwatch_metric_alarm.high_cpu.alarm_name,
      var.enable_memory_monitoring ? aws_cloudwatch_metric_alarm.high_memory[0].alarm_name : null,
      var.enable_disk_monitoring ? aws_cloudwatch_metric_alarm.high_disk[0].alarm_name : null,
      var.load_balancer_arn != null ? aws_cloudwatch_metric_alarm.alb_response_time[0].alarm_name : null,
      var.load_balancer_arn != null ? aws_cloudwatch_metric_alarm.alb_5xx_errors[0].alarm_name : null,
      var.rds_instance_id != null ? aws_cloudwatch_metric_alarm.rds_cpu[0].alarm_name : null,
      var.rds_instance_id != null ? aws_cloudwatch_metric_alarm.rds_memory[0].alarm_name : null,
      length(var.log_group_names) > 0 ? aws_cloudwatch_metric_alarm.application_errors[0].alarm_name : null
    ]))
    lambda_functions_monitored = length(var.lambda_functions)
    applications_monitored     = length(var.applications)
    log_groups_monitored      = length(var.log_group_names)
  }
}