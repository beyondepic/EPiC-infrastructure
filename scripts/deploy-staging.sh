#!/bin/bash

# EPiC Infrastructure - Staging Environment Deployment Script
# This script follows the comprehensive testing plan for deploying the staging environment

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="epic"
ENVIRONMENT="staging"
AWS_REGION="ap-southeast-4"
TERRAFORM_VERSION="1.6"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."

    # Check if AWS CLI is installed and configured
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi

    # Check if Terraform is installed
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install version $TERRAFORM_VERSION or higher."
        exit 1
    fi

    # Check Terraform version
    CURRENT_TF_VERSION=$(terraform version -json | jq -r '.terraform_version')
    print_status "Terraform version: $CURRENT_TF_VERSION"

    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials not configured. Please run 'aws configure'."
        exit 1
    fi

    # Get AWS account details
    AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
    AWS_USER_ARN=$(aws sts get-caller-identity --query 'Arn' --output text)
    print_status "AWS Account: $AWS_ACCOUNT_ID"
    print_status "AWS User: $AWS_USER_ARN"

    print_success "Prerequisites check completed!"
}

# Function to set up backend resources
setup_backend() {
    print_status "Setting up Terraform backend resources..."

    # Create S3 bucket for Terraform state (if not exists)
    BUCKET_NAME="${PROJECT_NAME}-terraform-state"
    if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
        print_warning "S3 bucket '$BUCKET_NAME' already exists."
    else
        print_status "Creating S3 bucket: $BUCKET_NAME"
        aws s3api create-bucket \
            --bucket "$BUCKET_NAME" \
            --region "$AWS_REGION" \
            --create-bucket-configuration LocationConstraint="$AWS_REGION"

        # Enable versioning
        aws s3api put-bucket-versioning \
            --bucket "$BUCKET_NAME" \
            --versioning-configuration Status=Enabled

        # Enable encryption
        aws s3api put-bucket-encryption \
            --bucket "$BUCKET_NAME" \
            --server-side-encryption-configuration '{
                "Rules": [{
                    "ApplyServerSideEncryptionByDefault": {
                        "SSEAlgorithm": "AES256"
                    }
                }]
            }'

        # Block public access
        aws s3api put-public-access-block \
            --bucket "$BUCKET_NAME" \
            --public-access-block-configuration \
            BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
    fi

    # Create DynamoDB table for state locking (if not exists)
    TABLE_NAME="${PROJECT_NAME}-terraform-locks"
    if aws dynamodb describe-table --table-name "$TABLE_NAME" &>/dev/null; then
        print_warning "DynamoDB table '$TABLE_NAME' already exists."
    else
        print_status "Creating DynamoDB table: $TABLE_NAME"
        aws dynamodb create-table \
            --table-name "$TABLE_NAME" \
            --attribute-definitions AttributeName=LockID,AttributeType=S \
            --key-schema AttributeName=LockID,KeyType=HASH \
            --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
            --region "$AWS_REGION"

        print_status "Waiting for table to be active..."
        aws dynamodb wait table-exists --table-name "$TABLE_NAME" --region "$AWS_REGION"
    fi

    print_success "Backend resources are ready!"
}

# Function to deploy shared environment
deploy_shared() {
    print_status "Deploying shared environment..."

    cd terraform/environments/shared

    # Check if terraform.tfvars exists
    if [ ! -f terraform.tfvars ]; then
        print_warning "terraform.tfvars not found. Please create it from terraform.tfvars.example"
        if [ -f terraform.tfvars.example ]; then
            print_status "Copying terraform.tfvars.example to terraform.tfvars"
            cp terraform.tfvars.example terraform.tfvars
            print_warning "Please update terraform.tfvars with your values before continuing."
            read -p "Press Enter to continue once you've updated terraform.tfvars..."
        fi
    fi

    # Initialize Terraform
    print_status "Initializing Terraform..."
    terraform init

    # Validate configuration
    print_status "Validating Terraform configuration..."
    terraform validate

    # Format code
    terraform fmt -recursive

    # Plan deployment
    print_status "Planning shared environment deployment..."
    terraform plan -out=shared.tfplan

    # Apply (with confirmation)
    echo -e "\n${YELLOW}Ready to deploy shared environment. This will create:${NC}"
    echo "- VPC with multi-tier subnet architecture"
    echo "- Security baseline (CloudTrail, Config, GuardDuty, Security Hub)"
    echo "- SNS notification topics"
    echo ""
    read -p "Do you want to proceed? (y/N): " confirm
    if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
        print_status "Applying shared environment..."
        terraform apply shared.tfplan
        print_success "Shared environment deployed successfully!"
    else
        print_warning "Deployment cancelled."
        exit 0
    fi

    # Clean up plan file
    rm -f shared.tfplan

    cd ../../..
}

