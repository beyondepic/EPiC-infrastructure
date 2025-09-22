#!/bin/bash

# EPiC Infrastructure - Validation and Health Check Script
# This script validates the deployed infrastructure and performs health checks

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="epic"
AWS_REGION="ap-southeast-4"

# Counters for summary
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNING_CHECKS=0

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((PASSED_CHECKS++))
    ((TOTAL_CHECKS++))
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    ((WARNING_CHECKS++))
    ((TOTAL_CHECKS++))
}

print_error() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((FAILED_CHECKS++))
    ((TOTAL_CHECKS++))
}

print_check() {
    echo -e "${BLUE}[CHECK]${NC} $1"
}

# Function to validate environment parameter
validate_environment() {
    local env=$1
    if [[ "$env" != "staging" && "$env" != "production" ]]; then
        echo "Error: Environment must be 'staging' or 'production'"
        exit 1
    fi
}

# Function to check if Terraform state exists
check_terraform_state() {
    local environment=$1
    print_check "Checking Terraform state for $environment environment..."

    cd "terraform/environments/$environment"

    if terraform state list > /dev/null 2>&1; then
        print_success "Terraform state is accessible"
    else
        print_error "Terraform state is not accessible or empty"
        return 1
    fi

    cd ../../..
}

# Function to validate VPC and networking
validate_networking() {
    local environment=$1
    print_check "Validating VPC and networking infrastructure..."

    # Get VPC ID from shared environment
    local vpc_id
    if environment == "staging" || environment == "production"; then
        cd terraform/environments/shared
        vpc_id=$(terraform output -raw vpc_id 2>/dev/null || echo "")
        cd ../../..
    fi

    if [ -n "$vpc_id" ]; then
        # Check if VPC exists
        if aws ec2 describe-vpcs --vpc-ids "$vpc_id" --region "$AWS_REGION" > /dev/null 2>&1; then
            print_success "VPC $vpc_id exists and is accessible"

            # Check subnets
            local subnet_count
            subnet_count=$(aws ec2 describe-subnets \
                --filters "Name=vpc-id,Values=$vpc_id" \
                --query 'Subnets | length(@)' \
                --output text \
                --region "$AWS_REGION")

            if [ "$subnet_count" -ge 6 ]; then
                print_success "Found $subnet_count subnets (expected >= 6)"
            else
                print_warning "Found only $subnet_count subnets (expected >= 6)"
            fi

            # Check NAT Gateways
            local nat_count
            nat_count=$(aws ec2 describe-nat-gateways \
                --filter "Name=vpc-id,Values=$vpc_id" \
                --query 'NatGateways[?State==`available`] | length(@)' \
                --output text \
                --region "$AWS_REGION")

            if [ "$nat_count" -gt 0 ]; then
                print_success "Found $nat_count NAT Gateway(s)"
            else
                print_warning "No NAT Gateways found"
            fi

        else
            print_error "VPC $vpc_id not found or not accessible"
        fi
    else
        print_error "Could not retrieve VPC ID from Terraform state"
    fi
}

