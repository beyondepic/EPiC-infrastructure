# Terraform and Provider Version Constraints - Shared Environment

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
    bucket         = "epic-terraform-state-shared"
    key            = "shared/terraform.tfstate"
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

# AWS Provider Configuration for Shared Resources
provider "aws" {
  region = "ap-southeast-4"

  # Shared environment provider tags
  default_tags {
    tags = {
      Project     = "epic"
      Environment = "shared"
      ManagedBy   = "Terraform"
      Repository  = "EPiC-infrastructure"
      Version     = "2.0.0"
      CostCenter  = "Infrastructure"
      Owner       = "DevOps Team"
      Shared      = "CrossEnvironment"
    }
  }
}