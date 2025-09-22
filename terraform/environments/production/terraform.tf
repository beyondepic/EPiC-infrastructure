# Terraform Configuration for Production Environment

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

  # Backend configuration for production state
  backend "s3" {
    bucket         = "epic-terraform-state-production"
    key            = "production/terraform.tfstate"
    region         = "ap-southeast-4"
    dynamodb_table = "epic-terraform-locks"
    encrypt        = true
  }
}

# AWS Provider configuration for production
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "EPiC Infrastructure"
      ManagedBy   = "Terraform"
      Repository  = "EPiC-infrastructure"
      Environment = "production"
      CreatedBy   = "terraform"
    }
  }
}