# Function to validate security baseline
validate_security() {
    local environment=$1
    print_check "Validating security baseline..."

    # Check CloudTrail
    local trail_name="${PROJECT_NAME}-shared-cloudtrail"
    if aws cloudtrail describe-trails \
        --trail-name-list "$trail_name" \
        --region "$AWS_REGION" > /dev/null 2>&1; then
        print_success "CloudTrail '$trail_name' is configured"

        # Check if trail is logging
        local is_logging
        is_logging=$(aws cloudtrail get-trail-status \
            --name "$trail_name" \
            --query 'IsLogging' \
            --output text \
            --region "$AWS_REGION")

        if [ "$is_logging" == "True" ]; then
            print_success "CloudTrail is actively logging"
        else
            print_error "CloudTrail is not logging"
        fi
    else
        print_error "CloudTrail '$trail_name' not found"
    fi

    # Check GuardDuty
    local detector_ids
    detector_ids=$(aws guardduty list-detectors \
        --query 'DetectorIds' \
        --output text \
        --region "$AWS_REGION")

    if [ -n "$detector_ids" ]; then
        print_success "GuardDuty detector found"

        # Check detector status
        for detector_id in $detector_ids; do
            local status
            status=$(aws guardduty get-detector \
                --detector-id "$detector_id" \
                --query 'Status' \
                --output text \
                --region "$AWS_REGION")

            if [ "$status" == "ENABLED" ]; then
                print_success "GuardDuty detector $detector_id is enabled"
            else
                print_warning "GuardDuty detector $detector_id status: $status"
            fi
        done
    else
        print_error "No GuardDuty detectors found"
    fi

    # Check Security Hub
    if aws securityhub get-enabled-standards --region "$AWS_REGION" > /dev/null 2>&1; then
        local standards_count
        standards_count=$(aws securityhub get-enabled-standards \
            --query 'StandardsSubscriptions | length(@)' \
            --output text \
            --region "$AWS_REGION")

        if [ "$standards_count" -gt 0 ]; then
            print_success "Security Hub has $standards_count standard(s) enabled"
        else
            print_warning "Security Hub is enabled but no standards are active"
        fi
    else
        print_error "Security Hub is not accessible or not enabled"
    fi

    # Check Config
    local config_recorders
    config_recorders=$(aws configservice describe-configuration-recorders \
        --query 'ConfigurationRecorders | length(@)' \
        --output text \
        --region "$AWS_REGION")

    if [ "$config_recorders" -gt 0 ]; then
        print_success "AWS Config has $config_recorders recorder(s) configured"
    else
        print_error "No AWS Config recorders found"
    fi
}

# Function to validate application infrastructure
validate_application() {
    local environment=$1
    print_check "Validating application infrastructure for $environment..."

    cd "terraform/environments/$environment"

    # Check Auto Scaling Group
    local asg_name
    asg_name=$(terraform output -raw autoscaling_group_name 2>/dev/null || echo "")

    if [ -n "$asg_name" ]; then
        local desired_capacity
        local current_instances

        desired_capacity=$(aws autoscaling describe-auto-scaling-groups \
            --auto-scaling-group-names "$asg_name" \
            --query 'AutoScalingGroups[0].DesiredCapacity' \
            --output text \
            --region "$AWS_REGION")

        current_instances=$(aws autoscaling describe-auto-scaling-groups \
            --auto-scaling-group-names "$asg_name" \
            --query 'AutoScalingGroups[0].Instances[?LifecycleState==`InService`] | length(@)' \
            --output text \
            --region "$AWS_REGION")

        if [ "$current_instances" -eq "$desired_capacity" ]; then
            print_success "Auto Scaling Group '$asg_name' has $current_instances/$desired_capacity healthy instances"
        else
            print_warning "Auto Scaling Group '$asg_name' has $current_instances/$desired_capacity healthy instances"
        fi
    else
        print_error "Could not retrieve Auto Scaling Group name"
    fi

    # Check Application Load Balancer
    local alb_arn
    alb_arn=$(terraform output -raw web_application_alb_arn 2>/dev/null || echo "")

    if [ -n "$alb_arn" ]; then
        local alb_state
        alb_state=$(aws elbv2 describe-load-balancers \
            --load-balancer-arns "$alb_arn" \
            --query 'LoadBalancers[0].State.Code' \
            --output text \
            --region "$AWS_REGION")

        if [ "$alb_state" == "active" ]; then
            print_success "Application Load Balancer is active"

            # Test ALB endpoint
            local alb_dns
            alb_dns=$(terraform output -raw web_application_url 2>/dev/null || echo "")

            if [ -n "$alb_dns" ]; then
                if curl -s --connect-timeout 10 --max-time 30 -I "http://$alb_dns/" > /dev/null 2>&1; then
                    print_success "ALB endpoint is responding"
                else
                    print_warning "ALB endpoint is not responding (may be normal if no application deployed)"
                fi
            fi
        else
            print_error "Application Load Balancer state: $alb_state"
        fi
    else
        print_error "Could not retrieve Application Load Balancer ARN"
    fi

    # Check S3 bucket for React hosting
    local s3_bucket
    s3_bucket=$(terraform output -raw react_s3_bucket_name 2>/dev/null || echo "")

    if [ -n "$s3_bucket" ]; then
        if aws s3api head-bucket --bucket "$s3_bucket" > /dev/null 2>&1; then
            print_success "React hosting S3 bucket '$s3_bucket' exists"

            # Check bucket encryption
            if aws s3api get-bucket-encryption --bucket "$s3_bucket" > /dev/null 2>&1; then
                print_success "S3 bucket encryption is enabled"
            else
                print_warning "S3 bucket encryption is not enabled"
            fi
        else
            print_error "React hosting S3 bucket '$s3_bucket' not accessible"
        fi
    else
        print_error "Could not retrieve React hosting S3 bucket name"
    fi

    # Check CloudFront distribution
    local cf_distribution_id
    cf_distribution_id=$(terraform output -raw react_cloudfront_distribution_id 2>/dev/null || echo "")

    if [ -n "$cf_distribution_id" ]; then
        local cf_status
        cf_status=$(aws cloudfront get-distribution \
            --id "$cf_distribution_id" \
            --query 'Distribution.Status' \
            --output text)

        if [ "$cf_status" == "Deployed" ]; then
            print_success "CloudFront distribution is deployed"

            # Test CloudFront endpoint
            local cf_url
            cf_url=$(terraform output -raw react_static_website_url 2>/dev/null || echo "")

            if [ -n "$cf_url" ]; then
                if curl -s --connect-timeout 10 --max-time 30 -I "$cf_url" > /dev/null 2>&1; then
                    print_success "CloudFront endpoint is responding"
                else
                    print_warning "CloudFront endpoint is not responding (may be normal if no content uploaded)"
                fi
            fi
        else
            print_warning "CloudFront distribution status: $cf_status"
        fi
    else
        print_error "Could not retrieve CloudFront distribution ID"
    fi

    cd ../../..
}

