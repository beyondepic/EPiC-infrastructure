#!/bin/bash

# EPiC Infrastructure - Production Environment Deployment Script
# This script deploys the production environment with enhanced safety checks

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="epic"
ENVIRONMENT="production"
AWS_REGION="ap-southeast-4"

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

# Function to require confirmation for production
require_confirmation() {
    local message="$1"
    echo ""
    echo -e "${YELLOW}⚠️  PRODUCTION DEPLOYMENT WARNING ⚠️${NC}"
    echo "You are about to deploy to the PRODUCTION environment."
    echo "$message"
    echo ""
    echo "This action will:"
    echo "- Create or modify production infrastructure"
    echo "- Potentially affect live users and services"
    echo "- Incur AWS costs"
    echo ""
    read -p "Are you absolutely sure you want to proceed? Type 'YES' to continue: " confirm

    if [[ "$confirm" != "YES" ]]; then
        print_warning "Production deployment cancelled."
        exit 0
    fi
}

# Function to check staging validation
check_staging_validation() {
    print_status "Checking staging environment validation..."

    if [ ! -f "scripts/validate-infrastructure.sh" ]; then
        print_error "Validation script not found. Cannot verify staging environment."
        exit 1
    fi

    print_status "Running staging validation..."
    if ./scripts/validate-infrastructure.sh staging; then
        print_success "Staging environment validation passed"
    else
        print_error "Staging environment validation failed"
        echo ""
        echo "Please fix staging environment issues before deploying to production."
        exit 1
    fi
}

# Function to check security compliance
check_security_compliance() {
    print_status "Running security compliance checks..."

    # Check if checkov is available
    if command -v checkov &> /dev/null; then
        print_status "Running Checkov security scan..."

        # Run security scan on production configuration
        if checkov --directory terraform/environments/production --framework terraform --quiet; then
            print_success "Security scan passed"
        else
            print_error "Security scan failed"
            echo ""
            echo "Please fix security issues before deploying to production."
            echo "Run: checkov --directory terraform/environments/production --framework terraform"
            exit 1
        fi
    else
        print_warning "Checkov not found. Skipping automated security scan."
        read -p "Do you want to continue without security scanning? (y/N): " confirm
        if [[ "$confirm" != [yY] ]]; then
            exit 1
        fi
    fi
}

# Function to validate terraform configuration
validate_terraform_config() {
    print_status "Validating Terraform configuration..."

    cd terraform/environments/production

    # Check if terraform.tfvars exists
    if [ ! -f terraform.tfvars ]; then
        print_error "terraform.tfvars not found in production environment"
        print_status "Creating from template..."

        if [ -f "../staging/terraform.tfvars.sample" ]; then
            cp "../staging/terraform.tfvars.sample" terraform.tfvars

            # Update environment-specific values
            sed -i '' 's/environment = "staging"/environment = "production"/' terraform.tfvars
            sed -i '' 's/monthly_budget_limit = 200/monthly_budget_limit = 1000/' terraform.tfvars
            sed -i '' 's/instance_type = "t3.small"/instance_type = "t3.medium"/' terraform.tfvars
            sed -i '' 's/min_capacity = 1/min_capacity = 2/' terraform.tfvars
            sed -i '' 's/max_capacity = 2/max_capacity = 6/' terraform.tfvars
            sed -i '' 's/desired_capacity = 1/desired_capacity = 2/' terraform.tfvars
            sed -i '' 's/enable_ri_recommendations = false/enable_ri_recommendations = true/' terraform.tfvars
            sed -i '' 's/pci_dss_standard = false/pci_dss_standard = true/' terraform.tfvars

            print_warning "terraform.tfvars created from template with production defaults."
            print_warning "Please review and update with your production values before continuing."
            print_warning "Key items to verify:"
            echo "  - notification_email addresses"
            echo "  - SSL certificate ARNs (if using custom domains)"
            echo "  - Budget limits and thresholds"
            echo "  - Compliance requirements"
            echo ""
            read -p "Press Enter after updating terraform.tfvars..."
        else
            print_error "No template found. Please create terraform.tfvars manually."
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

    cd ../../..
}

