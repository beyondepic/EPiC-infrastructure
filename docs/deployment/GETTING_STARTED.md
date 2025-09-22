# Getting Started with EPiC Infrastructure

This guide helps you deploy the SNS notifications infrastructure as your first step in setting up the EPiC infrastructure.

## 🚀 Quick Start

### 1. Prerequisites

Before deploying, ensure you have:

- [Terraform](https://www.terraform.io/downloads.html) >= 1.6 installed
- [AWS CLI](https://aws.amazon.com/cli/) configured with appropriate permissions
- Access to AWS account with admin privileges (for initial setup)

### 2. Initial AWS Setup

#### Create S3 Buckets for Terraform State

```bash
# Create staging state bucket
aws s3 mb s3://epic-terraform-state-staging --region ap-southeast-4

# Create production state bucket
aws s3 mb s3://epic-terraform-state-production --region ap-southeast-4

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket epic-terraform-state-staging \
  --versioning-configuration Status=Enabled

aws s3api put-bucket-versioning \
  --bucket epic-terraform-state-production \
  --versioning-configuration Status=Enabled
```

#### Create DynamoDB Table for State Locking

```bash
aws dynamodb create-table \
  --table-name epic-terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
  --region ap-southeast-4
```

### 3. Deploy SNS Notifications (Staging)

Start with staging environment:

```bash
# Navigate to staging environment
cd terraform/environments/staging

# Copy and customize variables
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your values
# Required: notification_email
# Optional: slack_webhook_url

# Initialize Terraform
terraform init

# Plan the deployment
terraform plan

# Apply the configuration
terraform apply
```

### 4. Test SNS Integration

After deployment, test the notifications:

```bash
# Get the topic ARN from output
TOPIC_ARN=$(terraform output -raw infrastructure_topic_arn)

# Send a test notification
aws sns publish \
  --topic-arn "$TOPIC_ARN" \
  --subject "Test Notification" \
  --message "This is a test message from EPiC infrastructure" \
  --region ap-southeast-4
```

### 5. Deploy to Production

Once staging is working:

```bash
# Navigate to production environment
cd ../production

# Copy and customize variables
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with production values
# Initialize and deploy
terraform init
terraform plan
terraform apply
```

## 📧 Email Configuration

### Required Email Setup

1. **Notification Email**: Infrastructure alerts (backups, failures, etc.)
2. **Application Email**: User-facing notifications (OTP, alerts, etc.)

### Email Subscription Confirmation

After deployment:
1. Check your email for AWS SNS subscription confirmation
2. Click the confirmation link in each email
3. Verify subscriptions in AWS Console: SNS → Topics → Subscriptions

## 🔧 Integration with Existing Systems

### Django Application Integration

Add to your `.env` files:

```bash
# Staging
AWS_SNS_REGION=ap-southeast-4
AWS_SNS_APPLICATION_TOPIC_ARN=arn:aws:sns:ap-southeast-4:ACCOUNT:epic-staging-app-notifications

# Production
AWS_SNS_REGION=ap-southeast-4
AWS_SNS_APPLICATION_TOPIC_ARN=arn:aws:sns:ap-southeast-4:ACCOUNT:epic-production-app-notifications
```

### GitHub Actions Integration

Add to your GitHub Actions workflows:

```yaml
# In your staging.yml workflow
- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v2
  with:
    aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
    aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
    aws-region: ap-southeast-4

- name: Send deployment notification
  run: |
    aws sns publish \
      --topic-arn "${{ secrets.AWS_SNS_INFRASTRUCTURE_TOPIC_ARN }}" \
      --subject "Deployment Complete: ${{ github.repository }}" \
      --message "Successfully deployed ${{ github.sha }} to staging"
```

### Required GitHub Secrets

Add these secrets to your repository:

```
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AWS_SNS_INFRASTRUCTURE_TOPIC_ARN_STAGING
AWS_SNS_INFRASTRUCTURE_TOPIC_ARN_PRODUCTION
AWS_SNS_APPLICATION_TOPIC_ARN_STAGING
AWS_SNS_APPLICATION_TOPIC_ARN_PRODUCTION
```

## 🔐 IAM Permissions

### Required AWS Permissions

Your AWS user/role needs these permissions for deployment:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "sns:*",
        "lambda:*",
        "iam:*",
        "logs:*",
        "s3:*",
        "dynamodb:*"
      ],
      "Resource": "*"
    }
  ]
}
```

### Application IAM Role

For your EC2 instances, create a role with this policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "sns:Publish"
      ],
      "Resource": [
        "arn:aws:sns:ap-southeast-4:*:epic-*-app-notifications"
      ]
    }
  ]
}
```

## 🧪 Testing & Verification

### 1. Verify Infrastructure

```bash
# Check if topics exist
aws sns list-topics --region ap-southeast-4 | grep epic

# Check subscriptions
aws sns list-subscriptions --region ap-southeast-4
```

### 2. Test Email Notifications

```bash
# Test infrastructure notifications
aws sns publish \
  --topic-arn "arn:aws:sns:ap-southeast-4:ACCOUNT:epic-staging-notifications" \
  --subject "Infrastructure Test" \
  --message "Testing infrastructure notifications" \
  --region ap-southeast-4

# Test application notifications
aws sns publish \
  --topic-arn "arn:aws:sns:ap-southeast-4:ACCOUNT:epic-staging-app-notifications" \
  --subject "Application Test" \
  --message "Testing application notifications" \
  --region ap-southeast-4
```

### 3. Test Slack Integration (if configured)

The Lambda function should automatically forward SNS messages to Slack. Check:

1. CloudWatch Logs: `/aws/lambda/epic-staging-slack-notifier`
2. Slack channel for received messages
3. Lambda function metrics in AWS Console

## 🔍 Troubleshooting

### Common Issues

#### 1. State Backend Access Denied
```bash
# Ensure S3 bucket exists and you have access
aws s3 ls s3://epic-terraform-state-staging --region ap-southeast-4
```

#### 2. Email Not Received
- Check spam folder
- Verify email address in terraform.tfvars
- Check SNS subscription status in AWS Console

#### 3. Slack Notifications Not Working
- Check Lambda function logs in CloudWatch
- Verify webhook URL is correct
- Ensure Lambda has proper permissions

#### 4. Permission Denied Errors
- Verify AWS credentials: `aws sts get-caller-identity`
- Check IAM policies attached to your user/role

### Getting Help

1. Check AWS CloudWatch Logs for error details
2. Review Terraform plan output before applying
3. Use `terraform validate` to check configuration syntax
4. Enable Terraform debug logging: `export TF_LOG=DEBUG`

## 📋 Next Steps

After SNS is working:

1. **Set up Database Backup Module**: For automated RDS backups with SNS notifications
2. **Deploy Web Application Module**: For EC2/ECS infrastructure with monitoring
3. **Configure CloudWatch Alarms**: To use your SNS topics for alerts
4. **Set up Budget Alerts**: To monitor AWS costs

Continue with the next modules in this order:
1. `database-backup` - Critical for data protection
2. `monitoring` - Essential for observability
3. `web-application` - For hosting your apps
4. `security` - Advanced security features

## 📖 Additional Resources

- [AWS SNS Documentation](https://docs.aws.amazon.com/sns/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [EPiC Infrastructure Architecture](/docs/architecture/EPiC-Infrastructure-PRD.md)
- [SNS Email System PRD](/docs/plans/SNS-Email-System-PRD.md)