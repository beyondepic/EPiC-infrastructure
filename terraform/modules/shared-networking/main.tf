# Shared Networking Infrastructure Module
# Creates VPC, subnets, security groups, and networking components

data "aws_availability_zones" "available" {
  state = "available"
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-vpc"
    Environment = var.environment
    Module      = "shared-networking"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-${var.environment}-igw"
    Environment = var.environment
    Module      = "shared-networking"
  }
}

# Public Subnets
resource "aws_subnet" "public" {
  count = var.public_subnet_count

  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-public-${count.index + 1}"
    Type        = "Public"
    Environment = var.environment
    Module      = "shared-networking"
  }
}

# Private Subnets
resource "aws_subnet" "private" {
  count = var.private_subnet_count

  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + var.public_subnet_count)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name        = "${var.project_name}-${var.environment}-private-${count.index + 1}"
    Type        = "Private"
    Environment = var.environment
    Module      = "shared-networking"
  }
}

# Database Subnets
resource "aws_subnet" "database" {
  count = var.database_subnet_count

  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + var.public_subnet_count + var.private_subnet_count)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name        = "${var.project_name}-${var.environment}-database-${count.index + 1}"
    Type        = "Database"
    Environment = var.environment
    Module      = "shared-networking"
  }
}

# Elastic IPs for NAT Gateways
resource "aws_eip" "nat" {
  count = var.enable_nat_gateway ? var.nat_gateway_count : 0

  domain = "vpc"

  tags = {
    Name        = "${var.project_name}-${var.environment}-nat-eip-${count.index + 1}"
    Environment = var.environment
    Module      = "shared-networking"
  }

  depends_on = [aws_internet_gateway.main]
}

# NAT Gateways
resource "aws_nat_gateway" "main" {
  count = var.enable_nat_gateway ? var.nat_gateway_count : 0

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name        = "${var.project_name}-${var.environment}-nat-${count.index + 1}"
    Environment = var.environment
    Module      = "shared-networking"
  }

  depends_on = [aws_internet_gateway.main]
}

# Route Table for Public Subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-public-rt"
    Environment = var.environment
    Module      = "shared-networking"
  }
}

# Route Tables for Private Subnets
resource "aws_route_table" "private" {
  count = var.enable_nat_gateway ? var.nat_gateway_count : 1

  vpc_id = aws_vpc.main.id

  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.main[count.index % length(aws_nat_gateway.main)].id
    }
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-private-rt-${count.index + 1}"
    Environment = var.environment
    Module      = "shared-networking"
  }
}

# Route Table for Database Subnets
resource "aws_route_table" "database" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-${var.environment}-database-rt"
    Environment = var.environment
    Module      = "shared-networking"
  }
}

# Route Table Associations
resource "aws_route_table_association" "public" {
  count = var.public_subnet_count

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count = var.private_subnet_count

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index % length(aws_route_table.private)].id
}

resource "aws_route_table_association" "database" {
  count = var.database_subnet_count

  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database.id
}

# VPC Flow Logs
resource "aws_flow_log" "vpc_flow_log" {
  count = var.enable_flow_logs ? 1 : 0

  iam_role_arn    = aws_iam_role.flow_log[0].arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_log[0].arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id
}

resource "aws_cloudwatch_log_group" "vpc_flow_log" {
  count = var.enable_flow_logs ? 1 : 0

  name              = "/aws/vpc/flowlogs/${var.project_name}-${var.environment}"
  retention_in_days = var.flow_logs_retention_days

  tags = {
    Name        = "${var.project_name}-${var.environment}-vpc-flow-logs"
    Environment = var.environment
    Module      = "shared-networking"
  }
}

resource "aws_iam_role" "flow_log" {
  count = var.enable_flow_logs ? 1 : 0

  name_prefix = "${var.project_name}-${var.environment}-flow-log-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-flow-log-role"
    Environment = var.environment
    Module      = "shared-networking"
  }
}

resource "aws_iam_role_policy" "flow_log" {
  count = var.enable_flow_logs ? 1 : 0

  name_prefix = "${var.project_name}-${var.environment}-flow-log-"
  role        = aws_iam_role.flow_log[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect = "Allow"
        Resource = "*"
      }
    ]
  })
}

# Security Groups
resource "aws_security_group" "web" {
  name_prefix = "${var.project_name}-${var.environment}-web-"
  description = "Security group for web servers"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-web-sg"
    Environment = var.environment
    Module      = "shared-networking"
  }
}

resource "aws_security_group" "application" {
  name_prefix = "${var.project_name}-${var.environment}-app-"
  description = "Security group for application servers"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Application traffic from web tier"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-app-sg"
    Environment = var.environment
    Module      = "shared-networking"
  }
}

resource "aws_security_group" "database" {
  name_prefix = "${var.project_name}-${var.environment}-db-"
  description = "Security group for database servers"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "MySQL/Aurora"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.application.id]
  }

  ingress {
    description     = "PostgreSQL"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.application.id]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-db-sg"
    Environment = var.environment
    Module      = "shared-networking"
  }
}

# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  count = var.database_subnet_count > 0 ? 1 : 0

  name       = "${var.project_name}-${var.environment}-db-subnet-group"
  subnet_ids = aws_subnet.database[*].id

  tags = {
    Name        = "${var.project_name}-${var.environment}-db-subnet-group"
    Environment = var.environment
    Module      = "shared-networking"
  }
}