# Function to create backup of existing state
backup_state() {
    print_status "Creating backup of existing Terraform state..."

    cd terraform/environments/production

    # Check if state exists
    if terraform state list > /dev/null 2>&1; then
        local backup_dir="../../../backups/$(date +%Y%m%d-%H%M%S)"
        mkdir -p "$backup_dir"

        # Export current state
        terraform show -json > "$backup_dir/terraform-state-backup.json"

        # Save current terraform.tfvars
        cp terraform.tfvars "$backup_dir/"

        print_success "State backup created in $backup_dir"
    else
        print_status "No existing state found, skipping backup"
    fi

    cd ../../..
}

# Function to plan deployment with review
plan_deployment() {
    print_status "Planning production deployment..."

    cd terraform/environments/production

    # Generate plan
    terraform plan -out=production.tfplan

    echo ""
    echo -e "${YELLOW}📋 DEPLOYMENT PLAN REVIEW${NC}"
    echo "Please carefully review the Terraform plan above."
    echo ""
    echo "Key items to verify:"
    echo "- No unexpected resource deletions"
    echo "- Resource configurations match production requirements"
    echo "- No hardcoded sensitive values"
    echo "- Backup and monitoring systems are included"
    echo ""

    read -p "Does the plan look correct? (y/N): " plan_confirm
    if [[ "$plan_confirm" != [yY] ]]; then
        rm -f production.tfplan
        print_warning "Deployment cancelled due to plan review."
        exit 0
    fi

    cd ../../..
}

# Function to deploy with monitoring
deploy_production() {
    print_status "Deploying to production environment..."

    cd terraform/environments/production

    require_confirmation "This will apply the planned changes to production infrastructure."

    # Apply the plan
    print_status "Applying Terraform plan..."
    if terraform apply production.tfplan; then
        print_success "Production deployment completed successfully!"

        # Clean up plan file
        rm -f production.tfplan

        # Display key outputs
        print_status "Production Environment Summary:"
        terraform output -json | jq -r '.production_environment_summary.value | to_entries[] | "  \(.key): \(.value)"' 2>/dev/null || echo "  (outputs not available)"

    else
        print_error "Production deployment failed!"
        rm -f production.tfplan
        exit 1
    fi

    cd ../../..
}

# Function to run post-deployment validation
run_post_deployment_validation() {
    print_status "Running post-deployment validation..."

    # Wait a moment for resources to stabilize
    sleep 30

    if ./scripts/validate-infrastructure.sh production; then
        print_success "Post-deployment validation passed!"
    else
        print_warning "Post-deployment validation failed. Please review the issues."
        print_warning "This doesn't necessarily mean the deployment failed, but indicates areas needing attention."
    fi
}

# Function to configure monitoring alerts
configure_monitoring() {
    print_status "Configuring production monitoring..."

    cd terraform/environments/production

    # Get SNS topic ARN for notifications
    local shared_topic_arn
    shared_topic_arn=$(cd ../shared && terraform output -raw notification_topic_arn 2>/dev/null || echo "")

    if [ -n "$shared_topic_arn" ]; then
        print_status "SNS notifications are configured with topic: $shared_topic_arn"

        # Verify SNS subscriptions
        local subscription_count
        subscription_count=$(aws sns list-subscriptions-by-topic \
            --topic-arn "$shared_topic_arn" \
            --query 'Subscriptions | length(@)' \
            --output text)

        if [ "$subscription_count" -gt 0 ]; then
            print_success "Found $subscription_count SNS subscription(s)"
        else
            print_warning "No SNS subscriptions found. Consider adding email subscriptions for alerts."
        fi
    else
        print_warning "Could not verify SNS topic configuration"
    fi

    # Check CloudWatch dashboard URLs
    local dashboard_urls
    dashboard_urls=$(terraform output -raw cloudwatch_dashboard_urls 2>/dev/null || echo "")

    if [ -n "$dashboard_urls" ]; then
        print_success "CloudWatch dashboards are available"
        echo "  Dashboard URLs have been configured (check terraform outputs)"
    fi

    cd ../../..
}

