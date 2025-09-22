# Global Terraform Configuration for EPiC Infrastructure
# This file defines the minimum Terraform version and required providers

terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  # Backend configuration for remote state
  # This will be configured per environment
  backend "s3" {
    # Configuration provided by environment-specific terraform.tf files
    # bucket         = "epic-terraform-state-${var.environment}"
    # key            = "terraform.tfstate"
    # region         = "ap-southeast-4"
    # dynamodb_table = "epic-terraform-locks"
    # encrypt        = true
  }
}

# Default AWS provider configuration
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "EPiC Infrastructure"
      ManagedBy   = "Terraform"
      Repository  = "EPiC-infrastructure"
      CreatedBy   = "terraform"
      Environment = var.environment
    }
  }
}