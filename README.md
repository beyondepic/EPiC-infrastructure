# EPiC Infrastructure Management System

**Version:** 1.0
**Repository:** AWS Infrastructure as Code for EPiC Projects
**Technology Stack:** Terraform, GitHub Actions, AWS

---

## 🎯 Overview

The EPiC Infrastructure Management System is a centralized Terraform-based infrastructure-as-code solution designed to manage AWS resources across multiple projects and environments. This system provides automated, version-controlled, and reusable infrastructure components.

### Key Features
- ✅ **Multi-project support** - Shared infrastructure across EPiC projects
- ✅ **Environment isolation** - Staging, production, and shared resources
- ✅ **Reusable modules** - Standardized AWS resource patterns
- ✅ **Automated deployment** - GitHub Actions CI/CD integration
- ✅ **Cost optimization** - Shared resources and right-sizing
- ✅ **Security by default** - Built-in security best practices

---

## 🏗️ Repository Structure

```
EPiC-infrastructure/
├── terraform/
│   ├── modules/                    # Reusable Terraform modules
│   │   ├── shared-networking/      # ✅ VPC + Subnets + Security Groups
│   │   ├── security-baseline/      # ✅ IAM + CloudTrail + Config + GuardDuty
│   │   ├── web-application/        # ✅ EC2 + ALB + ASG + CloudWatch
│   │   ├── react-hosting/          # ✅ S3/CloudFront + AWS-IA integration
│   │   ├── sns-notifications/      # ✅ SNS email and messaging
│   │   ├── database-backup/        # 🔲 RDS + S3 backup system (planned)
│   │   ├── monitoring-alerting/    # 🔲 CloudWatch + Dashboards (planned)
│   │   └── cost-optimization/      # 🔲 Cost monitoring (planned)
│   ├── environments/
│   │   ├── shared/                 # Cross-environment resources
│   │   ├── staging/                # Staging environment
│   │   └── production/             # Production environment
│   └── projects/
│       ├── nestedphoenix/          # NestedPhoenix-specific resources
│       ├── project-alpha/          # Future project configurations
│       └── project-beta/           # Future project configurations
├── scripts/
│   ├── setup/                      # Initial setup and bootstrapping
│   ├── deployment/                 # Deployment automation
│   └── utilities/                  # Utility scripts
├── docs/
│   ├── architecture/               # System design and specifications
│   ├── runbooks/                   # Operational procedures
│   └── compliance/                 # Compliance and audit docs
├── config/                         # Global configuration files
└── .github/
    ├── workflows/                  # GitHub Actions workflows
    └── templates/                  # PR and issue templates
```

---

## 🚀 Quick Start

### Prerequisites
- AWS CLI configured with appropriate permissions
- Terraform 1.6+ installed
- GitHub CLI (gh) for repository operations

### 1. Clone Repository
```bash
git clone https://github.com/beyondepic/EPiC-infrastructure.git
cd EPiC-infrastructure
```

### 2. Initialize Terraform Backend
```bash
# Run backend setup script
./scripts/setup/bootstrap-terraform.sh
```

### 3. Deploy Shared Infrastructure
```bash
# Deploy shared networking and security
cd terraform/environments/shared
terraform init
terraform plan
terraform apply
```

### 4. Deploy Project Infrastructure
```bash
# Deploy NestedPhoenix infrastructure
cd terraform/projects/nestedphoenix
terraform init
terraform plan
terraform apply
```

---

## 📋 Available Modules

### Core Infrastructure Modules ✅ IMPLEMENTED

#### 1. **Shared Networking** (`shared-networking`)
- **VPC with multi-tier architecture** - Public, private, and database subnets
- **High availability** - Resources across multiple AZs
- **NAT Gateways** - Secure outbound connectivity for private subnets
- **Security Groups** - Web, application, and database tier protection
- **VPC Flow Logs** - Network monitoring and troubleshooting
- **VPC Endpoints** - Private connectivity to AWS services (S3, DynamoDB, etc.)
- **DB Subnet Groups** - Ready for RDS deployments
- **Input Validation** - Comprehensive validation for all configuration parameters

#### 2. **Security Baseline** (`security-baseline`)
- **CloudTrail** - Comprehensive audit logging with S3 storage
- **AWS Config** - Compliance monitoring and configuration tracking
- **GuardDuty** - Advanced threat detection with ML
- **Security Hub** - Centralized security findings management
- **IAM Roles** - Least privilege roles for EC2 and Lambda
- **KMS Encryption** - Customer-managed keys for sensitive data

#### 3. **Web Application** (`web-application`)
- **Auto Scaling Groups** - Automated scaling based on CPU metrics
- **Application Load Balancer** - High availability with health checks
- **AWS WAF Integration** - Advanced web application firewall protection
- **Managed Rule Sets** - Core, Known Bad Inputs, SQL injection protection
- **Rate Limiting** - Protection against DDoS and abuse
- **Geographic Blocking** - Optional country-based access control
- **CloudWatch Integration** - Detailed monitoring and alarms
- **Instance Profiles** - Secure IAM integration
- **SSL/TLS Support** - HTTPS listener configuration
- **Input Validation** - Comprehensive validation for all configuration parameters

#### 4. **React Hosting** (`react-hosting`)
- **Dual Hosting Options**:
  - **Static**: S3 + CloudFront for static React sites
  - **Serverless**: ECS + ALB + CloudFront for dynamic apps
- **AWS-IA Integration** - Uses aws-ia/serverless-streamlit-app module
- **CDN Distribution** - Global content delivery with CloudFront
- **SSL Certificate Support** - ACM certificate integration
- **CI/CD Ready** - CodeBuild and CodePipeline integration