# Function to run security scan
run_security_scan() {
    print_status "Running security scan with Checkov..."

    # Check if checkov is installed
    if ! command -v checkov &> /dev/null; then
        print_warning "Checkov is not installed. Installing..."
        pip3 install checkov
    fi

    # Run security scan on modules
    print_status "Scanning Terraform modules..."
    checkov --directory terraform/modules --framework terraform --output cli --quiet

    print_success "Security scan completed!"
}

# Function to deploy staging environment
deploy_staging() {
    print_status "Deploying staging environment..."

    cd terraform/environments/staging

    # Check if terraform.tfvars exists
    if [ ! -f terraform.tfvars ]; then
        print_warning "terraform.tfvars not found."
        if [ -f terraform.tfvars.sample ]; then
            print_status "Copying terraform.tfvars.sample to terraform.tfvars"
            cp terraform.tfvars.sample terraform.tfvars
            print_warning "Please update terraform.tfvars with your values before continuing."
            print_warning "Key fields to update:"
            echo "  - notification_email"
            echo "  - compliance_notification_email"
            echo "  - cost_anomaly_email"
            echo "  - notification_emails"
            read -p "Press Enter to continue once you've updated terraform.tfvars..."
        else
            print_error "terraform.tfvars.sample not found. Please create terraform.tfvars manually."
            exit 1
        fi
    fi

    # Initialize Terraform
    print_status "Initializing Terraform..."
    terraform init

    # Validate configuration
    print_status "Validating Terraform configuration..."
    terraform validate

    # Format code
    terraform fmt -recursive

    # Plan deployment
    print_status "Planning staging environment deployment..."
    terraform plan -out=staging.tfplan

    # Apply (with confirmation)
    echo -e "\n${YELLOW}Ready to deploy staging environment. This will create:${NC}"
    echo "- Web application infrastructure (ALB, ASG, EC2)"
    echo "- React hosting (S3, CloudFront)"
    echo "- Database backup automation"
    echo "- Monitoring and alerting (CloudWatch)"
    echo "- Cost optimization (Budgets, Cost Explorer)"
    echo "- Compliance monitoring (Config, Security Hub)"
    echo ""
    read -p "Do you want to proceed? (y/N): " confirm
    if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
        print_status "Applying staging environment..."
        terraform apply staging.tfplan
        print_success "Staging environment deployed successfully!"

        # Display useful outputs
        print_status "Deployment Summary:"
        terraform output -json | jq -r '.staging_environment_summary.value | to_entries[] | "  \(.key): \(.value)"'

        print_status "Console Links:"
        terraform output -json | jq -r '.aws_console_links.value | to_entries[] | "  \(.key): \(.value)"'

    else
        print_warning "Deployment cancelled."
        exit 0
    fi

    # Clean up plan file
    rm -f staging.tfplan

    cd ../../..
}

# Function to run post-deployment tests
run_post_deployment_tests() {
    print_status "Running post-deployment tests..."

    cd terraform/environments/staging

    # Test ALB endpoint
    if ALB_DNS=$(terraform output -raw web_application_url 2>/dev/null); then
        print_status "Testing ALB endpoint: $ALB_DNS"
        if curl -s --connect-timeout 10 --max-time 30 -I "http://$ALB_DNS/" > /dev/null; then
            print_success "ALB endpoint is responding"
        else
            print_warning "ALB endpoint is not responding (this may be normal if no application is deployed)"
        fi
    fi

    # Test CloudFront endpoint
    if CF_URL=$(terraform output -raw react_static_website_url 2>/dev/null); then
        print_status "Testing CloudFront endpoint: $CF_URL"
        if curl -s --connect-timeout 10 --max-time 30 -I "$CF_URL" > /dev/null; then
            print_success "CloudFront endpoint is responding"
        else
            print_warning "CloudFront endpoint is not responding (this may be normal if no content is uploaded)"
        fi
    fi

    # Verify AWS resources
    print_status "Verifying AWS resources..."

    # Check Auto Scaling Group
    if ASG_NAME=$(terraform output -raw autoscaling_group_name 2>/dev/null); then
        INSTANCE_COUNT=$(aws autoscaling describe-auto-scaling-groups \
            --auto-scaling-group-names "$ASG_NAME" \
            --query 'AutoScalingGroups[0].Instances | length(@)' \
            --output text)
        print_status "Auto Scaling Group '$ASG_NAME' has $INSTANCE_COUNT instance(s)"
    fi

    # Check S3 buckets
    S3_BUCKETS=$(aws s3api list-buckets --query "Buckets[?contains(Name, '$PROJECT_NAME-$ENVIRONMENT')].Name" --output text)
    if [ -n "$S3_BUCKETS" ]; then
        print_status "Created S3 buckets:"
        echo "$S3_BUCKETS" | tr '\t' '\n' | sed 's/^/  /'
    fi

    cd ../../..
    print_success "Post-deployment tests completed!"
}

