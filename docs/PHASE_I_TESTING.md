# Phase I Testing Procedure

## Pre-Testing Setup

### 1. Prerequisites Check
```bash
# Verify required tools
terraform --version  # Should be >= 1.6
aws --version        # Should be >= 2.0
aws sts get-caller-identity  # Verify AWS access

# Check AWS permissions
aws iam get-user
aws ec2 describe-regions --region ap-southeast-4
```

### 2. Backend Infrastructure Setup
```bash
# Create S3 buckets for state
aws s3 mb s3://epic-terraform-state-shared --region ap-southeast-4
aws s3 mb s3://epic-terraform-state-staging --region ap-southeast-4

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket epic-terraform-state-shared \
  --versioning-configuration Status=Enabled

aws s3api put-bucket-versioning \
  --bucket epic-terraform-state-staging \
  --versioning-configuration Status=Enabled

# Create DynamoDB lock table
aws dynamodb create-table \
  --table-name epic-terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
  --region ap-southeast-4
```

## Test 1: Shared Environment Deployment

### 1.1 Configuration
```bash
cd terraform/environments/shared

# Create terraform.tfvars
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your values:
# notification_email = "your-email@domain.com"
# project_name = "epic"
# aws_region = "ap-southeast-4"
```

### 1.2 Deployment
```bash
# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Check formatting
terraform fmt -check

# Plan deployment
terraform plan -out=tfplan

# Apply infrastructure
terraform apply tfplan
```

### 1.3 Verification Tests
```bash
# Test 1: Verify VPC Creation
VPC_ID=$(terraform output -raw vpc_id)
aws ec2 describe-vpcs --vpc-ids $VPC_ID --region ap-southeast-4

# Test 2: Verify Subnets
aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --region ap-southeast-4

# Test 3: Verify Security Groups
aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$VPC_ID" --region ap-southeast-4

# Test 4: Verify CloudTrail
aws cloudtrail describe-trails --region ap-southeast-4

# Test 5: Verify GuardDuty
aws guardduty list-detectors --region ap-southeast-4

# Test 6: Verify Config
aws configservice describe-configuration-recorders --region ap-southeast-4

# Test 7: Verify SNS Topics
aws sns list-topics --region ap-southeast-4 | grep epic
```

### 1.4 Expected Results
- ✅ VPC with CIDR 10.0.0.0/16
- ✅ 3 public subnets, 3 private subnets, 3 database subnets
- ✅ 2 NAT Gateways in different AZs
- ✅ Security groups for web, app, and database tiers
- ✅ CloudTrail logging to S3
- ✅ GuardDuty detector enabled
- ✅ AWS Config recorder active
- ✅ SNS topics for notifications

## Test 2: Module Testing

### 2.1 Test Shared Networking Module
```bash
cd terraform/modules/shared-networking

# Create test configuration
cat > test.tf << 'EOF'
module "test_networking" {
  source = "./"

  project_name = "test"
  environment  = "dev"
  vpc_cidr     = "192.168.0.0/16"

  public_subnet_count   = 2
  private_subnet_count  = 2
  database_subnet_count = 2
  enable_nat_gateway    = false  # Save costs for testing
  enable_flow_logs      = false  # Save costs for testing
}
EOF

terraform init
terraform plan
terraform destroy -auto-approve  # Clean up after test
```

### 2.2 Test Security Baseline Module
```bash
cd terraform/modules/security-baseline

# Test with minimal configuration
cat > test.tf << 'EOF'
module "test_security" {
  source = "./"

  project_name = "test"
  environment  = "dev"

  enable_config                    = false  # Disable for testing
  enable_guardduty                 = false  # Disable for testing
  enable_security_hub              = false  # Disable for testing
  enable_iam_password_policy       = false  # Don't override account policy
}
EOF

terraform init
terraform plan
# Don't apply - just validate syntax
```

### 2.3 Test React Hosting Module
```bash
cd terraform/modules/react-hosting

# Test static hosting configuration
cat > test.tf << 'EOF'
module "test_react_static" {
  source = "./"

  app_name     = "test-app"
  environment  = "dev"
  hosting_type = "static"

  enable_force_destroy = true
  cloudfront_price_class = "PriceClass_100"
}
EOF

terraform init
terraform plan
# Review plan but don't apply unless needed
```

## Test 3: Integration Testing

