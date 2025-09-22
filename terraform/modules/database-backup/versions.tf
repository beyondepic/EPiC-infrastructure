# Terraform and Provider Version Constraints - Database Backup Module

terraform {
  required_version = ">= 1.13.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.14.0"
    }

    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.6.0"
    }
  }
}