# Function to validate monitoring and alerting
validate_monitoring() {
    local environment=$1
    print_check "Validating monitoring and alerting for $environment..."

    cd "terraform/environments/$environment"

    # Check CloudWatch dashboards
    local dashboard_names
    dashboard_names=$(terraform output -json 2>/dev/null | jq -r '
        [.infrastructure_dashboard_name.value, .security_dashboard_name.value, .application_dashboard_name.value]
        | map(select(. != null and . != ""))
        | .[]' || echo "")

    if [ -n "$dashboard_names" ]; then
        local dashboard_count=0
        while IFS= read -r dashboard_name; do
            if [ -n "$dashboard_name" ]; then
                if aws cloudwatch get-dashboard \
                    --dashboard-name "$dashboard_name" \
                    --region "$AWS_REGION" > /dev/null 2>&1; then
                    print_success "CloudWatch dashboard '$dashboard_name' exists"
                    ((dashboard_count++))
                else
                    print_error "CloudWatch dashboard '$dashboard_name' not found"
                fi
            fi
        done <<< "$dashboard_names"

        if [ "$dashboard_count" -gt 0 ]; then
            print_success "Found $dashboard_count CloudWatch dashboard(s)"
        fi
    else
        print_error "Could not retrieve CloudWatch dashboard names"
    fi

    # Check CloudWatch alarms
    local alarm_count
    alarm_count=$(aws cloudwatch describe-alarms \
        --alarm-name-prefix "$PROJECT_NAME-$environment" \
        --query 'MetricAlarms | length(@)' \
        --output text \
        --region "$AWS_REGION")

    if [ "$alarm_count" -gt 0 ]; then
        print_success "Found $alarm_count CloudWatch alarm(s)"

        # Check alarm states
        local alarm_states
        alarm_states=$(aws cloudwatch describe-alarms \
            --alarm-name-prefix "$PROJECT_NAME-$environment" \
            --query 'MetricAlarms[].StateValue' \
            --output text \
            --region "$AWS_REGION")

        local ok_alarms=0
        local alarm_alarms=0
        local insufficient_alarms=0

        for state in $alarm_states; do
            case $state in
                "OK") ((ok_alarms++)) ;;
                "ALARM") ((alarm_alarms++)) ;;
                "INSUFFICIENT_DATA") ((insufficient_alarms++)) ;;
            esac
        done

        print_status "Alarm states: $ok_alarms OK, $alarm_alarms ALARM, $insufficient_alarms INSUFFICIENT_DATA"

        if [ "$alarm_alarms" -gt 0 ]; then
            print_warning "$alarm_alarms alarm(s) are in ALARM state"
        fi
    else
        print_error "No CloudWatch alarms found"
    fi

    cd ../../..
}

