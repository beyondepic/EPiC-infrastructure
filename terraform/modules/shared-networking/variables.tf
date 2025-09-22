# Variables for Shared Networking Module

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (shared, staging, production)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_count" {
  description = "Number of public subnets to create"
  type        = number
  default     = 3
}

variable "private_subnet_count" {
  description = "Number of private subnets to create"
  type        = number
  default     = 3
}

variable "database_subnet_count" {
  description = "Number of database subnets to create"
  type        = number
  default     = 3
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = true
}

variable "nat_gateway_count" {
  description = "Number of NAT Gateways to create (for high availability)"
  type        = number
  default     = 2
}

variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs"
  type        = bool
  default     = true
}

variable "flow_logs_retention_days" {
  description = "Number of days to retain VPC Flow Logs"
  type        = number
  default     = 14
}

variable "additional_tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}