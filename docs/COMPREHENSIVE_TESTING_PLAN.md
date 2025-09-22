# Comprehensive Testing Plan - EPiC Infrastructure

This document provides a complete testing plan for validating the EPiC Infrastructure Management System, covering all Phase I and Phase II modules across shared, staging, and production environments.

## Overview

The testing plan is organized into the following sections:
1. **Pre-deployment Setup**: Backend configuration and prerequisites
2. **Phase I Testing**: Core infrastructure modules (shared environment)
3. **Phase II Testing**: Application infrastructure modules (staging/production)
4. **Integration Testing**: End-to-end functionality validation
5. **Security and Compliance Validation**: Security scanning and compliance checks
6. **Disaster Recovery Testing**: Backup and recovery procedures

## Prerequisites

Before starting the testing process, ensure you have:

- [x] AWS CLI installed and configured with appropriate permissions
- [x] Terraform 1.6+ installed
- [x] Access to the target AWS account (ap-southeast-4 region)
- [x] Email access for notification testing
- [x] GitHub CLI installed (for repository operations)

## 1. Pre-deployment Setup

### 1.1 Backend Configuration

First, set up the Terraform state backend:

```bash
# Navigate to repository root
cd /Users/365-pruthvi/development/BeyondEPiC/EPiC-infrastructure

# Create S3 bucket for Terraform state (if not exists)
aws s3api create-bucket \
  --bucket epic-terraform-state \
  --region ap-southeast-4 \
  --create-bucket-configuration LocationConstraint=ap-southeast-4

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket epic-terraform-state \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket epic-terraform-state \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# Create DynamoDB table for state locking (if not exists)
aws dynamodb create-table \
  --table-name epic-terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
  --region ap-southeast-4
```

### 1.2 Environment Variables

Set up required environment variables:

```bash
export AWS_REGION=ap-southeast-4
export PROJECT_NAME=epic
export NOTIFICATION_EMAIL=your-email@example.com
export TF_VAR_notification_email=$NOTIFICATION_EMAIL
```

## 2. Phase I Testing (Shared Environment)

### 2.1 Shared Networking Module Test

```bash
cd terraform/environments/shared

# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Plan deployment
terraform plan -var="notification_email=$NOTIFICATION_EMAIL"

# Apply shared infrastructure
terraform apply -var="notification_email=$NOTIFICATION_EMAIL" -auto-approve
```

**Expected Results:**
- ✅ VPC created with multi-tier subnet architecture
- ✅ Public, private, and database subnets across 3 AZs
- ✅ NAT Gateways and Internet Gateway configured
- ✅ Security groups with least privilege access
- ✅ VPC Flow Logs enabled

**Validation Commands:**
```bash
# Verify VPC creation
aws ec2 describe-vpcs --filters "Name=tag:Project,Values=epic" --region ap-southeast-4

# Check subnet configuration
aws ec2 describe-subnets --filters "Name=tag:Project,Values=epic" --region ap-southeast-4

# Verify NAT Gateways
aws ec2 describe-nat-gateways --filter "Name=tag:Project,Values=epic" --region ap-southeast-4

# Check Flow Logs
aws logs describe-log-groups --log-group-name-prefix "/aws/vpc/flowlogs" --region ap-southeast-4
```

### 2.2 Security Baseline Module Test

**Expected Results:**
- ✅ CloudTrail enabled with S3 logging
- ✅ AWS Config service activated
- ✅ GuardDuty threat detection enabled
- ✅ Security Hub centralized findings
- ✅ KMS keys for encryption

**Validation Commands:**
```bash
# Verify CloudTrail
aws cloudtrail describe-trails --region ap-southeast-4

# Check Config service
aws configservice describe-configuration-recorders --region ap-southeast-4

# Verify GuardDuty
aws guardduty list-detectors --region ap-southeast-4

# Check Security Hub
aws securityhub get-enabled-standards --region ap-southeast-4

# List KMS keys
aws kms list-keys --region ap-southeast-4
```

### 2.3 SNS Notifications Test

**Expected Results:**
- ✅ SNS topics created for different notification types
- ✅ Email subscriptions configured
- ✅ Lambda function for Slack integration (if enabled)

**Validation Commands:**
```bash
# List SNS topics
aws sns list-topics --region ap-southeast-4

# Check subscriptions
aws sns list-subscriptions --region ap-southeast-4

# Test notification
aws sns publish \
  --topic-arn "arn:aws:sns:ap-southeast-4:ACCOUNT-ID:epic-shared-infrastructure-alerts" \
  --message "Test notification from EPiC Infrastructure" \
  --region ap-southeast-4
```