### 3.1 Test Web Application Module Integration
```bash
cd terraform/environments/shared

# Add web application test
cat >> test-web-app.tf << 'EOF'
module "test_web_app" {
  source = "../../modules/web-application"

  project_name    = "epic"
  environment     = "shared"
  application_name = "test-app"

  vpc_id                = module.shared_networking.vpc_id
  subnet_ids           = module.shared_networking.private_subnet_ids
  public_subnet_ids    = module.shared_networking.public_subnet_ids
  security_group_id    = module.shared_networking.application_security_group_id
  alb_security_group_id = module.shared_networking.web_security_group_id
  instance_profile_name = module.security_baseline.ec2_instance_profile_name

  instance_type    = "t3.micro"
  min_size        = 1
  max_size        = 2
  desired_capacity = 1

  enable_deletion_protection = false
  access_logs_bucket        = null  # Disable for testing
}
EOF

terraform plan
# If plan looks good, apply and test
terraform apply
```

### 3.2 Test Application Accessibility
```bash
# Get ALB DNS name
ALB_DNS=$(terraform output -raw test_web_app_alb_dns_name 2>/dev/null || echo "Not available")

# Test ALB health check endpoint
curl -f http://$ALB_DNS/health

# Check Auto Scaling Group
ASG_NAME=$(terraform output -raw test_web_app_asg_name 2>/dev/null)
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names $ASG_NAME \
  --region ap-southeast-4
```

## Test 4: Security Validation

### 4.1 Run Security Scans
```bash
# Install Checkov if not already installed
pip install checkov

# Run security scan on shared environment
cd terraform/environments/shared
checkov -d . --framework terraform --output cli

# Check for common security issues
checkov -d . --framework terraform --check CKV_AWS_8,CKV_AWS_21,CKV_AWS_23
```

### 4.2 Validate IAM Policies
```bash
# Check IAM roles created
aws iam list-roles --query "Roles[?contains(RoleName, 'epic-shared')]"

# Validate policies are least privilege
aws iam get-role-policy --role-name epic-shared-ec2-instance-role --policy-name inline-policy || echo "No inline policies"
```

### 4.3 Test Network Security
```bash
# Verify security group rules
aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=epic-shared-web-*" \
  --query "SecurityGroups[].IpPermissions"

# Check VPC Flow Logs
aws logs describe-log-groups \
  --log-group-name-prefix "/aws/vpc/flowlogs" \
  --region ap-southeast-4
```

## Test 5: Cost and Resource Validation

### 5.1 Check Resource Costs
```bash
# Get cost estimation (if AWS Cost Explorer CLI is available)
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE
```

### 5.2 Validate Resource Tagging
```bash
# Check all resources have proper tags
aws ec2 describe-instances \
  --filters "Name=tag:Project,Values=EPiC Infrastructure" \
  --query "Reservations[].Instances[].Tags"

aws s3api get-bucket-tagging --bucket epic-terraform-state-shared
```

## Test 6: Cleanup and Destruction Testing

### 6.1 Test Resource Cleanup
```bash
cd terraform/environments/shared

# Remove test web app if created
rm -f test-web-app.tf

# Plan destruction of test resources
terraform plan -destroy

# If needed, destroy test resources (be careful!)
# terraform destroy -auto-approve
```

### 6.2 Verify State Management
```bash
# Check state file location
terraform state list

# Verify state lock
aws dynamodb scan --table-name epic-terraform-locks --region ap-southeast-4
```

## Expected Success Criteria

### ✅ Phase I Success Indicators:
1. **Infrastructure Deployed**: All modules deploy without errors
2. **Security Enabled**: CloudTrail, GuardDuty, Config all active
3. **Network Connectivity**: Subnets can reach internet via NAT Gateways
4. **Monitoring Active**: CloudWatch logs and metrics collecting
5. **State Management**: Terraform state stored in S3 with locking
6. **Security Scan**: No critical security issues in Checkov scan
7. **Cost Tracking**: All resources properly tagged
8. **Documentation**: All outputs accessible and documented

### 🚨 Failure Scenarios to Check:
1. **Permission Issues**: Verify AWS credentials and permissions
2. **Resource Conflicts**: Check for naming conflicts
3. **State Lock Issues**: Ensure DynamoDB table is accessible
4. **Network Issues**: Validate subnet routing and NAT Gateway health
5. **Security Violations**: Address any security findings immediately

## Troubleshooting Guide

### Common Issues:
1. **"Bucket already exists"**: Use unique bucket names with random suffix
2. **"Access Denied"**: Check IAM permissions for the service
3. **"Resource already exists"**: Import existing resource or use different name
4. **State lock timeout**: Check DynamoDB table and force unlock if needed

### Debug Commands:
```bash
# Enable Terraform debug logging
export TF_LOG=DEBUG
terraform plan

# Check AWS CLI configuration
aws configure list
aws sts get-caller-identity

# Validate JSON syntax in policies
cat policy.json | jq .
```

This comprehensive testing procedure will validate that Phase I is working correctly and ready for production use.