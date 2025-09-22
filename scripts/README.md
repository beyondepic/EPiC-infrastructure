# EPiC Infrastructure - Deployment Scripts

This directory contains automated deployment and validation scripts for the EPiC Infrastructure Management System.

## 🚀 Quick Start

### 1. Deploy Staging Environment
```bash
# From repository root
./scripts/deploy-staging.sh
```

### 2. Validate Infrastructure
```bash
# Validate staging environment
./scripts/validate-infrastructure.sh staging

# Validate production environment
./scripts/validate-infrastructure.sh production
```

### 3. Deploy Production Environment
```bash
# Deploy to production (with safety checks)
./scripts/deploy-production.sh
```

## 📁 Script Overview

### `deploy-staging.sh`
**Purpose**: Automated deployment of the staging environment
**Safety Level**: 🟢 Safe (staging environment)

**Features**:
- Prerequisite checking (AWS CLI, Terraform, credentials)
- Automatic backend setup (S3 bucket, DynamoDB table)
- Shared environment deployment
- Security scanning with Checkov
- Staging environment deployment
- Post-deployment validation
- Comprehensive error handling

**Usage**:
```bash
# Full deployment
./scripts/deploy-staging.sh

# Skip specific steps
./scripts/deploy-staging.sh --skip-prereq --skip-backend

# Get help
./scripts/deploy-staging.sh --help
```

### `deploy-production.sh`
**Purpose**: Secure deployment of the production environment
**Safety Level**: 🔴 High Risk (production environment)

**Features**:
- Multiple confirmation prompts
- Staging environment validation requirement
- Security compliance checks
- State backup before deployment
- Plan review process
- Enhanced monitoring configuration
- Post-deployment checklist

**Usage**:
```bash
# Interactive production deployment
./scripts/deploy-production.sh

# Skip specific safety checks (NOT RECOMMENDED)
./scripts/deploy-production.sh --skip-staging-check

# Get help
./scripts/deploy-production.sh --help
```

### `validate-infrastructure.sh`
**Purpose**: Comprehensive infrastructure health checks
**Safety Level**: 🟢 Safe (read-only validation)

**Features**:
- Terraform state validation
- VPC and networking checks
- Security baseline verification
- Application infrastructure testing
- Monitoring and alerting validation
- Cost management verification
- Compliance monitoring checks
- Detailed reporting with pass/fail/warning status

**Usage**:
```bash
# Validate staging
./scripts/validate-infrastructure.sh staging

# Validate production
./scripts/validate-infrastructure.sh production

# Get help
./scripts/validate-infrastructure.sh --help
```

## 🔧 Prerequisites

### Required Tools
- **AWS CLI**: Configured with appropriate permissions
- **Terraform**: Version 1.6 or higher
- **jq**: For JSON processing in scripts
- **curl**: For endpoint testing

### AWS Permissions
The following AWS permissions are required:

#### Core Infrastructure
- EC2: Full access for VPC, instances, load balancers
- S3: Full access for buckets and objects
- IAM: Full access for roles and policies
- CloudFormation: Read access for stack information

#### Security Services
- CloudTrail: Full access
- GuardDuty: Full access
- Security Hub: Full access
- AWS Config: Full access
- KMS: Key management access

#### Monitoring & Cost Management
- CloudWatch: Full access for logs, metrics, dashboards, alarms
- AWS Budgets: Full access
- Cost Explorer: Read access
- SNS: Full access for notifications

#### Optional (for enhanced features)
- Lambda: Full access for automation functions
- EventBridge: Full access for scheduling
- ECS: Full access for serverless hosting option

### AWS Account Setup
1. **Backend Resources**: S3 bucket and DynamoDB table (auto-created by scripts)
2. **Region**: Scripts are configured for `ap-southeast-4` (adjust in script headers if needed)
3. **Billing**: Ensure Cost Explorer and Budgets are enabled

## 📋 Deployment Workflow

### Standard Deployment Process

1. **Preparation**
   ```bash
   # Clone repository and navigate to root
   git clone <repository-url>
   cd EPiC-infrastructure

   # Configure AWS credentials
   aws configure
   ```

2. **Staging Deployment**
   ```bash
   # Deploy staging environment
   ./scripts/deploy-staging.sh

   # Validate deployment
   ./scripts/validate-infrastructure.sh staging
   ```

3. **Application Testing**
   ```bash
   # Deploy your application to staging
   # Test all functionality
   # Validate monitoring and alerting
   ```

4. **Production Deployment**
   ```bash
   # Deploy production environment
   ./scripts/deploy-production.sh

   # Validate deployment
   ./scripts/validate-infrastructure.sh production
   ```

5. **Post-Production Setup**
   - Configure DNS for custom domains
   - Set up SNS notification subscriptions
   - Deploy applications to production
   - Configure additional monitoring