## 3. Phase II Testing (Staging Environment)

### 3.1 Web Application Module Test

```bash
cd terraform/environments/staging

# Initialize and plan
terraform init
terraform plan -var="notification_email=$NOTIFICATION_EMAIL"

# Apply staging infrastructure
terraform apply -var="notification_email=$NOTIFICATION_EMAIL" -auto-approve
```

**Expected Results:**
- ✅ Auto Scaling Group with Launch Template
- ✅ Application Load Balancer with target group
- ✅ Security groups allowing only necessary traffic
- ✅ CloudWatch alarms for scaling policies

**Validation Commands:**
```bash
# Verify Auto Scaling Group
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names "epic-staging-web-asg" \
  --region ap-southeast-4

# Check Load Balancer
aws elbv2 describe-load-balancers \
  --names "epic-staging-web-alb" \
  --region ap-southeast-4

# Test health check endpoint
ALB_DNS=$(aws elbv2 describe-load-balancers \
  --names "epic-staging-web-alb" \
  --query 'LoadBalancers[0].DNSName' \
  --output text \
  --region ap-southeast-4)

curl -I http://$ALB_DNS/
```

### 3.2 React Hosting Module Test

**Expected Results:**
- ✅ S3 bucket configured for static hosting
- ✅ CloudFront distribution for global CDN
- ✅ Proper caching and security headers
- ✅ Optional ECS service for serverless hosting

**Validation Commands:**
```bash
# Verify S3 bucket
aws s3api list-buckets --query "Buckets[?contains(Name, 'epic-staging-react')]"

# Check CloudFront distribution
aws cloudfront list-distributions \
  --query "DistributionList.Items[?contains(Comment, 'epic-staging')]" \
  --region ap-southeast-4

# Test static website (if enabled)
CLOUDFRONT_DOMAIN=$(aws cloudfront list-distributions \
  --query "DistributionList.Items[?contains(Comment, 'epic-staging')].DomainName" \
  --output text)

curl -I https://$CLOUDFRONT_DOMAIN/
```

### 3.3 Database Backup Module Test

**Expected Results:**
- ✅ S3 bucket for backup storage
- ✅ Lambda function for automated backups
- ✅ EventBridge rule for scheduling
- ✅ Cross-region replication (if enabled)

**Validation Commands:**
```bash
# Verify backup bucket
aws s3api list-buckets --query "Buckets[?contains(Name, 'epic-staging-backups')]"

# Check Lambda function
aws lambda list-functions \
  --query "Functions[?contains(FunctionName, 'epic-staging-backup')]" \
  --region ap-southeast-4

# Verify EventBridge rule
aws events list-rules \
  --name-prefix "epic-staging-backup" \
  --region ap-southeast-4

# Test manual backup trigger
aws lambda invoke \
  --function-name "epic-staging-backup-lambda" \
  --payload '{"test": true}' \
  /tmp/backup-test-output.json \
  --region ap-southeast-4
```

### 3.4 Monitoring and Alerting Module Test

**Expected Results:**
- ✅ CloudWatch dashboards for infrastructure, security, and applications
- ✅ Comprehensive alarm configuration
- ✅ Log groups with appropriate retention
- ✅ Custom metrics and insights queries

**Validation Commands:**
```bash
# List CloudWatch dashboards
aws cloudwatch list-dashboards --region ap-southeast-4

# Check alarms
aws cloudwatch describe-alarms \
  --alarm-name-prefix "epic-staging" \
  --region ap-southeast-4

# Verify log groups
aws logs describe-log-groups \
  --log-group-name-prefix "/aws/lambda/epic-staging" \
  --region ap-southeast-4

# Test dashboard access
echo "Dashboard URLs:"
terraform output -raw cloudwatch_dashboard_urls
```

### 3.5 Cost Optimization Module Test

**Expected Results:**
- ✅ AWS Budgets configured with alerts
- ✅ Cost anomaly detection enabled
- ✅ Lambda function for cost recommendations
- ✅ Cost dashboard and reporting

