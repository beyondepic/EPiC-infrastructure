# Web Application Module

This Terraform module provisions a highly available, scalable web application infrastructure on AWS with integrated security features including AWS WAF protection.

## Features

### Core Infrastructure
- **Auto Scaling Group (ASG)** - Automatically scales EC2 instances based on CPU utilization
- **Application Load Balancer (ALB)** - Distributes traffic across healthy instances
- **Launch Template** - Standardized EC2 instance configuration
- **Target Group** - Health check and routing configuration

### Security Features
- **AWS WAF Integration** - Advanced web application firewall protection
  - AWS Managed Core Rule Set
  - Known Bad Inputs protection
  - SQL injection protection
  - Rate limiting (configurable)
  - Geographic blocking (optional)
- **Security Groups** - Instance and ALB traffic control
- **IAM Instance Profile** - Least privilege EC2 permissions

### Monitoring & Scaling
- **CloudWatch Alarms** - CPU-based scaling triggers
- **Auto Scaling Policies** - Scale up/down based on demand
- **Health Checks** - Application-level health monitoring
- **Access Logs** - ALB request logging to S3

### SSL/HTTPS Support
- **SSL Certificate Integration** - ACM certificate support
- **HTTPS Listener** - Secure traffic handling
- **HTTP to HTTPS Redirect** - Automatic secure redirection

## Usage

### Basic Example

```hcl
module "web_application" {
  source = "../../modules/web-application"

  # Required Variables
  project_name          = "nestedphoenix"
  environment          = "production"
  application_name     = "web-app"
  vpc_id              = module.shared_networking.vpc_id
  subnet_ids          = module.shared_networking.private_subnet_ids
  public_subnet_ids   = module.shared_networking.public_subnet_ids
  security_group_id   = module.shared_networking.application_security_group_id
  alb_security_group_id = module.shared_networking.web_security_group_id
  instance_profile_name = module.security_baseline.ec2_instance_profile_name

  # Optional Customizations
  instance_type    = "t3.medium"
  min_size        = 2
  max_size        = 10
  desired_capacity = 3

  # WAF Configuration
  enable_waf      = true
  waf_rate_limit  = 2000
  enable_geo_blocking = false

  # SSL Configuration
  ssl_certificate_arn = "arn:aws:acm:region:account:certificate/cert-id"
}
```

### Advanced Example with WAF and Geographic Blocking

```hcl
module "web_application" {
  source = "../../modules/web-application"

  # Required Variables
  project_name          = "nestedphoenix"
  environment          = "production"
  application_name     = "secure-web-app"
  vpc_id              = module.shared_networking.vpc_id
  subnet_ids          = module.shared_networking.private_subnet_ids
  public_subnet_ids   = module.shared_networking.public_subnet_ids
  security_group_id   = module.shared_networking.application_security_group_id
  alb_security_group_id = module.shared_networking.web_security_group_id
  instance_profile_name = module.security_baseline.ec2_instance_profile_name

  # Instance Configuration
  instance_type           = "m5.large"
  root_volume_size       = 50
  enable_detailed_monitoring = true

  # Auto Scaling Configuration
  min_size               = 3
  max_size              = 20
  desired_capacity      = 5
  scale_up_threshold    = 70
  scale_down_threshold  = 30

  # Load Balancer Configuration
  target_port           = 8080
  health_check_path     = "/api/health"
  enable_stickiness     = true
  enable_deletion_protection = true
  enable_access_logs    = true
  access_logs_bucket    = "my-alb-logs-bucket"

  # WAF Security Configuration
  enable_waf           = true
  waf_rate_limit       = 1000
  enable_geo_blocking  = true
  blocked_countries    = ["CN", "RU", "KP"]

  # SSL Configuration
  ssl_certificate_arn  = "arn:aws:acm:us-east-1:123456789012:certificate/abcd1234-efgh-5678-ijkl-mnop9012qrst"
  ssl_policy          = "ELBSecurityPolicy-TLS-1-2-2017-01"

  # Additional Tags
  additional_tags = {
    Owner       = "DevOps Team"
    Environment = "production"
    Project     = "nestedphoenix"
  }
}
```

## Variables

### Required Variables

| Name | Type | Description |
|------|------|-------------|
| `project_name` | `string` | Name of the project (1-50 chars, alphanumeric + hyphens) |
| `environment` | `string` | Environment name (staging, production) |
| `application_name` | `string` | Name of the application (1-50 chars, alphanumeric + hyphens) |
| `vpc_id` | `string` | ID of the VPC |
| `subnet_ids` | `list(string)` | List of subnet IDs for the Auto Scaling Group |
| `public_subnet_ids` | `list(string)` | List of public subnet IDs for the ALB |
| `security_group_id` | `string` | Security group ID for EC2 instances |
| `alb_security_group_id` | `string` | Security group ID for the ALB |
| `instance_profile_name` | `string` | Name of the IAM instance profile |

### Optional Variables

#### Instance Configuration
| Name | Type | Default | Description |
|------|------|---------|-------------|
| `ami_id` | `string` | `null` | AMI ID (defaults to latest Amazon Linux 2) |
| `instance_type` | `string` | `"t3.micro"` | EC2 instance type |
| `key_pair_name` | `string` | `null` | EC2 Key Pair name for SSH access |
| `root_volume_size` | `number` | `20` | Root EBS volume size in GB (8-1000) |
| `enable_detailed_monitoring` | `bool` | `true` | Enable detailed CloudWatch monitoring |

