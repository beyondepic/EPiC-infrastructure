# Shared Networking Module

This module creates a comprehensive networking foundation for AWS infrastructure, including VPC, subnets, security groups, and related networking components.

## Features

- **VPC** with configurable CIDR block
- **Multi-tier subnet architecture** (public, private, database)
- **High availability** across multiple availability zones
- **NAT Gateways** for secure outbound connectivity from private subnets
- **Security Groups** for web, application, and database tiers
- **VPC Flow Logs** for network monitoring and troubleshooting
- **Database subnet group** for RDS deployments

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                       Internet Gateway                      │
└──────────────────┬──────────────────────────────────────────┘
                   │
┌─────────────────────────────────────────────────────────────┐
│                    Public Subnets                          │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │ Public-1    │  │ Public-2    │  │ Public-3    │         │
│  │ NAT GW      │  │ NAT GW      │  │             │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
└─────────────────────────────────────────────────────────────┘
                   │
┌─────────────────────────────────────────────────────────────┐
│                   Private Subnets                          │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │ Private-1   │  │ Private-2   │  │ Private-3   │         │
│  │ App Tier    │  │ App Tier    │  │ App Tier    │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
└─────────────────────────────────────────────────────────────┘
                   │
┌─────────────────────────────────────────────────────────────┐
│                  Database Subnets                          │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │ Database-1  │  │ Database-2  │  │ Database-3  │         │
│  │ RDS/Aurora  │  │ RDS/Aurora  │  │ RDS/Aurora  │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
└─────────────────────────────────────────────────────────────┘
```

## Usage

```hcl
module "shared_networking" {
  source = "../../modules/shared-networking"

  project_name = "epic"
  environment  = "shared"
  vpc_cidr     = "10.0.0.0/16"

  public_subnet_count   = 3
  private_subnet_count  = 3
  database_subnet_count = 3

  enable_nat_gateway    = true
  nat_gateway_count     = 2
  enable_flow_logs      = true

  additional_tags = {
    Owner = "Platform Team"
    Cost  = "Shared"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.6 |
| aws | ~> 5.0 |

## Resources Created

- 1 VPC
- 3-9 Subnets (configurable)
- 1 Internet Gateway
- 0-3 NAT Gateways (configurable)
- 1-3 Route Tables
- 3 Security Groups (web, application, database)
- 1 DB Subnet Group
- VPC Flow Logs (optional)

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project_name | Name of the project | `string` | n/a | yes |
| environment | Environment name | `string` | n/a | yes |
| vpc_cidr | CIDR block for the VPC | `string` | `"10.0.0.0/16"` | no |
| public_subnet_count | Number of public subnets | `number` | `3` | no |
| private_subnet_count | Number of private subnets | `number` | `3` | no |
| database_subnet_count | Number of database subnets | `number` | `3` | no |
| enable_nat_gateway | Enable NAT Gateway | `bool` | `true` | no |
| nat_gateway_count | Number of NAT Gateways | `number` | `2` | no |
| enable_flow_logs | Enable VPC Flow Logs | `bool` | `true` | no |
| flow_logs_retention_days | Flow logs retention period | `number` | `14` | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | ID of the VPC |
| vpc_cidr_block | CIDR block of the VPC |
| public_subnet_ids | IDs of the public subnets |
| private_subnet_ids | IDs of the private subnets |
| database_subnet_ids | IDs of the database subnets |
| web_security_group_id | ID of the web security group |
| application_security_group_id | ID of the application security group |
| database_security_group_id | ID of the database security group |
| db_subnet_group_name | Name of the database subnet group |

## Security Considerations

- **Network Segmentation**: Three-tier architecture with proper isolation
- **Least Privilege**: Security groups follow principle of least privilege
- **Monitoring**: VPC Flow Logs enabled for security monitoring
- **High Availability**: Resources distributed across multiple AZs
- **Secure Connectivity**: NAT Gateways provide secure outbound access

## Cost Optimization

- **Configurable NAT Gateways**: Reduce costs by adjusting NAT Gateway count
- **Flow Logs Retention**: Configurable retention period to manage storage costs
- **Right-sizing**: Choose appropriate subnet counts based on requirements