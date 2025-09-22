# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a Terraform-based infrastructure-as-code repository for managing AWS resources across multiple EPiC projects and environments. The infrastructure follows a modular architecture with reusable Terraform modules and environment-specific configurations.

## Key Technologies

- **Infrastructure as Code**: Terraform 1.6+
- **Cloud Provider**: AWS (primary region: ap-southeast-4)
- **State Management**: S3 backend with DynamoDB locking
- **CI/CD**: GitHub Actions (planned)

## Development Commands

### Terraform Operations

```bash
# Initialize Terraform (required before any other operations)
cd terraform/environments/<environment>
terraform init

# Validate configuration syntax
terraform validate

# Preview infrastructure changes
terraform plan

# Apply infrastructure changes
terraform apply

# Destroy infrastructure (use with caution)
terraform destroy
```

### Working with Modules

```bash
# When developing a new module
cd terraform/modules/<module-name>
terraform fmt          # Format Terraform files
terraform validate     # Validate module syntax

# Test module locally
cd terraform/environments/staging
terraform plan -target=module.<module_name>
```

### Environment Management

- **shared**: Cross-environment resources (VPC, networking)
- **staging**: Testing environment for changes
- **production**: Live production resources

Always deploy to staging first before production.

## Architecture & Structure

### Module Pattern
All infrastructure is organized as reusable Terraform modules under `terraform/modules/`. Each module follows this structure:
- `main.tf`: Primary resource definitions
- `variables.tf`: Input variable declarations
- `outputs.tf`: Output value exports
- `README.md`: Module documentation

### Available Modules
- **sns-notifications**: Email/Slack notification system using SNS topics and Lambda
- **database-backup**: RDS backup automation with S3 storage
- **web-application**: EC2 Auto Scaling with ALB
- **react-hosting**: S3 + CloudFront for static sites
- **shared-networking**: VPC, subnets, security groups
- **security-baseline**: IAM, Config, GuardDuty, CloudTrail

### State Management
- Terraform state is stored in S3 with encryption enabled
- State locking uses DynamoDB to prevent concurrent modifications
- Each environment maintains separate state files

### Resource Tagging Strategy
All resources must include these tags:
- `Project`: Project name (e.g., "nestedphoenix")
- `Environment`: Environment name (staging/production)
- `ManagedBy`: "Terraform"
- `Module`: Module name that created the resource

## Important Conventions

### Naming Conventions
- Resources: `{project_name}-{environment}-{resource_type}`
- Modules: Use kebab-case (e.g., `sns-notifications`)
- Variables: Use snake_case (e.g., `notification_email`)

### Security Requirements
- Never commit sensitive values (use variables and AWS Secrets Manager)
- All S3 buckets must have encryption enabled
- IAM policies follow least privilege principle
- Security groups use restrictive ingress rules

### Module Usage Pattern
```hcl
module "example" {
  source = "../../modules/module-name"

  project_name = var.project_name
  environment  = var.environment
  # Additional module-specific variables
}
```

## GitHub CLI Usage

When working with pull requests and GitHub operations:
```bash
# Create PR from feature branch
gh pr create --title "feat: description" --body "Details..."

# Check PR status
gh pr status

# View PR checks
gh pr checks
```

## Common Tasks

### Adding a New Module
1. Create module directory under `terraform/modules/`
2. Implement main.tf, variables.tf, outputs.tf
3. Add README.md with usage examples
4. Test in staging environment first

### Deploying Infrastructure Changes
1. Make changes in feature branch
2. Run `terraform fmt` and `terraform validate`
3. Test with `terraform plan` in staging
4. Create PR with plan output
5. Apply to staging after review
6. Apply to production with approval

### Debugging Terraform Issues
- Check state with: `terraform state list`
- Import existing resources: `terraform import <resource> <id>`
- Force unlock state: `terraform force-unlock <lock-id>`