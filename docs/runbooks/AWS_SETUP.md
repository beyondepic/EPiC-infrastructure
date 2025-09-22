# AWS S3 Backup Setup Guide

This guide covers setting up AWS S3 integration for automatic database backups.

## 📋 Prerequisites

- AWS S3 bucket: `nestedphoenix` (in ap-southeast-4 region)
- AWS CLI installed on EC2 instances
- IAM permissions for S3 access

## 🔧 Setup Steps

### 1. Create/Configure S3 Bucket

```bash
# Create bucket if it doesn't exist
aws s3 mb s3://nestedphoenix --region ap-southeast-4

# Create backup folder structure
aws s3api put-object --bucket nestedphoenix --key backups/deploy/ --region ap-southeast-4
aws s3api put-object --bucket nestedphoenix --key backups/deploy-staging/ --region ap-southeast-4
```

### 2. Apply IAM Policy

#### Option A: Update existing EC2 IAM Role
If your EC2 instance has an IAM role, add this policy to it:

1. Go to AWS IAM Console → Roles
2. Find your EC2 instance role
3. Attach the policy from `docs/aws-iam-policy.json`

#### Option B: Create IAM User (if no role exists)

```bash
# Create IAM user for backups
aws iam create-user --user-name nestedphoenix-backup-user

# Attach the policy
aws iam put-user-policy --user-name nestedphoenix-backup-user \
  --policy-name NestedPhoenixBackupPolicy \
  --policy-document file://docs/aws-iam-policy.json

# Create access keys
aws iam create-access-key --user-name nestedphoenix-backup-user
```

### 3. Configure AWS CLI on EC2

#### If using IAM Role (Recommended):
No additional configuration needed - the role permissions will be used automatically.

#### If using IAM User:
```bash
# SSH to your EC2 instance
ssh -i your-key.pem ubuntu@your-ec2-instance

# Configure AWS CLI
aws configure
# Enter:
# - Access Key ID: (from step 2)
# - Secret Access Key: (from step 2)
# - Default region: ap-southeast-4
# - Default output: json
```

### 4. Test S3 Access

```bash
# Test S3 access from EC2
aws s3 ls s3://nestedphoenix/backups/ --region ap-southeast-4

# Test upload
echo "test" > /tmp/test.txt
aws s3 cp /tmp/test.txt s3://nestedphoenix/backups/test/ --region ap-southeast-4
```

## 📁 S3 Backup Structure

Backups will be organized as:
```
s3://nestedphoenix/
└── backups/
    ├── deploy/              # Production backups
    │   ├── nestedphoenix_backup_20240315_120000.sql.gz
    │   └── nestedphoenix_backup_20240316_120000.sql.gz
    └── deploy-staging/      # Staging backups
        ├── nestedphoenix_backup_20240315_120000.sql.gz
        └── nestedphoenix_backup_20240316_120000.sql.gz
```

## 🔄 Automatic Deployment

After the next deployment via GitHub Actions, your backup scripts will:

1. ✅ **Deploy to EC2** automatically with your application
2. ✅ **Include S3 configuration** in environment variables
3. ✅ **Upload backups to S3** automatically after each backup

## 🛠️ Manual Setup on Existing EC2

If you want to set up backups on currently running EC2 instances:

```bash
# SSH to your EC2 instance
ssh -i your-key.pem ubuntu@your-ec2-instance

# Navigate to deployment directory
cd /home/ubuntu/deploy  # or /home/ubuntu/deploy-staging

# Add S3 config to .env file
echo "AWS_S3_BUCKET=nestedphoenix" >> .env
echo "COMPOSE_PROJECT_NAME=deploy" >> .env  # or "deploy-staging"

# Set up backup system
./scripts/setup_backup_system.sh --full

# Test backup with S3 upload
./scripts/backup_db.sh
```

## 🔍 Verification

### Check if S3 upload is working:
```bash
# View backup logs
tail -f logs/backup.log

# List S3 backups
aws s3 ls s3://nestedphoenix/backups/deploy/ --region ap-southeast-4
```

### Successful backup log should show:
```
[2024-03-15 12:00:00] Backup created successfully: /home/ubuntu/deploy/backups/nestedphoenix_backup_20240315_120000.sql.gz
[2024-03-15 12:00:01] Uploading backup to S3...
[2024-03-15 12:00:05] Backup uploaded to S3 successfully: s3://nestedphoenix/backups/deploy/nestedphoenix_backup_20240315_120000.sql.gz
```

## 💰 Cost Optimization (Optional)

### S3 Lifecycle Policy
Create a lifecycle policy to automatically transition old backups to cheaper storage:

```json
{
    "Rules": [
        {
            "ID": "NestedPhoenixBackupLifecycle",
            "Status": "Enabled",
            "Filter": {
                "Prefix": "backups/"
            },
            "Transitions": [
                {
                    "Days": 30,
                    "StorageClass": "STANDARD_IA"
                },
                {
                    "Days": 90,
                    "StorageClass": "GLACIER"
                }
            ],
            "Expiration": {
                "Days": 365
            }
        }
    ]
}
```

Apply with:
```bash
aws s3api put-bucket-lifecycle-configuration \
  --bucket nestedphoenix \
  --lifecycle-configuration file://lifecycle-policy.json \
  --region ap-southeast-4
```

## 🚨 Troubleshooting

### Common Issues:

#### 1. "Access Denied" errors
- Check IAM policy is correctly applied
- Verify bucket name and region are correct
- Ensure EC2 instance has the IAM role attached

#### 2. "AWS CLI not found"
```bash
# Install AWS CLI on EC2
sudo apt update
sudo apt install awscli
```

#### 3. "Region not specified"
- Backup script defaults to ap-southeast-4
- Override with: `export AWS_REGION=ap-southeast-4`

#### 4. Check AWS credentials
```bash
# Test AWS configuration
aws sts get-caller-identity
aws s3 ls --region ap-southeast-4
```

---

## 📞 Support

- AWS IAM Policy: `docs/aws-iam-policy.json`
- Backup Documentation: `docs/BACKUP_RESTORE.md`
- GitHub Issues: Report problems in the repository issues