# Function to display next steps
show_next_steps() {
    print_success "Staging environment deployment completed!"
    echo ""
    echo -e "${BLUE}Next Steps:${NC}"
    echo "1. Update your application deployment pipeline to use the new ALB endpoint"
    echo "2. Upload your React application to the S3 bucket for static hosting"
    echo "3. Configure your domain DNS to point to the CloudFront distribution"
    echo "4. Set up monitoring alerts by updating SNS subscriptions"
    echo "5. Review cost budgets and thresholds in AWS Cost Management"
    echo "6. Check Security Hub for any compliance findings"
    echo ""
    echo -e "${BLUE}Useful Commands:${NC}"
    echo "  # View all outputs:"
    echo "  cd terraform/environments/staging && terraform output"
    echo ""
    echo "  # Update infrastructure:"
    echo "  cd terraform/environments/staging && terraform plan && terraform apply"
    echo ""
    echo "  # Destroy infrastructure (when no longer needed):"
    echo "  cd terraform/environments/staging && terraform destroy"
    echo ""
    echo -e "${BLUE}Monitoring:${NC}"
    echo "  - CloudWatch Dashboards: $(cd terraform/environments/staging && terraform output -raw aws_console_links | jq -r '.cloudwatch_dashboards' 2>/dev/null || echo 'Check terraform outputs')"
    echo "  - Cost Dashboard: $(cd terraform/environments/staging && terraform output -raw cost_dashboard_url 2>/dev/null || echo 'Check terraform outputs')"
    echo "  - Security Hub: $(cd terraform/environments/staging && terraform output -raw aws_console_links | jq -r '.security_hub' 2>/dev/null || echo 'Check terraform outputs')"
}

# Main execution
main() {
    echo -e "${GREEN}EPiC Infrastructure - Staging Deployment${NC}"
    echo "========================================"
    echo ""

    # Check if we're in the right directory
    if [ ! -d "terraform" ]; then
        print_error "Please run this script from the repository root directory."
        exit 1
    fi

    # Parse command line arguments
    SKIP_PREREQ=false
    SKIP_BACKEND=false
    SKIP_SHARED=false
    SKIP_SECURITY=false
    SKIP_TESTS=false

    while [[ $# -gt 0 ]]; do
        case $1 in
            --skip-prereq)
                SKIP_PREREQ=true
                shift
                ;;
            --skip-backend)
                SKIP_BACKEND=true
                shift
                ;;
            --skip-shared)
                SKIP_SHARED=true
                shift
                ;;
            --skip-security)
                SKIP_SECURITY=true
                shift
                ;;
            --skip-tests)
                SKIP_TESTS=true
                shift
                ;;
            --help|-h)
                echo "Usage: $0 [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  --skip-prereq   Skip prerequisite checks"
                echo "  --skip-backend  Skip backend setup"
                echo "  --skip-shared   Skip shared environment deployment"
                echo "  --skip-security Skip security scanning"
                echo "  --skip-tests    Skip post-deployment tests"
                echo "  --help, -h      Show this help message"
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                echo "Use --help for usage information."
                exit 1
                ;;
        esac
    done

    # Run deployment steps
    if [ "$SKIP_PREREQ" != true ]; then
        check_prerequisites
        echo ""
    fi

    if [ "$SKIP_BACKEND" != true ]; then
        setup_backend
        echo ""
    fi

    if [ "$SKIP_SHARED" != true ]; then
        deploy_shared
        echo ""
    fi

    if [ "$SKIP_SECURITY" != true ]; then
        run_security_scan
        echo ""
    fi

    deploy_staging
    echo ""

    if [ "$SKIP_TESTS" != true ]; then
        run_post_deployment_tests
        echo ""
    fi

    show_next_steps
}

# Run main function with all arguments
main "$@"