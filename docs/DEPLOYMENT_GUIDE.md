# EPiC Infrastructure Deployment Guide

This guide provides step-by-step instructions for deploying the EPiC Infrastructure Management System.

## Prerequisites

### 1. Required Tools

- **Terraform** >= 1.6
- **AWS CLI** >= 2.0
- **Git**
- **jq** (for JSON processing)

### 2. AWS Configuration

```bash
# Configure AWS credentials
aws configure

# Verify access
aws sts get-caller-identity
```

### 3. Required AWS Permissions

Your AWS user/role needs permissions for:
- S3 (for state storage)
- DynamoDB (for state locking)
- VPC and networking services
- IAM roles and policies
- CloudTrail, Config, GuardDuty, Security Hub
- EC2, ECS, ALB, CloudFront
- SNS and CloudWatch

## Phase 1: Backend Infrastructure Setup

### Step 1: Create S3 State Buckets and DynamoDB Table

```bash
# Create S3 buckets for Terraform state
aws s3 mb s3://epic-terraform-state-shared --region ap-southeast-4
aws s3 mb s3://epic-terraform-state-staging --region ap-southeast-4
aws s3 mb s3://epic-terraform-state-production --region ap-southeast-4

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket epic-terraform-state-shared \
  --versioning-configuration Status=Enabled

aws s3api put-bucket-versioning \
  --bucket epic-terraform-state-staging \
  --versioning-configuration Status=Enabled

aws s3api put-bucket-versioning \
  --bucket epic-terraform-state-production \
  --versioning-configuration Status=Enabled

# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name epic-terraform-locks \
  --attribute-definitions \
    AttributeName=LockID,AttributeType=S \
  --key-schema \
    AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput \
    ReadCapacityUnits=5,WriteCapacityUnits=5 \
  --region ap-southeast-4
```

### Step 2: Configure Backend

The backend configuration is already set in each environment's `terraform.tf` file.

## Phase 2: Shared Environment Deployment

### Step 1: Deploy Shared Infrastructure

```bash
cd terraform/environments/shared

# Copy and configure variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Review the plan
terraform plan

# Apply the configuration
terraform apply
```

This deploys:
- ✅ VPC with public, private, and database subnets
- ✅ Security groups for web, application, and database tiers
- ✅ CloudTrail for audit logging
- ✅ AWS Config for compliance monitoring
- ✅ GuardDuty for threat detection
- ✅ Security Hub for centralized security
- ✅ SNS topics for notifications

### Step 2: Verify Deployment

```bash
# Check outputs
terraform output

# Verify resources in AWS Console
aws ec2 describe-vpcs --filters "Name=tag:Project,Values=EPiC Infrastructure"
aws cloudtrail describe-trails --region ap-southeast-4
aws guardduty list-detectors --region ap-southeast-4
```

## Phase 3: Application Environment Setup

### Step 1: Configure Staging Environment

```bash
cd terraform/environments/staging

# Copy variables from shared
cp ../shared/terraform.tfvars.example terraform.tfvars

# Update environment-specific values
sed -i 's/environment = "shared"/environment = "staging"/' terraform.tfvars

# Initialize and deploy
terraform init
terraform plan
terraform apply
```

### Step 2: Configure Production Environment

```bash
cd terraform/environments/production

# Copy and configure variables
cp ../shared/terraform.tfvars.example terraform.tfvars
sed -i 's/environment = "shared"/environment = "production"/' terraform.tfvars

# Update production-specific settings
# - Enable deletion protection
# - Increase instance sizes
# - Enable all security features

terraform init
terraform plan
terraform apply
```

## Phase 4: Application Deployment Examples

### Example 1: Deploy a Web Application

```bash
cd terraform/environments/staging

# Create application configuration
cat > web-app.tf << 'EOF'
module "nestedphoenix_web" {
  source = "../../modules/web-application"

  project_name    = "nestedphoenix"
  environment     = var.environment
  application_name = "nestedphoenix-app"

  vpc_id             = module.shared_networking.vpc_id
  subnet_ids         = module.shared_networking.private_subnet_ids
  public_subnet_ids  = module.shared_networking.public_subnet_ids
  security_group_id  = module.shared_networking.application_security_group_id
  alb_security_group_id = module.shared_networking.web_security_group_id
  instance_profile_name = module.security_baseline.ec2_instance_profile_name

  instance_type    = "t3.small"
  min_size        = 1
  max_size        = 3
  desired_capacity = 2

  additional_tags = var.additional_tags
}
EOF

terraform plan
terraform apply
```

