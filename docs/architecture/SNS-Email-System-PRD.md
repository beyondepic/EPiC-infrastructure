# SNS Email Notification System - Technical PRD

**Version:** 1.0
**Date:** September 2025
**Status:** Immediate Implementation
**Priority:** P0 (Critical - Staging Server Down)

---

## 🚨 Problem Statement

### Immediate Crisis
**Staging server is failing** with the following error:
```
ValueError: invalid literal for int() with base 10: ''
EMAIL_PORT = env("EMAIL_PORT")
```

### Root Cause Analysis
1. **Missing EMAIL_PORT configuration** in staging environment
2. **SMTP email dependency** blocking application startup
3. **Configuration fragility** - empty values cause crashes
4. **No email fallback mechanism** for service availability

### Business Impact
- ❌ **Staging environment down** - blocking development and testing
- ❌ **Cannot deploy new features** until email configuration is fixed
- ❌ **Development team blocked** on feature testing
- ❌ **No reliable notification system** for alerts and monitoring

---

## 🎯 Solution Overview

Replace SMTP email configuration with **AWS SNS-based email notifications** to:
- ✅ **Immediately fix staging server** startup issues
- ✅ **Eliminate SMTP configuration dependencies**
- ✅ **Provide reliable email delivery** through AWS infrastructure
- ✅ **Create foundation** for EPiC-infrastructure project

### Vision Statement
*"A robust, cloud-native email notification system that eliminates configuration dependencies and provides reliable message delivery through AWS SNS."*

---

## 🏗️ Technical Architecture

### System Components

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Django App    │───▶│   SNS Service   │───▶│   AWS SNS       │
│                 │    │                 │    │                 │
│ - Notifications │    │ - Format msgs   │    │ - Topic mgmt    │
│ - Error alerts  │    │ - Queue handling│    │ - Email delivery│
│ - User emails   │    │ - Retry logic   │    │ - Subscriptions │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │              ┌─────────────────┐              │
         └──────────────▶│ Fallback SMTP   │◀─────────────┘
                         │ (Optional)      │
                         └─────────────────┘
```

### Implementation Strategy

#### Phase 1: Emergency Fix (Today)
- **Make EMAIL_PORT optional** in Django settings
- **Add SNS email backend** as primary notification method
- **Deploy staging fix** to restore service

#### Phase 2: SNS Integration (1-2 days)
- **AWS SNS topic setup** for different notification types
- **Django SNS service** for application notifications
- **Email subscription management** for team notifications

#### Phase 3: Infrastructure Module (3-5 days)
- **Terraform SNS module** for repeatable deployments
- **Environment-specific topics** (staging, production)
- **Integration with EPiC-infrastructure** project

---

## 🔧 Technical Specifications

### Django SNS Integration

#### 1. SNS Email Backend
```python
# backends/sns_email.py
class SNSEmailBackend:
    """Django email backend using AWS SNS for message delivery"""

    def __init__(self):
        self.sns_client = boto3.client('sns', region_name='ap-southeast-4')
        self.topic_arn = settings.SNS_EMAIL_TOPIC_ARN

    def send_messages(self, email_messages):
        """Send email messages through SNS"""
        for message in email_messages:
            self._send_sns_message(message)

    def _send_sns_message(self, message):
        """Convert Django email to SNS message"""
        # Implementation details
```

#### 2. Notification Service
```python
# services/notifications.py
class NotificationService:
    """Centralized notification service for application alerts"""

    @staticmethod
    def send_error_alert(error_details, environment):
        """Send error alerts to development team"""

    @staticmethod
    def send_deployment_notification(deployment_info):
        """Send deployment success/failure notifications"""

    @staticmethod
    def send_user_notification(user_email, subject, message):
        """Send user-facing notifications"""
```

#### 3. Settings Configuration
```python
# settings.py
# SNS Configuration
SNS_ENABLED = env.bool('SNS_ENABLED', default=True)
SNS_EMAIL_TOPIC_ARN = env('SNS_EMAIL_TOPIC_ARN', default='')
SNS_REGION = env('SNS_REGION', default='ap-southeast-4')

# Email Backend Configuration
if SNS_ENABLED and SNS_EMAIL_TOPIC_ARN:
    EMAIL_BACKEND = 'backends.sns_email.SNSEmailBackend'
else:
    # Fallback to SMTP or console backend
    EMAIL_BACKEND = 'django.core.mail.backends.console.EmailBackend'

