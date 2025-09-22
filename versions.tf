# Terraform and Provider Version Constraints
# This file ensures consistent versions across all environments

terraform {
  required_version = ">= 1.13.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.14.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.6.0"
    }

    time = {
      source  = "hashicorp/time"
      version = "~> 0.12.0"
    }

    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4.0"
    }

    null = {
      source  = "hashicorp/null"
      version = "~> 3.2.0"
    }

    external = {
      source  = "hashicorp/external"
      version = "~> 2.3.0"
    }
  }
}

# AWS Provider Configuration
provider "aws" {
  region = var.aws_region

  # Enable provider-level tags
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Repository  = "EPiC-infrastructure"
      Version     = "2.0.0"
    }
  }
}

# Variables for provider configuration
variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "ap-southeast-4"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.aws_region))
    error_message = "AWS region must be a valid region format (e.g., us-east-1, ap-southeast-4)."
  }
}

variable "project_name" {
  description = "Name of the project"
  type        = string

  validation {
    condition     = length(var.project_name) > 0 && length(var.project_name) <= 50 && can(regex("^[a-zA-Z][a-zA-Z0-9-]*$", var.project_name))
    error_message = "Project name must be 1-50 characters, start with a letter, and contain only letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Environment name"
  type        = string

  validation {
    condition     = contains(["shared", "staging", "production"], var.environment)
    error_message = "Environment must be one of: shared, staging, production."
  }
}