# Function to validate cost management
validate_cost_management() {
    local environment=$1
    print_check "Validating cost management for $environment..."

    cd "terraform/environments/$environment"

    # Check budgets
    local budget_name
    budget_name=$(terraform output -raw monthly_budget_name 2>/dev/null || echo "")

    if [ -n "$budget_name" ]; then
        local account_id
        account_id=$(aws sts get-caller-identity --query 'Account' --output text)

        if aws budgets describe-budget \
            --account-id "$account_id" \
            --budget-name "$budget_name" > /dev/null 2>&1; then
            print_success "Budget '$budget_name' exists"

            # Check budget status
            local budget_status
            budget_status=$(aws budgets describe-budget \
                --account-id "$account_id" \
                --budget-name "$budget_name" \
                --query 'Budget.CalculatedSpend.ActualSpend.Amount' \
                --output text)

            print_status "Current budget spend: \$$(printf "%.2f" "$budget_status")"
        else
            print_error "Budget '$budget_name' not found"
        fi
    else
        print_error "Could not retrieve budget name"
    fi

    # Check cost anomaly detectors
    local detector_count
    detector_count=$(aws ce get-anomaly-detectors \
        --query 'AnomalyDetectors | length(@)' \
        --output text)

    if [ "$detector_count" -gt 0 ]; then
        print_success "Found $detector_count cost anomaly detector(s)"
    else
        print_warning "No cost anomaly detectors found"
    fi

    cd ../../..
}

# Function to validate compliance monitoring
validate_compliance() {
    local environment=$1
    print_check "Validating compliance monitoring for $environment..."

    cd "terraform/environments/$environment"

    # Check Config rules
    local config_rules
    config_rules=$(aws configservice describe-config-rules \
        --query 'ConfigRules[?starts_with(ConfigRuleName, `'$PROJECT_NAME'-'$environment'`)] | length(@)' \
        --output text \
        --region "$AWS_REGION")

    if [ "$config_rules" -gt 0 ]; then
        print_success "Found $config_rules AWS Config rule(s)"

        # Check compliance status
        local compliant_rules
        local noncompliant_rules

        compliant_rules=$(aws configservice get-compliance-details-by-config-rule \
            --config-rule-names $(aws configservice describe-config-rules \
                --query 'ConfigRules[?starts_with(ConfigRuleName, `'$PROJECT_NAME'-'$environment'`)].ConfigRuleName' \
                --output text \
                --region "$AWS_REGION") \
            --query 'EvaluationResults[?ComplianceType==`COMPLIANT`] | length(@)' \
            --output text \
            --region "$AWS_REGION" 2>/dev/null || echo "0")

        noncompliant_rules=$(aws configservice get-compliance-details-by-config-rule \
            --config-rule-names $(aws configservice describe-config-rules \
                --query 'ConfigRules[?starts_with(ConfigRuleName, `'$PROJECT_NAME'-'$environment'`)].ConfigRuleName' \
                --output text \
                --region "$AWS_REGION") \
            --query 'EvaluationResults[?ComplianceType==`NON_COMPLIANT`] | length(@)' \
            --output text \
            --region "$AWS_REGION" 2>/dev/null || echo "0")

        print_status "Config rule compliance: $compliant_rules compliant, $noncompliant_rules non-compliant"

        if [ "$noncompliant_rules" -gt 0 ]; then
            print_warning "$noncompliant_rules Config rule(s) are non-compliant"
        fi
    else
        print_error "No AWS Config rules found for this environment"
    fi

    # Check Security Hub findings
    local findings_count
    findings_count=$(aws securityhub get-findings \
        --filters '{"ProductName": [{"Value": "Config", "Comparison": "EQUALS"}]}' \
        --query 'Findings | length(@)' \
        --output text \
        --region "$AWS_REGION" 2>/dev/null || echo "0")

    if [ "$findings_count" -gt 0 ]; then
        print_status "Found $findings_count Security Hub finding(s) from Config"

        # Check finding severities
        local critical_findings
        local high_findings

        critical_findings=$(aws securityhub get-findings \
            --filters '{"ProductName": [{"Value": "Config", "Comparison": "EQUALS"}], "SeverityLabel": [{"Value": "CRITICAL", "Comparison": "EQUALS"}]}' \
            --query 'Findings | length(@)' \
            --output text \
            --region "$AWS_REGION" 2>/dev/null || echo "0")

        high_findings=$(aws securityhub get-findings \
            --filters '{"ProductName": [{"Value": "Config", "Comparison": "EQUALS"}], "SeverityLabel": [{"Value": "HIGH", "Comparison": "EQUALS"}]}' \
            --query 'Findings | length(@)' \
            --output text \
            --region "$AWS_REGION" 2>/dev/null || echo "0")

        if [ "$critical_findings" -gt 0 ] || [ "$high_findings" -gt 0 ]; then
            print_warning "Found $critical_findings critical and $high_findings high severity findings"
        else
            print_success "No critical or high severity findings"
        fi
    else
        print_success "No Security Hub findings from Config"
    fi

    cd ../../..
}

