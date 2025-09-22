# TFLint Configuration for EPiC Infrastructure
# https://github.com/terraform-linters/tflint

config {
  # Enable all rules by default
  disabled_by_default = false

  # Disable color output for CI/CD
  force_no_color = true

  # Enable module inspection
  module = true

  # Enable variable checks
  varfile = ["terraform.tfvars", "*.auto.tfvars"]
}

# Core Terraform Rules
rule "terraform_deprecated_interpolation" {
  enabled = true
}

rule "terraform_deprecated_index" {
  enabled = true
}

rule "terraform_unused_declarations" {
  enabled = true
}

rule "terraform_comment_syntax" {
  enabled = true
}

rule "terraform_documented_outputs" {
  enabled = true
}

rule "terraform_documented_variables" {
  enabled = true
}

rule "terraform_typed_variables" {
  enabled = true
}

rule "terraform_module_pinned_source" {
  enabled = true
  style   = "semver"
}

rule "terraform_naming_convention" {
  enabled = true
  format  = "snake_case"
}

rule "terraform_required_version" {
  enabled = true
}

rule "terraform_required_providers" {
  enabled = true
}

rule "terraform_standard_module_structure" {
  enabled = true
}

rule "terraform_workspace_remote" {
  enabled = true
}

# AWS Provider Plugin
plugin "aws" {
  enabled = true
  version = "0.37.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"

  # Deep check mode enables more comprehensive rules but requires AWS credentials
  deep_check = false
}

# AWS Specific Rules
rule "aws_instance_invalid_type" {
  enabled = true
}

rule "aws_instance_previous_type" {
  enabled = true
}

rule "aws_instance_invalid_ami" {
  enabled = true
}

rule "aws_instance_invalid_key_name" {
  enabled = true
}

rule "aws_instance_invalid_security_group" {
  enabled = true
}

rule "aws_instance_invalid_subnet" {
  enabled = true
}

rule "aws_instance_invalid_vpc_security_group_id" {
  enabled = true
}

rule "aws_instance_invalid_iam_instance_profile" {
  enabled = true
}

rule "aws_alb_invalid_security_group" {
  enabled = true
}

rule "aws_alb_invalid_subnet" {
  enabled = true
}

rule "aws_db_instance_invalid_type" {
  enabled = true
}

rule "aws_db_instance_invalid_engine" {
  enabled = true
}

rule "aws_elasticache_cluster_invalid_type" {
  enabled = true
}

rule "aws_route_invalid_gateway" {
  enabled = true
}

rule "aws_route_invalid_instance" {
  enabled = true
}

rule "aws_route_invalid_vpc_peering_connection" {
  enabled = true
}

rule "aws_s3_bucket_invalid_acl" {
  enabled = true
}

rule "aws_s3_bucket_invalid_region" {
  enabled = true
}

# Security Best Practices
rule "aws_security_group_rule_invalid_protocol" {
  enabled = true
}

rule "aws_launch_configuration_invalid_image_id" {
  enabled = true
}

rule "aws_launch_configuration_invalid_iam_instance_profile" {
  enabled = true
}

rule "aws_launch_configuration_invalid_security_group" {
  enabled = true
}

# Networking Rules
rule "aws_route_table_invalid_route" {
  enabled = true
}

rule "aws_route_table_invalid_vpc" {
  enabled = true
}

# Custom Rules for EPiC Infrastructure
rule "terraform_workspace_remote" {
  enabled = false  # We use local state for development
}