#### Auto Scaling Configuration
| Name | Type | Default | Description |
|------|------|---------|-------------|
| `min_size` | `number` | `1` | Minimum number of instances (0-100) |
| `max_size` | `number` | `5` | Maximum number of instances (1-1000) |
| `desired_capacity` | `number` | `2` | Desired number of instances (0-1000) |
| `scale_up_threshold` | `number` | `75` | CPU utilization threshold for scaling up (1-100%) |
| `scale_down_threshold` | `number` | `25` | CPU utilization threshold for scaling down (1-100%) |

#### Load Balancer Configuration
| Name | Type | Default | Description |
|------|------|---------|-------------|
| `target_port` | `number` | `80` | Port for the target group (1-65535) |
| `health_check_path` | `string` | `"/health"` | Health check path |
| `enable_stickiness` | `bool` | `false` | Enable session stickiness |
| `enable_deletion_protection` | `bool` | `false` | Enable deletion protection |
| `enable_access_logs` | `bool` | `true` | Enable ALB access logs |
| `access_logs_bucket` | `string` | `null` | S3 bucket for access logs |

#### WAF Configuration
| Name | Type | Default | Description |
|------|------|---------|-------------|
| `enable_waf` | `bool` | `true` | Enable AWS WAF protection |
| `waf_rate_limit` | `number` | `2000` | Rate limit per 5-minute period |
| `enable_geo_blocking` | `bool` | `false` | Enable geographic blocking |
| `blocked_countries` | `list(string)` | `[]` | List of 2-letter country codes to block |

#### SSL Configuration
| Name | Type | Default | Description |
|------|------|---------|-------------|
| `ssl_certificate_arn` | `string` | `null` | ARN of SSL certificate for HTTPS |
| `ssl_policy` | `string` | `"ELBSecurityPolicy-TLS-1-2-2017-01"` | SSL policy for HTTPS listener |

## Outputs

### Auto Scaling Group
| Name | Description |
|------|-------------|
| `autoscaling_group_id` | ID of the Auto Scaling Group |
| `autoscaling_group_name` | Name of the Auto Scaling Group |
| `autoscaling_group_arn` | ARN of the Auto Scaling Group |

### Launch Template
| Name | Description |
|------|-------------|
| `launch_template_id` | ID of the Launch Template |
| `launch_template_latest_version` | Latest version of the Launch Template |

### Load Balancer
| Name | Description |
|------|-------------|
| `load_balancer_id` | ID of the Application Load Balancer |
| `load_balancer_arn` | ARN of the Application Load Balancer |
| `load_balancer_dns_name` | DNS name of the Application Load Balancer |
| `load_balancer_zone_id` | Canonical hosted zone ID of the load balancer |

### Target Group
| Name | Description |
|------|-------------|
| `target_group_id` | ID of the Target Group |
| `target_group_arn` | ARN of the Target Group |

### Listeners
| Name | Description |
|------|-------------|
| `http_listener_arn` | ARN of the HTTP listener |
| `https_listener_arn` | ARN of the HTTPS listener (if SSL enabled) |

### Auto Scaling Policies
| Name | Description |
|------|-------------|
| `scale_up_policy_arn` | ARN of the scale up policy |
| `scale_down_policy_arn` | ARN of the scale down policy |

### CloudWatch Alarms
| Name | Description |
|------|-------------|
| `cpu_high_alarm_arn` | ARN of the CPU high alarm |
| `cpu_low_alarm_arn` | ARN of the CPU low alarm |

### WAF Outputs
| Name | Description |
|------|-------------|
| `waf_web_acl_arn` | ARN of the WAF Web ACL (if enabled) |
| `waf_web_acl_id` | ID of the WAF Web ACL (if enabled) |
| `waf_web_acl_name` | Name of the WAF Web ACL (if enabled) |

## Security Considerations

### WAF Protection
This module includes comprehensive WAF protection by default:
- **Core Rule Set**: Protects against OWASP Top 10 vulnerabilities
- **Known Bad Inputs**: Blocks requests with known malicious patterns
- **SQL Injection Protection**: Specifically targets SQL injection attempts
- **Rate Limiting**: Prevents DDoS and brute force attacks
- **Geographic Blocking**: Optional country-based access control

### Network Security
- EC2 instances are deployed in private subnets
- ALB is deployed in public subnets with restricted security groups
- All traffic between ALB and instances uses security group rules

### Data Protection
- EBS volumes are encrypted by default
- Access logs can be stored in encrypted S3 buckets
- HTTPS redirection enforces encryption in transit

## Dependencies

This module requires the following:
- VPC with public and private subnets
- Security groups for web tier and application tier
- IAM instance profile with necessary permissions

## Examples

See the `examples/` directory for complete working examples:
- `basic-web-app/` - Simple web application setup
- `secure-web-app/` - Production setup with WAF and SSL
- `multi-environment/` - Staging and production configurations

## Troubleshooting

### Common Issues

1. **Health Check Failures**
   - Verify the application is listening on the correct port
   - Check that the health check path returns a 200 status code
   - Ensure security groups allow traffic on the target port

2. **Auto Scaling Issues**
   - Check CloudWatch metrics for CPU utilization
   - Verify scaling policies are configured correctly
   - Review Auto Scaling Group events for errors

3. **WAF Blocking Legitimate Traffic**
   - Review WAF logs in CloudWatch
   - Adjust rate limiting thresholds if necessary
   - Consider adding custom allow rules for specific IPs

### Monitoring

Monitor your web application using:
- CloudWatch dashboards for key metrics
- ALB access logs for request analysis
- WAF logs for security insights
- Auto Scaling Group activities

## Version History

- **v2.0.0** - Added comprehensive WAF protection and input validation
- **v1.1.0** - Added SSL/HTTPS support and geographic blocking
- **v1.0.0** - Initial implementation with basic ALB and ASG