# Function to generate summary report
generate_summary() {
    echo ""
    echo "========================================"
    echo -e "${BLUE}Validation Summary${NC}"
    echo "========================================"
    echo "Total Checks: $TOTAL_CHECKS"
    echo -e "${GREEN}Passed: $PASSED_CHECKS${NC}"
    echo -e "${YELLOW}Warnings: $WARNING_CHECKS${NC}"
    echo -e "${RED}Failed: $FAILED_CHECKS${NC}"
    echo ""

    local success_rate=$((PASSED_CHECKS * 100 / TOTAL_CHECKS))

    if [ "$success_rate" -ge 90 ]; then
        echo -e "${GREEN}Overall Status: EXCELLENT (${success_rate}% success rate)${NC}"
    elif [ "$success_rate" -ge 75 ]; then
        echo -e "${YELLOW}Overall Status: GOOD (${success_rate}% success rate)${NC}"
    elif [ "$success_rate" -ge 50 ]; then
        echo -e "${YELLOW}Overall Status: NEEDS ATTENTION (${success_rate}% success rate)${NC}"
    else
        echo -e "${RED}Overall Status: CRITICAL (${success_rate}% success rate)${NC}"
    fi

    if [ "$FAILED_CHECKS" -gt 0 ]; then
        echo ""
        echo -e "${RED}Action Required: Please address the failed checks above.${NC}"
        return 1
    elif [ "$WARNING_CHECKS" -gt 0 ]; then
        echo ""
        echo -e "${YELLOW}Review Recommended: Please review the warnings above.${NC}"
        return 0
    else
        echo ""
        echo -e "${GREEN}Infrastructure is healthy and fully operational!${NC}"
        return 0
    fi
}

# Main execution
main() {
    local environment=${1:-staging}

    echo -e "${GREEN}EPiC Infrastructure - Validation Report${NC}"
    echo "======================================="
    echo "Environment: $environment"
    echo "Region: $AWS_REGION"
    echo "Date: $(date)"
    echo ""

    # Validate parameters
    validate_environment "$environment"

    # Check if we're in the right directory
    if [ ! -d "terraform" ]; then
        print_error "Please run this script from the repository root directory."
        exit 1
    fi

    # Run all validation checks
    check_terraform_state "$environment"
    echo ""

    validate_networking "$environment"
    echo ""

    validate_security "$environment"
    echo ""

    validate_application "$environment"
    echo ""

    validate_monitoring "$environment"
    echo ""

    validate_cost_management "$environment"
    echo ""

    validate_compliance "$environment"
    echo ""

    # Generate summary
    generate_summary
}

# Show help if requested
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Usage: $0 [ENVIRONMENT]"
    echo ""
    echo "ENVIRONMENT: staging or production (default: staging)"
    echo ""
    echo "This script validates the deployed EPiC infrastructure and performs"
    echo "comprehensive health checks across all components."
    echo ""
    echo "Examples:"
    echo "  $0 staging     # Validate staging environment"
    echo "  $0 production  # Validate production environment"
    exit 0
fi

# Run main function
main "$@"