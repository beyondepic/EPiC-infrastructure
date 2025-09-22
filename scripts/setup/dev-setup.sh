#!/bin/bash

# EPiC Infrastructure Development Environment Setup
# This script sets up all necessary tools and configurations for development

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Tool versions (latest as of 2025)
TERRAFORM_VERSION="1.13.3"
TFLINT_VERSION="0.59.1"
TERRAGRUNT_VERSION="0.67.16"
GO_VERSION="1.21.0"

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}  EPiC Infrastructure Setup     ${NC}"
echo -e "${BLUE}================================${NC}"
echo ""

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install Terraform
install_terraform() {
    echo -e "${YELLOW}Installing Terraform v${TERRAFORM_VERSION}...${NC}"

    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command_exists brew; then
            brew install tfenv
            tfenv install $TERRAFORM_VERSION
            tfenv use $TERRAFORM_VERSION
        else
            echo -e "${RED}Homebrew not found. Please install Homebrew first.${NC}"
            exit 1
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip
        unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip
        sudo mv terraform /usr/local/bin/
        rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip
    else
        echo -e "${RED}Unsupported OS: $OSTYPE${NC}"
        exit 1
    fi

    echo -e "${GREEN}Terraform installed successfully${NC}"
}

# Function to install TFLint
install_tflint() {
    echo -e "${YELLOW}Installing TFLint v${TFLINT_VERSION}...${NC}"

    if [[ "$OSTYPE" == "darwin"* ]]; then
        if command_exists brew; then
            brew install tflint
        else
            curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash
        fi
    else
        curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash
    fi

    echo -e "${GREEN}TFLint installed successfully${NC}"
}

# Function to install Terragrunt
install_terragrunt() {
    echo -e "${YELLOW}Installing Terragrunt v${TERRAGRUNT_VERSION}...${NC}"

    if [[ "$OSTYPE" == "darwin"* ]]; then
        if command_exists brew; then
            brew install terragrunt
        else
            TERRAGRUNT_URL="https://github.com/gruntwork-io/terragrunt/releases/download/v${TERRAGRUNT_VERSION}/terragrunt_darwin_amd64"
            curl -Lo terragrunt $TERRAGRUNT_URL
            chmod +x terragrunt
            sudo mv terragrunt /usr/local/bin/
        fi
    else
        TERRAGRUNT_URL="https://github.com/gruntwork-io/terragrunt/releases/download/v${TERRAGRUNT_VERSION}/terragrunt_linux_amd64"
        curl -Lo terragrunt $TERRAGRUNT_URL
        chmod +x terragrunt
        sudo mv terragrunt /usr/local/bin/
    fi

    echo -e "${GREEN}Terragrunt installed successfully${NC}"
}

# Function to install Go
install_go() {
    echo -e "${YELLOW}Installing Go v${GO_VERSION}...${NC}"

    if [[ "$OSTYPE" == "darwin"* ]]; then
        if command_exists brew; then
            brew install go
        else
            echo -e "${RED}Homebrew not found. Please install Go manually.${NC}"
        fi
    else
        GO_URL="https://golang.org/dl/go${GO_VERSION}.linux-amd64.tar.gz"
        wget $GO_URL
        sudo tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz
        rm go${GO_VERSION}.linux-amd64.tar.gz

        # Add Go to PATH
        echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
        export PATH=$PATH:/usr/local/go/bin
    fi

    echo -e "${GREEN}Go installed successfully${NC}"
}

# Function to install AWS CLI
install_aws_cli() {
    echo -e "${YELLOW}Installing AWS CLI v2...${NC}"

    if [[ "$OSTYPE" == "darwin"* ]]; then
        if command_exists brew; then
            brew install awscli
        else
            curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
            sudo installer -pkg AWSCLIV2.pkg -target /
            rm AWSCLIV2.pkg
        fi
    else
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
        unzip awscliv2.zip
        sudo ./aws/install
        rm -rf aws awscliv2.zip
    fi

    echo -e "${GREEN}AWS CLI installed successfully${NC}"
}

