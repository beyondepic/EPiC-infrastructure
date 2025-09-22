#!/bin/bash

# EPiC Infrastructure Test Runner
# This script runs all integration tests for the Terraform modules

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
TEST_TIMEOUT=${TEST_TIMEOUT:-30m}
TEST_PARALLEL=${TEST_PARALLEL:-4}
AWS_REGION=${AWS_REGION:-ap-southeast-4}

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}  EPiC Infrastructure Tests     ${NC}"
echo -e "${BLUE}================================${NC}"
echo ""

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

# Check if Go is installed
if ! command -v go &> /dev/null; then
    echo -e "${RED}Error: Go is not installed${NC}"
    exit 1
fi

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}Error: Terraform is not installed${NC}"
    exit 1
fi

# Check if AWS CLI is configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}Error: AWS CLI is not configured or credentials are invalid${NC}"
    exit 1
fi

echo -e "${GREEN}Prerequisites check passed${NC}"
echo ""

# Function to run tests
run_tests() {
    local test_pattern="$1"
    local test_name="$2"

    echo -e "${BLUE}Running $test_name...${NC}"

    if go test -v -timeout "$TEST_TIMEOUT" -parallel "$TEST_PARALLEL" -run "$test_pattern"; then
        echo -e "${GREEN}✅ $test_name passed${NC}"
        return 0
    else
        echo -e "${RED}❌ $test_name failed${NC}"
        return 1
    fi
}

# Function to clean up resources
cleanup_resources() {
    echo -e "${YELLOW}Cleaning up any remaining test resources...${NC}"

    # List and delete test VPCs
    aws ec2 describe-vpcs --filters "Name=tag:Name,Values=test-*" --query 'Vpcs[].VpcId' --output text | while read vpc_id; do
        if [ ! -z "$vpc_id" ]; then
            echo "Deleting test VPC: $vpc_id"
            aws ec2 delete-vpc --vpc-id "$vpc_id" 2>/dev/null || true
        fi
    done

    # List and delete test security groups
    aws ec2 describe-security-groups --filters "Name=group-name,Values=test-*" --query 'SecurityGroups[].GroupId' --output text | while read sg_id; do
        if [ ! -z "$sg_id" ]; then
            echo "Deleting test security group: $sg_id"
            aws ec2 delete-security-group --group-id "$sg_id" 2>/dev/null || true
        fi
    done

    echo -e "${GREEN}Cleanup completed${NC}"
}

# Trap to ensure cleanup runs on exit
trap cleanup_resources EXIT

# Change to tests directory
cd "$(dirname "$0")"

# Download Go modules
echo -e "${YELLOW}Downloading Go modules...${NC}"
go mod download

# Initialize test results
FAILED_TESTS=()

# Run different test suites
echo -e "${BLUE}Starting integration tests...${NC}"
echo ""

# Test 1: Shared Networking Module
if ! run_tests "TestSharedNetworkingModule" "Shared Networking Module Tests"; then
    FAILED_TESTS+=("Shared Networking Module")
fi

echo ""

# Test 2: Web Application Module
if ! run_tests "TestWebApplicationModule" "Web Application Module Tests"; then
    FAILED_TESTS+=("Web Application Module")
fi

echo ""

# Test 3: Validation Tests
if ! run_tests ".*Validation.*" "Input Validation Tests"; then
    FAILED_TESTS+=("Input Validation")
fi

echo ""

# Test 4: Security Tests
if ! run_tests ".*Security.*" "Security Feature Tests"; then
    FAILED_TESTS+=("Security Features")
fi

echo ""

# Summary
echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}        Test Results            ${NC}"
echo -e "${BLUE}================================${NC}"

if [ ${#FAILED_TESTS[@]} -eq 0 ]; then
    echo -e "${GREEN}🎉 All tests passed!${NC}"
    echo ""
    echo -e "${GREEN}Your EPiC Infrastructure is ready for production!${NC}"
    exit 0
else
    echo -e "${RED}❌ Some tests failed:${NC}"
    for test in "${FAILED_TESTS[@]}"; do
        echo -e "${RED}  - $test${NC}"
    done
    echo ""
    echo -e "${YELLOW}Please review the test output above and fix any issues.${NC}"
    exit 1
fi