# Make SMTP settings optional
EMAIL_HOST = env('EMAIL_HOST', default='')
EMAIL_PORT = env.int('EMAIL_PORT', default=587)  # Fixed: provide default
EMAIL_USE_TLS = env.bool('EMAIL_USE_TLS', default=True)
EMAIL_HOST_USER = env('EMAIL_HOST_USER', default='')
EMAIL_HOST_PASSWORD = env('EMAIL_HOST_PASSWORD', default='')
```

### AWS SNS Infrastructure

#### 1. SNS Topic Structure
```
SNS Topics by Environment:
├── nestedphoenix-staging-alerts     # Development team alerts
├── nestedphoenix-staging-users      # User notifications
├── nestedphoenix-production-alerts  # Production alerts
└── nestedphoenix-production-users   # Production user emails
```

#### 2. Message Types
- **Error Alerts**: Application errors, failed deployments
- **System Notifications**: Backup status, maintenance windows
- **User Communications**: Account updates, password resets
- **Monitoring Alerts**: Performance issues, security events

#### 3. Subscription Management
- **Development Team**: Subscribe to alerts and system notifications
- **Admin Users**: Subscribe to critical alerts and user issues
- **End Users**: Subscribe to account-related communications

---

## 🚀 Implementation Plan

### Emergency Phase (Today - 2 hours)

#### Step 1: Fix Staging Configuration (30 minutes)
```bash
# Update staging.yaml workflow
printf 'EMAIL_PORT=%s\n' "587" >> .env  # Add default port
printf 'SNS_ENABLED=%s\n' "false" >> .env  # Disable SNS initially
```

#### Step 2: Make Email Settings Optional (30 minutes)
```python
# Update base_settings.py
EMAIL_PORT = env.int('EMAIL_PORT', default=587)  # Add default value
EMAIL_BACKEND = env('EMAIL_BACKEND', default='django.core.mail.backends.console.EmailBackend')
```

#### Step 3: Deploy Emergency Fix (60 minutes)
- Test configuration changes locally
- Deploy to staging environment
- Verify application startup success
- Confirm basic functionality

### Phase 1: SNS Backend (Tomorrow - 4 hours)

#### Hour 1: AWS SNS Setup
- Create SNS topics for staging environment
- Set up email subscriptions for development team
- Configure IAM permissions for SNS access

#### Hour 2: Django Integration
- Implement SNS email backend
- Create notification service class
- Add SNS configuration to settings

#### Hour 3: Testing and Validation
- Test SNS email delivery
- Verify fallback mechanisms
- Integration testing with existing code

#### Hour 4: Deployment
- Deploy SNS integration to staging
- Monitor email delivery and error handling
- Documentation and team communication

### Phase 2: Production Deployment (Day 3 - 4 hours)

#### Production SNS Setup
- Create production SNS topics and subscriptions
- Update production GitHub Actions workflow
- Deploy SNS integration to production environment

#### Monitoring and Optimization
- Set up CloudWatch metrics for SNS delivery
- Implement retry logic and error handling
- Performance monitoring and cost optimization

### Phase 3: Infrastructure as Code (Days 4-5)

#### Terraform Module Development
- Create reusable SNS module for EPiC-infrastructure
- Environment-specific configuration management
- Integration with existing CI/CD pipelines

---

## 📊 Success Metrics

### Immediate Success (Today)
- ✅ **Staging server startup** - Application starts without email errors
- ✅ **Zero configuration dependencies** - No required email environment variables
- ✅ **Development unblocked** - Team can resume feature development

### Short-term Success (This Week)
- ✅ **Email delivery rate** - >99% successful SNS message delivery
- ✅ **Response time** - <30 seconds from trigger to email delivery
- ✅ **Error reduction** - Zero email-related application startup errors
- ✅ **Team productivity** - No email configuration blocking deployments

### Long-term Success (This Month)
- ✅ **Cost optimization** - <$10/month for SNS email delivery
- ✅ **Reliability improvement** - 99.9% email service availability
- ✅ **Infrastructure foundation** - Reusable SNS module for future projects

---

## 💰 Cost Analysis

### SNS Pricing (ap-southeast-4)
- **Email delivery**: $2.00 per 100,000 messages
- **Topic management**: Free
- **Subscriptions**: Free

### Estimated Monthly Costs
| Usage Scenario | Messages/Month | Monthly Cost |
|----------------|----------------|--------------|
| **Development** | 1,000 | $0.02 |
| **Staging** | 5,000 | $0.10 |
| **Production** | 20,000 | $0.40 |
| **Total** | **26,000** | **$0.52** |

### Cost Comparison
- **Current SMTP** (Gmail): $6/month per user
- **SNS Alternative**: $0.52/month total
- **Savings**: >90% cost reduction

---

## 🔐 Security Considerations

### IAM Permissions
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "sns:Publish",
        "sns:GetTopicAttributes"
      ],
      "Resource": [
        "arn:aws:sns:ap-southeast-4:*:nestedphoenix-*"
      ]
    }
  ]
}
```

### Message Security
- **Encryption in transit**: TLS 1.2 for all SNS communications
- **No sensitive data**: Avoid including passwords or keys in messages
- **Message filtering**: Use SNS message filtering for targeted delivery
- **Audit logging**: CloudTrail logging for all SNS API calls

