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