# Function to display next steps
show_production_next_steps() {
    print_success "🎉 Production environment deployment completed!"
    echo ""
    echo -e "${BLUE}📋 Post-Deployment Checklist:${NC}"
    echo ""
    echo "🔒 Security & Compliance:"
    echo "  □ Review Security Hub findings and address any issues"
    echo "  □ Verify AWS Config rules are passing"
    echo "  □ Check GuardDuty for any threats or anomalies"
    echo "  □ Confirm CloudTrail logging is active"
    echo ""
    echo "📊 Monitoring & Alerting:"
    echo "  □ Test SNS notification delivery"
    echo "  □ Review CloudWatch dashboard data"
    echo "  □ Verify all alarms are in expected states"
    echo "  □ Set up additional custom metrics if needed"
    echo ""
    echo "💰 Cost Management:"
    echo "  □ Review budget alerts and thresholds"
    echo "  □ Check cost anomaly detection settings"
    echo "  □ Monitor Reserved Instance recommendations"
    echo "  □ Set up monthly cost review process"
    echo ""
    echo "🚀 Application Deployment:"
    echo "  □ Deploy your application to the new ALB target group"
    echo "  □ Upload React application assets to S3"
    echo "  □ Configure DNS to point to CloudFront/ALB"
    echo "  □ Test application functionality end-to-end"
    echo ""
    echo "🔄 Ongoing Maintenance:"
    echo "  □ Schedule regular infrastructure reviews"
    echo "  □ Set up automated backup verification"
    echo "  □ Plan disaster recovery testing"
    echo "  □ Document runbooks for common operations"
    echo ""
    echo -e "${BLUE}🔗 Quick Links:${NC}"

    cd terraform/environments/production

    # Display console links if available
    local console_links
    console_links=$(terraform output -raw aws_console_links 2>/dev/null || echo "")

    if [ -n "$console_links" ]; then
        echo "  AWS Console links are available in terraform outputs"
        echo "  Run: cd terraform/environments/production && terraform output aws_console_links"
    fi

    # Display cost dashboard URL
    local cost_dashboard
    cost_dashboard=$(terraform output -raw cost_dashboard_url 2>/dev/null || echo "")

    if [ -n "$cost_dashboard" ]; then
        echo "  Cost Dashboard: $cost_dashboard"
    fi

    cd ../../..

    echo ""
    echo -e "${GREEN}🎯 Your EPiC Infrastructure is now live in production!${NC}"
    echo ""
    echo -e "${YELLOW}⚠️  Remember:${NC}"
    echo "  - Always test changes in staging first"
    echo "  - Use terraform plan before any production changes"
    echo "  - Monitor costs and security alerts regularly"
    echo "  - Keep your Terraform state secure and backed up"
}

# Main execution
main() {
    echo -e "${GREEN}EPiC Infrastructure - Production Deployment${NC}"
    echo "============================================"
    echo ""

    # Check if we're in the right directory
    if [ ! -d "terraform" ]; then
        print_error "Please run this script from the repository root directory."
        exit 1
    fi

    # Parse command line arguments
    SKIP_STAGING_CHECK=false
    SKIP_SECURITY_CHECK=false
    FORCE_DEPLOY=false

    while [[ $# -gt 0 ]]; do
        case $1 in
            --skip-staging-check)
                SKIP_STAGING_CHECK=true
                shift
                ;;
            --skip-security-check)
                SKIP_SECURITY_CHECK=true
                shift
                ;;
            --force)
                FORCE_DEPLOY=true
                shift
                ;;
            --help|-h)
                echo "Usage: $0 [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  --skip-staging-check   Skip staging environment validation"
                echo "  --skip-security-check  Skip security compliance checks"
                echo "  --force               Skip all confirmation prompts (USE WITH CAUTION)"
                echo "  --help, -h            Show this help message"
                echo ""
                echo "IMPORTANT: This script deploys to PRODUCTION environment."
                echo "Always test changes in staging first!"
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                echo "Use --help for usage information."
                exit 1
                ;;
        esac
    done

    # Initial safety confirmation
    if [ "$FORCE_DEPLOY" != true ]; then
        require_confirmation "You are starting the production deployment process."
    fi

    # Pre-deployment checks
    if [ "$SKIP_STAGING_CHECK" != true ]; then
        check_staging_validation
        echo ""
    fi

    if [ "$SKIP_SECURITY_CHECK" != true ]; then
        check_security_compliance
        echo ""
    fi

    validate_terraform_config
    echo ""

    backup_state
    echo ""

    plan_deployment
    echo ""

    deploy_production
    echo ""

    configure_monitoring
    echo ""

    run_post_deployment_validation
    echo ""

    show_production_next_steps
}

# Run main function with all arguments
main "$@"