### Access Control
- **Environment isolation**: Separate topics per environment
- **Role-based access**: Different IAM roles for staging vs production
- **Subscription management**: Automated subscription handling
- **Message validation**: Input sanitization and validation

---

## 🔍 Risk Assessment

### Technical Risks

#### 1. **SNS Service Availability** - Medium Impact, Low Probability
**Mitigation**:
- Implement SMTP fallback mechanism
- Multiple region deployment capability
- Circuit breaker pattern for service calls

#### 2. **Message Delivery Failures** - Low Impact, Medium Probability
**Mitigation**:
- SNS built-in retry mechanisms
- Dead letter queue for failed messages
- Monitoring and alerting for delivery failures

#### 3. **AWS Cost Spikes** - Medium Impact, Low Probability
**Mitigation**:
- CloudWatch billing alarms
- Message rate limiting
- Usage monitoring and optimization

### Operational Risks

#### 1. **Configuration Errors** - High Impact, Medium Probability
**Mitigation**:
- Environment-specific configuration validation
- Automated testing of email delivery
- Gradual rollout with monitoring

#### 2. **Team Knowledge Gap** - Medium Impact, High Probability
**Mitigation**:
- Comprehensive documentation
- Team training and knowledge sharing
- Clear troubleshooting procedures

---

## 📋 Deliverables

### Emergency Fix (Today)
- [ ] **Fixed base_settings.py** with optional EMAIL_PORT
- [ ] **Updated staging workflow** with email configuration
- [ ] **Deployed emergency fix** to staging environment
- [ ] **Verified application startup** and basic functionality

### SNS Implementation (This Week)
- [ ] **SNS email backend** (`backends/sns_email.py`)
- [ ] **Notification service** (`services/notifications.py`)
- [ ] **AWS SNS topics** and subscriptions setup
- [ ] **Updated Django settings** with SNS configuration
- [ ] **Integration testing** and deployment

### Infrastructure Module (Next Week)
- [ ] **Terraform SNS module** for EPiC-infrastructure
- [ ] **Environment-specific configurations** (staging/production)
- [ ] **CI/CD integration** with automated deployment
- [ ] **Documentation and runbooks** for operations

---

## 🔧 Quick Reference

### Emergency Commands

#### Fix Staging Now
```bash
# SSH to staging server
ssh ubuntu@your-staging-server

# Update environment file
echo "EMAIL_PORT=587" >> /home/ubuntu/deploy-staging/.env
echo "EMAIL_BACKEND=django.core.mail.backends.console.EmailBackend" >> /home/ubuntu/deploy-staging/.env

# Restart services
cd /home/ubuntu/deploy-staging
docker-compose restart api
```

#### Test Email Configuration
```python
# Django shell test
from django.core.mail import send_mail
send_mail('Test Subject', 'Test message', 'from@example.com', ['to@example.com'])
```

#### Monitor SNS Delivery
```bash
# AWS CLI commands
aws sns list-topics --region ap-southeast-4
aws sns get-topic-attributes --topic-arn arn:aws:sns:ap-southeast-4:account:topic-name
aws logs filter-log-events --log-group-name /aws/sns/ap-southeast-4/account/topic-name
```

---

## 📞 Support and Escalation

### Immediate Support (Emergency)
- **Primary**: Fix EMAIL_PORT configuration issue
- **Secondary**: Deploy console email backend for staging
- **Escalation**: Rollback to previous working configuration

### Implementation Support
- **Development**: SNS backend implementation and testing
- **DevOps**: AWS SNS setup and infrastructure configuration
- **Security**: IAM permissions and access control review

### Post-Implementation
- **Monitoring**: CloudWatch metrics and alerting setup
- **Optimization**: Cost monitoring and delivery optimization
- **Documentation**: Team training and operational procedures

---

## 🎯 Next Steps

### Immediate Actions (Next 2 Hours)
1. **Fix EMAIL_PORT configuration** in staging environment
2. **Update base_settings.py** with default email port value
3. **Deploy emergency fix** to restore staging functionality
4. **Verify application startup** and basic email functionality

### Short-term Implementation (This Week)
1. **Set up AWS SNS topics** for staging and production
2. **Implement Django SNS email backend** and notification service
3. **Deploy SNS integration** and test email delivery
4. **Create documentation** and team training materials

### Long-term Integration (Next Month)
1. **Develop Terraform SNS module** for EPiC-infrastructure
2. **Integrate with broader infrastructure** management system
3. **Expand notification capabilities** for monitoring and alerts
4. **Optimize costs and performance** based on usage patterns

---

**Document Status**: Ready for immediate implementation
**Next Review**: After emergency fix deployment
**Owner**: Development Team + DevOps Team

---

*This document addresses an immediate production issue and provides the foundation for scalable email notification infrastructure.*