### Example 2: Deploy a React Application (Static)

```bash
# Create React hosting configuration
cat > react-app.tf << 'EOF'
module "portfolio_react" {
  source = "../../modules/react-hosting"

  app_name     = "portfolio"
  environment  = var.environment
  hosting_type = "static"
  app_version  = "v1.0.0"

  # Optional: Configure custom domain
  # ssl_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/abc123"
  # domain_names = ["portfolio.yourdomain.com"]

  cloudfront_price_class = "PriceClass_100"
  enable_force_destroy   = true

  additional_tags = var.additional_tags
}
EOF

terraform plan
terraform apply
```

### Example 3: Deploy a React Application (Serverless)

```bash
# Create serverless React hosting configuration
cat > react-serverless.tf << 'EOF'
module "dashboard_react" {
  source = "../../modules/react-hosting"

  app_name     = "dashboard"
  environment  = var.environment
  hosting_type = "serverless"
  app_version  = "v1.0.0"

  # Use existing VPC
  use_existing_vpc       = true
  vpc_id                = module.shared_networking.vpc_id
  public_subnet_ids     = module.shared_networking.public_subnet_ids
  private_subnet_ids    = module.shared_networking.private_subnet_ids
  alb_security_group_id = module.shared_networking.web_security_group_id
  ecs_security_group_id = module.shared_networking.application_security_group_id

  # Application configuration
  container_port = 3000
  desired_count  = 2
  task_cpu      = 512
  task_memory   = 1024

  # Source code path (for CI/CD)
  app_source_path = "/path/to/react/app"

  additional_tags = var.additional_tags
}
EOF

terraform plan
terraform apply
```

## Phase 5: Validation and Testing

### Security Validation

```bash
# Run Checkov security scan
pip install checkov
checkov -d terraform/environments/staging --framework terraform

# Check AWS Config compliance
aws configservice get-compliance-summary-by-resource-type \
  --resource-types AWS::EC2::Instance,AWS::S3::Bucket
```

### Terraform Validation

```bash
# Validate all environments
for env in shared staging production; do
  echo "Validating $env environment..."
  cd terraform/environments/$env
  terraform validate
  terraform fmt -check
  cd ../../..
done
```

### Infrastructure Testing

```bash
# Test web application accessibility
ALB_DNS=$(terraform output -raw load_balancer_dns_name)
curl -f http://$ALB_DNS/health

# Test CloudFront distribution
CLOUDFRONT_URL=$(terraform output -raw application_url)
curl -f $CLOUDFRONT_URL
```

## Maintenance Tasks

### Regular Updates

```bash
# Update Terraform providers
terraform init -upgrade

# Apply security patches
terraform plan
terraform apply
```

### Monitoring

- **CloudWatch**: Monitor application and infrastructure metrics
- **GuardDuty**: Review security findings
- **Security Hub**: Check compliance status
- **Config**: Monitor configuration changes

### Cost Optimization

```bash
# Review AWS costs
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE

# Check for unused resources
aws ec2 describe-instances \
  --filters "Name=instance-state-name,Values=stopped"
```

## Troubleshooting

### Common Issues

1. **State Lock Issues**
   ```bash
   # Force unlock (use carefully)
   terraform force-unlock <LOCK_ID>
   ```

2. **Permission Errors**
   ```bash
   # Check AWS credentials
   aws sts get-caller-identity
   aws iam get-user
   ```

3. **Resource Conflicts**
   ```bash
   # Import existing resources
   terraform import aws_vpc.main vpc-123456789
   ```

### Getting Help

- Check CloudWatch logs for application issues
- Review CloudTrail for AWS API calls
- Use AWS Support for AWS-specific issues
- Check Terraform documentation for configuration issues

## Next Steps

1. **Set up CI/CD pipelines** using GitHub Actions
2. **Configure monitoring dashboards** in CloudWatch
3. **Implement backup strategies** for critical data
4. **Set up alerting** for security and operational events
5. **Plan for disaster recovery** and business continuity