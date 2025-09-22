# Variables for Web Application Module

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (staging, production)"
  type        = string
}

variable "application_name" {
  description = "Name of the application"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the Auto Scaling Group"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for the Application Load Balancer"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group ID for EC2 instances"
  type        = string
}

variable "alb_security_group_id" {
  description = "Security group ID for the Application Load Balancer"
  type        = string
}

variable "instance_profile_name" {
  description = "Name of the IAM instance profile"
  type        = string
}

# Instance Configuration
variable "ami_id" {
  description = "AMI ID for EC2 instances (defaults to latest Amazon Linux 2)"
  type        = string
  default     = null
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_pair_name" {
  description = "Name of the EC2 Key Pair for SSH access"
  type        = string
  default     = null
}

variable "root_volume_size" {
  description = "Size of the root EBS volume in GB"
  type        = number
  default     = 20
}

variable "enable_detailed_monitoring" {
  description = "Enable detailed CloudWatch monitoring"
  type        = bool
  default     = true
}

# Auto Scaling Configuration
variable "min_size" {
  description = "Minimum number of instances in the Auto Scaling Group"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of instances in the Auto Scaling Group"
  type        = number
  default     = 5
}

variable "desired_capacity" {
  description = "Desired number of instances in the Auto Scaling Group"
  type        = number
  default     = 2
}

variable "scale_up_threshold" {
  description = "CPU utilization threshold for scaling up"
  type        = number
  default     = 75
}

variable "scale_down_threshold" {
  description = "CPU utilization threshold for scaling down"
  type        = number
  default     = 25
}

# Load Balancer Configuration
variable "target_port" {
  description = "Port for the target group"
  type        = number
  default     = 80
}

variable "health_check_path" {
  description = "Health check path"
  type        = string
  default     = "/health"
}

variable "enable_stickiness" {
  description = "Enable session stickiness"
  type        = bool
  default     = false
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection for the load balancer"
  type        = bool
  default     = false
}

variable "enable_access_logs" {
  description = "Enable access logs for the load balancer"
  type        = bool
  default     = true
}

variable "access_logs_bucket" {
  description = "S3 bucket for access logs"
  type        = string
  default     = null
}

# SSL Configuration
variable "ssl_certificate_arn" {
  description = "ARN of the SSL certificate for HTTPS listener"
  type        = string
  default     = null
}

variable "ssl_policy" {
  description = "SSL policy for HTTPS listener"
  type        = string
  default     = "ELBSecurityPolicy-TLS-1-2-2017-01"
}

variable "additional_tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}