## 🔐 Security Considerations

### Script Security
- All scripts include parameter validation
- Production scripts require explicit confirmation
- State backup is created before production changes
- Security scanning is integrated into deployment

### Infrastructure Security
- All resources use encryption at rest
- VPC with private subnets for application servers
- Security groups with least privilege access
- CloudTrail logging for all API calls
- GuardDuty for threat detection
- Security Hub for centralized findings

### Credential Management
- Never hardcode credentials in scripts or Terraform files
- Use AWS IAM roles and policies for service access
- Store sensitive values in AWS Secrets Manager
- Use temporary credentials where possible

## 🚨 Troubleshooting

### Common Issues

#### Permission Errors
```bash
# Verify AWS credentials
aws sts get-caller-identity

# Check IAM permissions
aws iam get-user
aws iam list-attached-user-policies --user-name <username>
```

#### State Lock Issues
```bash
# If Terraform state is locked
cd terraform/environments/<environment>
terraform force-unlock <lock-id>
```

#### Backend Issues
```bash
# Verify backend resources exist
aws s3 ls s3://epic-terraform-state
aws dynamodb describe-table --table-name epic-terraform-locks
```

#### Validation Failures
```bash
# Run with detailed output
./scripts/validate-infrastructure.sh staging 2>&1 | tee validation.log

# Check specific AWS resources
aws ec2 describe-vpcs --filters "Name=tag:Project,Values=epic"
aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names epic-staging-web-asg
```

### Script Debugging
Enable verbose output:
```bash
# Add debug flag to any script
bash -x ./scripts/deploy-staging.sh
```

### Recovery Procedures

#### Rollback Production Deployment
```bash
# 1. Navigate to production environment
cd terraform/environments/production

# 2. Restore from backup (if available)
cp ../../../backups/<timestamp>/terraform.tfvars .

# 3. Plan rollback
terraform plan

# 4. Apply previous state (if safe)
terraform apply
```

#### Emergency Infrastructure Shutdown
```bash
# EMERGENCY ONLY - This will destroy all resources
cd terraform/environments/<environment>
terraform destroy --auto-approve
```

## 📊 Monitoring Integration

### CloudWatch Dashboards
The scripts automatically create dashboards for:
- **Infrastructure**: VPC, EC2, ALB metrics
- **Security**: GuardDuty findings, Config compliance
- **Application**: Custom application metrics
- **Cost**: Budget status, cost trends

### Alerting
Automatic alerts are configured for:
- High CPU/memory/disk utilization
- ALB response time and error rates
- Security Hub critical findings
- Budget threshold breaches
- Cost anomalies

### Cost Management
- Monthly budgets with email alerts
- Service-specific budget breakdowns
- Cost anomaly detection
- Reserved Instance recommendations
- S3 lifecycle policy suggestions

## 🔄 Maintenance

### Regular Tasks
- **Weekly**: Review CloudWatch dashboards and alerts
- **Monthly**: Analyze cost reports and optimization recommendations
- **Quarterly**: Update Terraform modules and provider versions
- **As needed**: Run security scans and compliance checks

### Updates and Upgrades
```bash
# Update Terraform modules
cd terraform/modules/<module-name>
terraform init -upgrade

# Run validation after updates
./scripts/validate-infrastructure.sh <environment>
```

### Backup Strategy
- Terraform state is automatically backed up before production changes
- Regular exports of infrastructure configuration
- Document all manual changes outside of Terraform

## 📞 Support

### Getting Help
1. **Check logs**: Review script output and Terraform logs
2. **Validate configuration**: Run validation scripts
3. **AWS Console**: Check resource status in AWS Console
4. **Documentation**: Refer to module README files

### Useful Commands
```bash
# View Terraform outputs
cd terraform/environments/<environment>
terraform output

# Check resource status
terraform state list
terraform state show <resource>

# View plan without applying
terraform plan

# Import existing resources
terraform import <resource_type>.<name> <resource_id>
```

---

## 📝 Configuration Files

Each environment requires a `terraform.tfvars` file. Sample configurations are provided:

- `terraform/environments/staging/terraform.tfvars.sample`
- Copy and customize for each environment
- Update email addresses, domain names, and other environment-specific values

## 🎯 Next Steps

After successful deployment:

1. **Application Integration**: Deploy your applications to the new infrastructure
2. **DNS Configuration**: Set up domain routing to CloudFront and ALB
3. **Monitoring Setup**: Configure SNS subscriptions for alerts
4. **Cost Optimization**: Review and adjust budget thresholds
5. **Security Review**: Address any Security Hub findings
6. **Documentation**: Update your team's runbooks and procedures

---

*For additional help, refer to the comprehensive testing plan in `/docs/COMPREHENSIVE_TESTING_PLAN.md`*