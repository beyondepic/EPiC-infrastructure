# Outputs for Shared Networking Module

# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "vpc_arn" {
  description = "ARN of the VPC"
  value       = aws_vpc.main.arn
}

# Internet Gateway
output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

# Subnet Outputs
output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "database_subnet_ids" {
  description = "IDs of the database subnets"
  value       = aws_subnet.database[*].id
}

output "public_subnet_arns" {
  description = "ARNs of the public subnets"
  value       = aws_subnet.public[*].arn
}

output "private_subnet_arns" {
  description = "ARNs of the private subnets"
  value       = aws_subnet.private[*].arn
}

output "database_subnet_arns" {
  description = "ARNs of the database subnets"
  value       = aws_subnet.database[*].arn
}

# NAT Gateway Outputs
output "nat_gateway_ids" {
  description = "IDs of the NAT Gateways"
  value       = aws_nat_gateway.main[*].id
}

output "nat_gateway_public_ips" {
  description = "Public IPs of the NAT Gateways"
  value       = aws_eip.nat[*].public_ip
}

# Route Table Outputs
output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public.id
}

output "private_route_table_ids" {
  description = "IDs of the private route tables"
  value       = aws_route_table.private[*].id
}

output "database_route_table_id" {
  description = "ID of the database route table"
  value       = aws_route_table.database.id
}

# Security Group Outputs
output "web_security_group_id" {
  description = "ID of the web security group"
  value       = aws_security_group.web.id
}

output "application_security_group_id" {
  description = "ID of the application security group"
  value       = aws_security_group.application.id
}

output "database_security_group_id" {
  description = "ID of the database security group"
  value       = aws_security_group.database.id
}

# DB Subnet Group
output "db_subnet_group_name" {
  description = "Name of the database subnet group"
  value       = var.database_subnet_count > 0 ? aws_db_subnet_group.main[0].name : null
}

output "db_subnet_group_arn" {
  description = "ARN of the database subnet group"
  value       = var.database_subnet_count > 0 ? aws_db_subnet_group.main[0].arn : null
}

# Availability Zones
output "availability_zones" {
  description = "List of availability zones used"
  value       = data.aws_availability_zones.available.names
}

# VPC Endpoints
output "vpc_endpoints_enabled" {
  description = "Whether VPC endpoints are enabled"
  value       = var.enable_vpc_endpoints
}

output "s3_vpc_endpoint_id" {
  description = "ID of the S3 VPC endpoint"
  value       = var.enable_vpc_endpoints ? aws_vpc_endpoint.s3[0].id : null
}

output "dynamodb_vpc_endpoint_id" {
  description = "ID of the DynamoDB VPC endpoint"
  value       = var.enable_vpc_endpoints ? aws_vpc_endpoint.dynamodb[0].id : null
}

output "vpc_endpoints_security_group_id" {
  description = "ID of the security group for VPC endpoints"
  value       = var.enable_vpc_endpoints ? aws_security_group.vpc_endpoints[0].id : null
}

output "vpc_endpoints_route_table_id" {
  description = "ID of the route table for VPC endpoints"
  value       = var.enable_vpc_endpoints ? aws_route_table.vpc_endpoints[0].id : null
}

# Advanced Security Outputs
output "network_acl_id" {
  description = "ID of the main Network ACL"
  value       = aws_network_acl.main.id
}

output "vpc_flow_log_group_name" {
  description = "Name of the VPC Flow Logs CloudWatch Log Group"
  value       = var.enable_flow_logs ? aws_cloudwatch_log_group.vpc_flow_log[0].name : null
}

output "security_insights_query_names" {
  description = "Names of CloudWatch Insights queries for security monitoring"
  value = var.enable_flow_logs ? [
    aws_cloudwatch_query_definition.vpc_flow_log_security[0].name,
    aws_cloudwatch_query_definition.vpc_flow_log_top_talkers[0].name
  ] : []
}

output "security_alarm_arn" {
  description = "ARN of the VPC security monitoring alarm"
  value       = var.enable_flow_logs ? aws_cloudwatch_metric_alarm.vpc_rejected_connections[0].arn : null
}

output "cloudtrail_vpc_endpoint_id" {
  description = "ID of the CloudTrail VPC endpoint"
  value       = var.enable_vpc_endpoints ? aws_vpc_endpoint.cloudtrail[0].id : null
}