# Function to install pre-commit
install_pre_commit() {
    echo -e "${YELLOW}Installing pre-commit...${NC}"

    if command_exists pip3; then
        pip3 install pre-commit
    elif command_exists pip; then
        pip install pre-commit
    elif [[ "$OSTYPE" == "darwin"* ]] && command_exists brew; then
        brew install pre-commit
    else
        echo -e "${RED}Cannot install pre-commit. Please install Python and pip first.${NC}"
        return 1
    fi

    echo -e "${GREEN}pre-commit installed successfully${NC}"
}

# Function to setup pre-commit hooks
setup_pre_commit() {
    echo -e "${YELLOW}Setting up pre-commit hooks...${NC}"

    # Install pre-commit hooks
    pre-commit install
    pre-commit install --hook-type commit-msg
    pre-commit install --hook-type pre-push

    echo -e "${GREEN}Pre-commit hooks installed successfully${NC}"
}

# Function to initialize TFLint
setup_tflint() {
    echo -e "${YELLOW}Initializing TFLint...${NC}"

    # Initialize TFLint plugins
    tflint --init

    echo -e "${GREEN}TFLint initialized successfully${NC}"
}

# Function to check AWS credentials
check_aws_credentials() {
    echo -e "${YELLOW}Checking AWS credentials...${NC}"

    if aws sts get-caller-identity >/dev/null 2>&1; then
        echo -e "${GREEN}AWS credentials are configured${NC}"
        aws sts get-caller-identity
    else
        echo -e "${YELLOW}AWS credentials not configured. Run 'aws configure' to set them up.${NC}"
    fi
}

# Main installation process
main() {
    echo -e "${BLUE}Starting development environment setup...${NC}"
    echo ""

    # Check and install Terraform
    if command_exists terraform; then
        CURRENT_VERSION=$(terraform version -json | jq -r '.terraform_version')
        echo -e "${GREEN}Terraform is already installed (v${CURRENT_VERSION})${NC}"
    else
        install_terraform
    fi

    # Check and install TFLint
    if command_exists tflint; then
        CURRENT_VERSION=$(tflint --version | head -n1 | awk '{print $3}')
        echo -e "${GREEN}TFLint is already installed (${CURRENT_VERSION})${NC}"
    else
        install_tflint
    fi

    # Check and install Terragrunt
    if command_exists terragrunt; then
        CURRENT_VERSION=$(terragrunt --version | head -n1 | awk '{print $3}')
        echo -e "${GREEN}Terragrunt is already installed (${CURRENT_VERSION})${NC}"
    else
        install_terragrunt
    fi

    # Check and install Go
    if command_exists go; then
        CURRENT_VERSION=$(go version | awk '{print $3}')
        echo -e "${GREEN}Go is already installed (${CURRENT_VERSION})${NC}"
    else
        install_go
    fi

    # Check and install AWS CLI
    if command_exists aws; then
        CURRENT_VERSION=$(aws --version | cut -d/ -f2 | cut -d' ' -f1)
        echo -e "${GREEN}AWS CLI is already installed (v${CURRENT_VERSION})${NC}"
    else
        install_aws_cli
    fi

    # Check and install pre-commit
    if command_exists pre-commit; then
        CURRENT_VERSION=$(pre-commit --version | awk '{print $2}')
        echo -e "${GREEN}pre-commit is already installed (v${CURRENT_VERSION})${NC}"
    else
        install_pre_commit
    fi

    echo ""
    echo -e "${BLUE}Setting up tools...${NC}"

    # Setup pre-commit hooks
    setup_pre_commit

    # Initialize TFLint
    setup_tflint

    # Check AWS credentials
    check_aws_credentials

    echo ""
    echo -e "${GREEN}================================${NC}"
    echo -e "${GREEN}  Setup Complete!               ${NC}"
    echo -e "${GREEN}================================${NC}"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "1. Configure AWS credentials: aws configure"
    echo "2. Run pre-commit on all files: pre-commit run --all-files"
    echo "3. Initialize Terraform: cd terraform/environments/staging && terraform init"
    echo "4. Run tests: cd tests && ./run_tests.sh"
    echo ""
    echo -e "${GREEN}Your EPiC Infrastructure development environment is ready!${NC}"
}

# Run main function
main "$@"