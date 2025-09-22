# Terraform and Provider Version Constraints - Production Environment

terraform {
  required_version = ">= 1.13.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.14.0"
    }
  }

  # S3 Backend Configuration for Remote State
  backend "s3" {
    bucket         = "epic-terraform-state-production"
    key            = "production/terraform.tfstate"
    region         = "ap-southeast-4"
    encrypt        = true
    dynamodb_table = "epic-terraform-locks"

    # Optional: Add versioning and lifecycle configuration
    versioning = true
    lifecycle {
      prevent_destroy = true
    }
  }
}

# AWS Provider Configuration for Production
provider "aws" {
  region = "ap-southeast-4"

  # Production-specific provider tags
  default_tags {
    tags = {
      Project     = "epic"
      Environment = "production"
      ManagedBy   = "Terraform"
      Repository  = "EPiC-infrastructure"
      Version     = "2.0.0"
      CostCenter  = "Production"
      Owner       = "DevOps Team"
      Backup      = "Required"
      Monitoring  = "Critical"
    }
  }
}