**Validation Commands:**
```bash
# List budgets
aws budgets describe-budgets --account-id $(aws sts get-caller-identity --query 'Account' --output text)

# Check cost anomaly detectors
aws ce get-anomaly-detectors --region ap-southeast-4

# Verify cost optimization Lambda
aws lambda list-functions \
  --query "Functions[?contains(FunctionName, 'epic-staging-cost-optimizer')]" \
  --region ap-southeast-4

# Test cost analysis
aws lambda invoke \
  --function-name "epic-staging-cost-optimizer" \
  --payload '{"test": true}' \
  /tmp/cost-test-output.json \
  --region ap-southeast-4
```

### 3.6 Compliance Monitoring Module Test

**Expected Results:**
- ✅ AWS Config rules for compliance checking
- ✅ Security Hub standards enabled
- ✅ Custom compliance Lambda function
- ✅ Compliance dashboard and reporting

**Validation Commands:**
```bash
# List Config rules
aws configservice describe-config-rules \
  --config-rule-names epic-staging-s3-encryption epic-staging-cloudtrail-enabled \
  --region ap-southeast-4

# Check Security Hub standards
aws securityhub get-enabled-standards --region ap-southeast-4

# Verify compliance Lambda
aws lambda list-functions \
  --query "Functions[?contains(FunctionName, 'epic-staging-compliance-checker')]" \
  --region ap-southeast-4

# Test compliance check
aws lambda invoke \
  --function-name "epic-staging-compliance-checker" \
  --payload '{"test": true}' \
  /tmp/compliance-test-output.json \
  --region ap-southeast-4
```

## 4. Production Environment Testing

### 4.1 Production Deployment

```bash
cd terraform/environments/production

# Initialize and plan
terraform init
terraform plan -var="notification_email=$NOTIFICATION_EMAIL"

# Apply production infrastructure (with careful review)
terraform apply -var="notification_email=$NOTIFICATION_EMAIL"
```

### 4.2 Production-Specific Validations

**High Availability Checks:**
```bash
# Verify multi-AZ deployment
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names "epic-production-web-asg" \
  --query 'AutoScalingGroups[0].AvailabilityZones' \
  --region ap-southeast-4

# Check minimum instance count
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names "epic-production-web-asg" \
  --query 'AutoScalingGroups[0].{Min:MinSize,Desired:DesiredCapacity,Max:MaxSize}' \
  --region ap-southeast-4
```

**Enhanced Security Checks:**
```bash
# Verify deletion protection
aws rds describe-db-instances \
  --query 'DBInstances[?contains(DBInstanceIdentifier, `epic-production`)].DeletionProtection' \
  --region ap-southeast-4

# Check enhanced monitoring
aws rds describe-db-instances \
  --query 'DBInstances[?contains(DBInstanceIdentifier, `epic-production`)].{MonitoringInterval:MonitoringInterval,PerformanceInsights:PerformanceInsightsEnabled}' \
  --region ap-southeast-4
```

## 5. Integration Testing

### 5.1 End-to-End Workflow Test

1. **Application Deployment Simulation:**
```bash
# Simulate application deployment to staging
aws s3 sync ./test-app/ s3://epic-staging-react-hosting/

# Invalidate CloudFront cache
DISTRIBUTION_ID=$(terraform output -raw react_cloudfront_distribution_id)
aws cloudfront create-invalidation \
  --distribution-id $DISTRIBUTION_ID \
  --paths "/*" \
  --region ap-southeast-4
```

2. **Monitoring Integration Test:**
```bash
# Generate test metrics
aws cloudwatch put-metric-data \
  --namespace "EPiC/Testing" \
  --metric-data MetricName=TestMetric,Value=100,Unit=Count \
  --region ap-southeast-4

# Trigger test alarm
aws cloudwatch set-alarm-state \
  --alarm-name "epic-staging-high-cpu" \
  --state-value ALARM \
  --state-reason "Testing alarm notification" \
  --region ap-southeast-4
```

3. **Backup and Recovery Test:**
```bash
# Trigger manual backup
aws lambda invoke \
  --function-name "epic-staging-backup-lambda" \
  --payload '{"manual_trigger": true}' \
  /tmp/manual-backup-result.json \
  --region ap-southeast-4

# Verify backup creation
aws s3 ls s3://epic-staging-backups/ --recursive
```

### 5.2 Cross-Environment Communication Test

```bash
# Test shared resource access from staging
cd terraform/environments/staging
terraform refresh

# Verify shared networking outputs
terraform output vpc_id
terraform output private_subnet_ids

# Test notification flow
aws sns publish \
  --topic-arn $(terraform output -raw notification_topic_arn) \
  --message "Integration test: Cross-environment notification" \
  --region ap-southeast-4
```

