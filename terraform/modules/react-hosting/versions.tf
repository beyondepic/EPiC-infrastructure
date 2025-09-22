# Terraform and Provider Version Constraints - React Hosting Module

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
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.12.0"
    }
    awscc = {
      source  = "hashicorp/awscc"
      version = "~> 1.56.0"
    }
  }
}