#### 5. **SNS Notifications** (`sns-notifications`)
- **Multi-channel alerts** - Email and Slack integration
- **Environment-specific topics** - Separate notification channels
- **Lambda integration** - Custom notification processing
- **Dead letter queues** - Reliable message delivery

### Usage Example
```hcl
module "web_application" {
  source = "../../modules/web-application"

  project_name     = "nestedphoenix"
  environment     = "production"
  instance_type   = "t3.medium"
  min_size        = 2
  max_size        = 10
  vpc_id          = module.shared_networking.vpc_id
  subnets         = module.shared_networking.private_subnets
}
```

---

## 🌍 Environment Management

### Environment Strategy
- **Shared**: Resources used across all environments (VPC, DNS, etc.)
- **Staging**: Development and testing environment
- **Production**: Live production environment

### Environment Configuration
Each environment has its own:
- Terraform state files
- Variable configurations
- Security policies
- Cost budgets

### Deployment Workflow
1. **Development** → Commit infrastructure changes
2. **PR Review** → Terraform plan shown in PR comments
3. **Staging Deploy** → Automatic deployment to staging
4. **Production Deploy** → Manual approval required

---

## 🔐 Security & Compliance

### Security Features
- **Least privilege IAM** - Minimal required permissions
- **Encryption at rest** - All storage encrypted
- **Encryption in transit** - TLS 1.2+ for all communications
- **Network isolation** - VPC and subnet segmentation
- **Audit logging** - CloudTrail for all API calls

### Compliance Standards
- SOC 2 Type II controls
- AWS Well-Architected Framework
- Infrastructure as Code best practices
- Automated compliance monitoring

---

## 💰 Cost Management

### Cost Optimization Features
- **Shared resources** - VPC, NAT Gateways, monitoring
- **Right-sizing** - Automated recommendations
- **Reserved instances** - For predictable workloads
- **Lifecycle policies** - Automatic storage optimization

### Cost Allocation
- **Project-based tagging** - Cost per project
- **Environment separation** - Staging vs production costs
- **Budget alerts** - Prevent cost overruns
- **Monthly reporting** - Detailed cost analysis

---

## 🛠️ Development Workflow

### Making Infrastructure Changes

1. **Create Feature Branch**
   ```bash
   git checkout -b feature/add-sns-module
   ```

2. **Develop Module**
   ```bash
   # Create or modify Terraform modules
   cd terraform/modules/sns-notifications
   # Edit main.tf, variables.tf, outputs.tf
   ```

3. **Test Locally**
   ```bash
   # Validate Terraform syntax
   terraform validate

   # Plan changes
   terraform plan
   ```

4. **Submit PR**
   ```bash
   git add .
   git commit -m "feat: add SNS notifications module"
   git push origin feature/add-sns-module
   gh pr create
   ```

5. **Review & Deploy**
   - GitHub Actions runs `terraform plan`
   - Team reviews PR and Terraform plan
   - Merge triggers deployment to staging
   - Manual approval for production deployment

---

## 📊 Monitoring & Alerting

### Infrastructure Monitoring
- **CloudWatch dashboards** - Real-time metrics
- **Cost anomaly detection** - Unusual spending alerts
- **Security alerts** - GuardDuty findings
- **Compliance monitoring** - AWS Config rules

### Notification Channels
- **Email alerts** - Via SNS topics
- **Slack integration** - For team notifications
- **GitHub notifications** - Deployment status

---

## 🤝 Contributing

### Guidelines
1. **Follow naming conventions** - Use kebab-case for resources
2. **Add documentation** - Update README for new modules
3. **Include examples** - Provide usage examples
4. **Test thoroughly** - Validate in staging first
5. **Security review** - All changes reviewed for security

### Module Development
1. **Standard structure** - Use consistent file organization
2. **Input validation** - Validate all input variables
3. **Output values** - Expose useful outputs
4. **Tagging strategy** - Apply consistent resource tags

---

## 📞 Support

### Getting Help
- **Documentation** - Check `/docs` directory
- **Issues** - Create GitHub issue for bugs
- **Discussions** - Use GitHub discussions for questions
- **Team chat** - Internal Slack channels

### Emergency Contact
- **Infrastructure team** - For critical infrastructure issues
- **Security team** - For security incidents
- **On-call rotation** - 24/7 support for production

---

## 📈 Roadmap

### Current Phase: Foundation (Q1 2025) - COMPLETED ✅
- ✅ Repository setup and structure
- ✅ Core Terraform modules (shared-networking, security-baseline, web-application, react-hosting)
- ✅ Multi-environment support (shared, staging, production)
- ✅ AWS-IA module integration (serverless-streamlit-app)
- ✅ Comprehensive deployment guide
- ✅ Security-first architecture with best practices
- ✅ **Recent Enhancements (September 2025)**:
  - ✅ AWS WAF integration for web application protection
  - ✅ VPC Endpoints for secure AWS service connectivity
  - ✅ Comprehensive input validation across all modules
  - ✅ Fixed critical Lambda region interpolation bugs
  - ✅ Enhanced repository documentation and structure

### Next Phase: Expansion (Q2 2025)
- 🔲 Advanced monitoring and alerting
- 🔲 Multi-cloud strategy evaluation
- 🔲 Additional project onboarding
- 🔲 Cost optimization automation

### Future Phase: Advanced Features (Q3-Q4 2025)
- 🔲 Kubernetes integration (EKS)
- 🔲 Data platform infrastructure
- 🔲 AI/ML infrastructure modules
- 🔲 Edge computing support

---

## 📄 License

This infrastructure code is proprietary to EPiC. See [LICENSE](LICENSE) for details.

---

**Last Updated:** September 2025
**Maintained By:** EPiC Infrastructure Team
**Repository:** https://github.com/beyondepic/EPiC-infrastructure