## 6. Security and Compliance Validation

### 6.1 Security Scanning

Use the Terraform MCP server's Checkov integration:

```bash
# Scan shared environment
cd terraform/environments/shared
terraform plan -out=tfplan
terraform show -json tfplan > tfplan.json
checkov -f tfplan.json --framework terraform

# Scan staging environment
cd ../staging
terraform plan -out=tfplan
terraform show -json tfplan > tfplan.json
checkov -f tfplan.json --framework terraform

# Scan production environment
cd ../production
terraform plan -out=tfplan
terraform show -json tfplan > tfplan.json
checkov -f tfplan.json --framework terraform
```

### 6.2 Compliance Validation

```bash
# Run AWS Config compliance evaluation
aws configservice start-config-rules-evaluation \
  --config-rule-names epic-staging-s3-encryption epic-staging-cloudtrail-enabled \
  --region ap-southeast-4

# Check Security Hub findings
aws securityhub get-findings \
  --filters '{"ProductName": [{"Value": "Config", "Comparison": "EQUALS"}]}' \
  --region ap-southeast-4

# Generate compliance report
aws lambda invoke \
  --function-name "epic-staging-compliance-checker" \
  --payload '{"generate_report": true}' \
  /tmp/compliance-report.json \
  --region ap-southeast-4
```

### 6.3 Network Security Test

```bash
# Verify security group rules
aws ec2 describe-security-groups \
  --filters "Name=tag:Project,Values=epic" \
  --query 'SecurityGroups[*].{GroupId:GroupId,GroupName:GroupName,InboundRules:IpPermissions}' \
  --region ap-southeast-4

# Test network isolation
# (This should be done from instances within the VPC)
aws ssm start-session --target i-1234567890abcdef0 --region ap-southeast-4
```

## 7. Disaster Recovery Testing

### 7.1 Backup Verification

```bash
# List all backups
aws s3 ls s3://epic-staging-backups/ --recursive --human-readable

# Verify cross-region replication (if enabled)
aws s3 ls s3://epic-staging-backups-replica/ --recursive --human-readable --region ap-southeast-2

# Test backup restoration process
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier epic-staging-test-restore \
  --db-snapshot-identifier epic-staging-backup-$(date +%Y%m%d) \
  --db-instance-class db.t3.micro \
  --region ap-southeast-4 \
  --dry-run
```

### 7.2 Infrastructure Recovery Test

```bash
# Simulate infrastructure failure by destroying and recreating
cd terraform/environments/staging

# Export current state
terraform show > pre-recovery-state.txt

# Destroy specific resources (for testing)
terraform destroy -target=module.web_application.aws_autoscaling_group.web_asg

# Recreate destroyed resources
terraform apply -auto-approve

# Compare state
terraform show > post-recovery-state.txt
diff pre-recovery-state.txt post-recovery-state.txt
```

## 8. Performance and Load Testing

### 8.1 Application Load Test

```bash
# Install Apache Bench (if not available)
# Use hey for more modern load testing
go install github.com/rakyll/hey@latest

# Test ALB endpoint
ALB_URL=$(terraform output -raw web_application_url)
hey -n 1000 -c 10 http://$ALB_URL/

# Test CloudFront endpoint
CLOUDFRONT_URL=$(terraform output -raw react_static_website_url)
hey -n 1000 -c 10 https://$CLOUDFRONT_URL/
```

### 8.2 Auto Scaling Test

```bash
# Generate load to trigger auto scaling
# Monitor scaling activities
aws autoscaling describe-scaling-activities \
  --auto-scaling-group-name "epic-staging-web-asg" \
  --region ap-southeast-4

# Watch instance count changes
watch -n 30 'aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names "epic-staging-web-asg" \
  --query "AutoScalingGroups[0].{Desired:DesiredCapacity,Running:length(Instances[?LifecycleState==\`InService\`])}" \
  --region ap-southeast-4'
```

## 9. Cost Analysis and Optimization

### 9.1 Cost Monitoring Validation

```bash
# Check current costs
aws ce get-cost-and-usage \
  --time-period Start=2024-09-01,End=2024-09-30 \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE

# Verify budget alerts
aws budgets describe-budget \
  --account-id $(aws sts get-caller-identity --query 'Account' --output text) \
  --budget-name "epic-staging-monthly-budget"

# Check cost anomaly detection
aws ce get-anomalies \
  --date-interval Start=2024-09-01,End=2024-09-30
```

