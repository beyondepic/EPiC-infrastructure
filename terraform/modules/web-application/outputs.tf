# Outputs for Web Application Module

# Auto Scaling Group
output "autoscaling_group_id" {
  description = "ID of the Auto Scaling Group"
  value       = aws_autoscaling_group.web.id
}

output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.web.name
}

output "autoscaling_group_arn" {
  description = "ARN of the Auto Scaling Group"
  value       = aws_autoscaling_group.web.arn
}

# Launch Template
output "launch_template_id" {
  description = "ID of the Launch Template"
  value       = aws_launch_template.web.id
}

output "launch_template_latest_version" {
  description = "Latest version of the Launch Template"
  value       = aws_launch_template.web.latest_version
}

# Application Load Balancer
output "load_balancer_id" {
  description = "ID of the Application Load Balancer"
  value       = aws_lb.web.id
}

output "load_balancer_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.web.arn
}

output "load_balancer_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.web.dns_name
}

output "load_balancer_zone_id" {
  description = "Canonical hosted zone ID of the load balancer"
  value       = aws_lb.web.zone_id
}

# Target Group
output "target_group_id" {
  description = "ID of the Target Group"
  value       = aws_lb_target_group.web.id
}

output "target_group_arn" {
  description = "ARN of the Target Group"
  value       = aws_lb_target_group.web.arn
}

# Listeners
output "http_listener_arn" {
  description = "ARN of the HTTP listener"
  value       = aws_lb_listener.web_http.arn
}

output "https_listener_arn" {
  description = "ARN of the HTTPS listener"
  value       = aws_lb_listener.web_https.arn
}

# Auto Scaling Policies
output "scale_up_policy_arn" {
  description = "ARN of the scale up policy"
  value       = aws_autoscaling_policy.scale_up.arn
}

output "scale_down_policy_arn" {
  description = "ARN of the scale down policy"
  value       = aws_autoscaling_policy.scale_down.arn
}

# CloudWatch Alarms
output "cpu_high_alarm_arn" {
  description = "ARN of the CPU high alarm"
  value       = aws_cloudwatch_metric_alarm.cpu_high.arn
}

output "cpu_low_alarm_arn" {
  description = "ARN of the CPU low alarm"
  value       = aws_cloudwatch_metric_alarm.cpu_low.arn
}

# WAF Outputs
output "waf_web_acl_arn" {
  description = "ARN of the WAF Web ACL"
  value       = var.enable_waf ? aws_wafv2_web_acl.web_acl[0].arn : null
}

output "waf_web_acl_id" {
  description = "ID of the WAF Web ACL"
  value       = var.enable_waf ? aws_wafv2_web_acl.web_acl[0].id : null
}

output "waf_web_acl_name" {
  description = "Name of the WAF Web ACL"
  value       = var.enable_waf ? aws_wafv2_web_acl.web_acl[0].name : null
}