### 9.2 Resource Optimization Check

```bash
# Analyze unused resources
aws support describe-trusted-advisor-checks \
  --language en \
  --query 'checks[?category==`cost_optimizing`]'

# Check Reserved Instance recommendations
aws ce get-reservation-purchase-recommendation \
  --service EC2-Instance \
  --payment-option PARTIAL_UPFRONT \
  --term-in-years ONE_YEAR
```

## 10. Test Results Documentation

### 10.1 Create Test Report

After completing all tests, document the results:

```bash
# Generate comprehensive test report
cat > test-results-$(date +%Y%m%d).md << EOF
# EPiC Infrastructure Test Results - $(date +%Y-%m-%d)

## Test Summary
- **Total Tests Executed:** X
- **Passed:** Y
- **Failed:** Z
- **Test Duration:** N hours

## Environment Status
- **Shared Environment:** ✅ Deployed and Validated
- **Staging Environment:** ✅ Deployed and Validated
- **Production Environment:** ✅ Deployed and Validated

## Module Test Results
$(terraform output -raw staging_environment_summary)
$(terraform output -raw production_environment_summary)

## Security Compliance
- **AWS Config Rules:** All passing
- **Security Hub Standards:** Enabled and monitoring
- **Checkov Scan:** No critical issues

## Performance Metrics
- **Load Test Results:** ALB handling 1000 concurrent requests
- **Auto Scaling:** Triggered successfully under load
- **Response Times:** < 500ms average

## Cost Analysis
- **Monthly Budget:** Within limits
- **Cost Anomalies:** None detected
- **Optimization Opportunities:** X recommendations generated

## Next Steps
1. Monitor production environment for 24 hours
2. Set up regular compliance reporting
3. Schedule monthly cost optimization reviews
EOF
```

### 10.2 Cleanup Test Resources (Optional)

```bash
# Remove test resources but keep main infrastructure
terraform destroy -target=aws_db_instance.test_restore

# Clear test files
rm -f /tmp/*-test-output.json
rm -f tfplan tfplan.json
```

## 11. Ongoing Monitoring Setup

### 11.1 Automated Health Checks

```bash
# Set up cron job for daily health checks
cat > daily-health-check.sh << 'EOF'
#!/bin/bash
# Daily EPiC Infrastructure Health Check

echo "=== EPiC Infrastructure Health Check - $(date) ===" >> /var/log/epic-health-check.log

# Check ALB health
curl -s -o /dev/null -w "%{http_code}" http://$(terraform output -raw web_application_url)/ >> /var/log/epic-health-check.log

# Check CloudFront health
curl -s -o /dev/null -w "%{http_code}" https://$(terraform output -raw react_static_website_url)/ >> /var/log/epic-health-check.log

# Check budget status
aws budgets describe-budget --account-id $(aws sts get-caller-identity --query 'Account' --output text) --budget-name "epic-staging-monthly-budget" >> /var/log/epic-health-check.log 2>&1

echo "Health check completed" >> /var/log/epic-health-check.log
EOF

chmod +x daily-health-check.sh
# Add to crontab: 0 6 * * * /path/to/daily-health-check.sh
```

### 11.2 Monitoring Dashboard URLs

Access these URLs to monitor your infrastructure:

```bash
echo "=== EPiC Infrastructure Monitoring URLs ==="
echo "CloudWatch Dashboards:"
terraform output -raw cloudwatch_dashboard_urls

echo -e "\nCost Management:"
terraform output -raw cost_dashboard_url

echo -e "\nAWS Console Links:"
terraform output -raw aws_console_links
```

---

## Success Criteria

The testing is considered successful when:

- ✅ All Terraform deployments complete without errors
- ✅ All AWS resources are created and properly configured
- ✅ Security scans pass with no critical vulnerabilities
- ✅ Compliance checks meet organizational requirements
- ✅ Load testing demonstrates expected performance
- ✅ Backup and recovery procedures work correctly
- ✅ Cost monitoring and alerting function properly
- ✅ All notification systems send alerts successfully

## Troubleshooting

Common issues and solutions:

1. **State Locking Issues:** Use `terraform force-unlock <LOCK_ID>`
2. **Permission Errors:** Verify IAM roles and policies
3. **Resource Limits:** Check AWS service quotas
4. **Network Connectivity:** Verify security group rules and NACLs
5. **Cost Overruns:** Review resource sizes and scaling policies

For additional support, refer to the module README files and AWS documentation.