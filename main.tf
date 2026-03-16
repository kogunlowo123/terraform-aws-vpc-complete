data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

################################################################################
# VPC
################################################################################

resource "aws_vpc" "this" {
  cidr_block                       = var.cidr_block
  instance_tenancy                 = var.instance_tenancy
  enable_dns_support               = var.enable_dns_support
  enable_dns_hostnames             = var.enable_dns_hostnames
  assign_generated_ipv6_cidr_block = var.enable_ipv6

  tags = merge(var.tags, {
    Name = var.name
  })
}

resource "aws_vpc_ipv4_cidr_block_association" "secondary" {
  count = length(var.secondary_cidr_blocks)

  vpc_id     = aws_vpc.this.id
  cidr_block = var.secondary_cidr_blocks[count.index]
}

################################################################################
# Internet Gateway
################################################################################

resource "aws_internet_gateway" "this" {
  count = length(var.public_subnet_cidrs) > 0 ? 1 : 0

  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.name}-igw"
  })
}

resource "aws_egress_only_internet_gateway" "this" {
  count = var.enable_ipv6 && length(var.private_subnet_cidrs) > 0 ? 1 : 0

  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.name}-eigw"
  })
}

################################################################################
# Public Subnets
################################################################################

resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index % length(var.availability_zones)]
  map_public_ip_on_launch = true

  ipv6_cidr_block                 = var.enable_ipv6 ? cidrsubnet(aws_vpc.this.ipv6_cidr_block, 8, count.index) : null
  assign_ipv6_address_on_creation = var.enable_ipv6

  tags = merge(var.tags, var.public_subnet_tags, {
    Name = "${var.name}-public-${var.availability_zones[count.index % length(var.availability_zones)]}"
    Tier = "public"
  })
}

resource "aws_route_table" "public" {
  count = length(var.public_subnet_cidrs) > 0 ? 1 : 0

  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.name}-public-rt"
  })
}

resource "aws_route" "public_internet" {
  count = length(var.public_subnet_cidrs) > 0 ? 1 : 0

  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this[0].id
}

resource "aws_route" "public_internet_ipv6" {
  count = var.enable_ipv6 && length(var.public_subnet_cidrs) > 0 ? 1 : 0

  route_table_id              = aws_route_table.public[0].id
  destination_ipv6_cidr_block = "::/0"
  gateway_id                  = aws_internet_gateway.this[0].id
}

resource "aws_route_table_association" "public" {
  count = length(var.public_subnet_cidrs)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[0].id
}

################################################################################
# Private Subnets
################################################################################

resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index % length(var.availability_zones)]

  tags = merge(var.tags, var.private_subnet_tags, {
    Name = "${var.name}-private-${var.availability_zones[count.index % length(var.availability_zones)]}"
    Tier = "private"
  })
}

resource "aws_route_table" "private" {
  count = length(var.private_subnet_cidrs) > 0 ? (var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.availability_zones)) : 0) : 0

  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.name}-private-rt-${var.availability_zones[count.index % length(var.availability_zones)]}"
  })
}

resource "aws_route" "private_nat" {
  count = var.enable_nat_gateway && length(var.private_subnet_cidrs) > 0 ? (var.single_nat_gateway ? 1 : length(var.availability_zones)) : 0

  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[count.index].id
}

resource "aws_route" "private_ipv6_egress" {
  count = var.enable_ipv6 && length(var.private_subnet_cidrs) > 0 ? (var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.availability_zones)) : 0) : 0

  route_table_id              = aws_route_table.private[count.index].id
  destination_ipv6_cidr_block = "::/0"
  egress_only_gateway_id      = aws_egress_only_internet_gateway.this[0].id
}

resource "aws_route_table_association" "private" {
  count = length(var.private_subnet_cidrs)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[var.single_nat_gateway ? 0 : count.index % (var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.availability_zones)) : 1)].id
}

################################################################################
# Database Subnets
################################################################################

resource "aws_subnet" "database" {
  count = length(var.database_subnet_cidrs)

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.database_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index % length(var.availability_zones)]

  tags = merge(var.tags, var.database_subnet_tags, {
    Name = "${var.name}-database-${var.availability_zones[count.index % length(var.availability_zones)]}"
    Tier = "database"
  })
}

resource "aws_route_table" "database" {
  count = length(var.database_subnet_cidrs) > 0 ? 1 : 0

  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.name}-database-rt"
  })
}

resource "aws_route_table_association" "database" {
  count = length(var.database_subnet_cidrs)

  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database[0].id
}

resource "aws_db_subnet_group" "this" {
  count = length(var.database_subnet_cidrs) > 0 && var.create_database_subnet_group ? 1 : 0

  name       = "${var.name}-db-subnet-group"
  subnet_ids = aws_subnet.database[*].id

  tags = merge(var.tags, {
    Name = "${var.name}-db-subnet-group"
  })
}

################################################################################
# Intra Subnets (no internet access)
################################################################################

resource "aws_subnet" "intra" {
  count = length(var.intra_subnet_cidrs)

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.intra_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index % length(var.availability_zones)]

  tags = merge(var.tags, {
    Name = "${var.name}-intra-${var.availability_zones[count.index % length(var.availability_zones)]}"
    Tier = "intra"
  })
}

resource "aws_route_table" "intra" {
  count = length(var.intra_subnet_cidrs) > 0 ? 1 : 0

  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.name}-intra-rt"
  })
}

resource "aws_route_table_association" "intra" {
  count = length(var.intra_subnet_cidrs)

  subnet_id      = aws_subnet.intra[count.index].id
  route_table_id = aws_route_table.intra[0].id
}

################################################################################
# ElastiCache Subnets
################################################################################

resource "aws_subnet" "elasticache" {
  count = length(var.elasticache_subnet_cidrs)

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.elasticache_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index % length(var.availability_zones)]

  tags = merge(var.tags, {
    Name = "${var.name}-elasticache-${var.availability_zones[count.index % length(var.availability_zones)]}"
    Tier = "elasticache"
  })
}

resource "aws_elasticache_subnet_group" "this" {
  count = length(var.elasticache_subnet_cidrs) > 0 ? 1 : 0

  name       = "${var.name}-elasticache-subnet-group"
  subnet_ids = aws_subnet.elasticache[*].id

  tags = merge(var.tags, {
    Name = "${var.name}-elasticache-subnet-group"
  })
}

################################################################################
# NAT Gateway
################################################################################

resource "aws_eip" "nat" {
  count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.availability_zones)) : 0

  domain = "vpc"

  tags = merge(var.tags, {
    Name = "${var.name}-nat-eip-${var.availability_zones[count.index % length(var.availability_zones)]}"
  })

  depends_on = [aws_internet_gateway.this]
}

resource "aws_nat_gateway" "this" {
  count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.availability_zones)) : 0

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(var.tags, {
    Name = "${var.name}-nat-${var.availability_zones[count.index % length(var.availability_zones)]}"
  })

  depends_on = [aws_internet_gateway.this]
}

################################################################################
# VPN Gateway
################################################################################

resource "aws_vpn_gateway" "this" {
  count = var.enable_vpn_gateway ? 1 : 0

  vpc_id          = aws_vpc.this.id
  amazon_side_asn = var.vpn_gateway_asn

  tags = merge(var.tags, {
    Name = "${var.name}-vgw"
  })
}

################################################################################
# DHCP Options
################################################################################

resource "aws_vpc_dhcp_options" "this" {
  count = var.enable_dhcp_options ? 1 : 0

  domain_name         = var.dhcp_domain_name
  domain_name_servers = var.dhcp_domain_name_servers
  ntp_servers         = length(var.dhcp_ntp_servers) > 0 ? var.dhcp_ntp_servers : null

  tags = merge(var.tags, {
    Name = "${var.name}-dhcp-options"
  })
}

resource "aws_vpc_dhcp_options_association" "this" {
  count = var.enable_dhcp_options ? 1 : 0

  vpc_id          = aws_vpc.this.id
  dhcp_options_id = aws_vpc_dhcp_options.this[0].id
}

################################################################################
# Default Security Group (lockdown)
################################################################################

resource "aws_default_security_group" "this" {
  count = var.manage_default_security_group ? 1 : 0

  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.name}-default-sg-restricted"
  })
}

################################################################################
# Default Network ACL
################################################################################

resource "aws_default_network_acl" "this" {
  count = var.manage_default_network_acl ? 1 : 0

  default_network_acl_id = aws_vpc.this.default_network_acl_id

  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = merge(var.tags, {
    Name = "${var.name}-default-nacl"
  })

  lifecycle {
    ignore_changes = [subnet_ids]
  }
}

################################################################################
# VPC Gateway Endpoints
################################################################################

resource "aws_vpc_endpoint" "s3" {
  count = var.enable_s3_endpoint ? 1 : 0

  vpc_id       = aws_vpc.this.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.s3"

  route_table_ids = compact(concat(
    aws_route_table.public[*].id,
    aws_route_table.private[*].id,
    aws_route_table.database[*].id,
    aws_route_table.intra[*].id,
  ))

  tags = merge(var.tags, {
    Name = "${var.name}-s3-endpoint"
  })
}

resource "aws_vpc_endpoint" "dynamodb" {
  count = var.enable_dynamodb_endpoint ? 1 : 0

  vpc_id       = aws_vpc.this.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.dynamodb"

  route_table_ids = compact(concat(
    aws_route_table.public[*].id,
    aws_route_table.private[*].id,
    aws_route_table.database[*].id,
    aws_route_table.intra[*].id,
  ))

  tags = merge(var.tags, {
    Name = "${var.name}-dynamodb-endpoint"
  })
}

################################################################################
# Interface VPC Endpoints
################################################################################

resource "aws_vpc_endpoint" "interface" {
  for_each = var.interface_endpoints

  vpc_id              = aws_vpc.this.id
  service_name        = each.value.service_name
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = each.value.private_dns_enabled

  subnet_ids         = length(each.value.subnet_ids) > 0 ? each.value.subnet_ids : aws_subnet.private[*].id
  security_group_ids = length(each.value.security_group_ids) > 0 ? each.value.security_group_ids : [aws_security_group.vpc_endpoints[0].id]

  tags = merge(var.tags, {
    Name = "${var.name}-${each.key}-endpoint"
  })

  depends_on = [aws_security_group.vpc_endpoints]
}

resource "aws_security_group" "vpc_endpoints" {
  count = length(var.interface_endpoints) > 0 ? 1 : 0

  name_prefix = "${var.name}-vpc-endpoints-"
  description = "Security group for VPC interface endpoints"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.this.cidr_block]
  }

  tags = merge(var.tags, {
    Name = "${var.name}-vpc-endpoints-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

################################################################################
# VPC Flow Logs
################################################################################

resource "aws_flow_log" "this" {
  count = var.enable_flow_logs ? 1 : 0

  vpc_id                   = aws_vpc.this.id
  traffic_type             = "ALL"
  max_aggregation_interval = var.flow_log_max_aggregation_interval

  log_destination_type = var.flow_log_destination_type
  log_destination      = var.flow_log_destination_type == "cloud-watch-logs" ? aws_cloudwatch_log_group.flow_logs[0].arn : aws_s3_bucket.flow_logs[0].arn
  iam_role_arn         = var.flow_log_destination_type == "cloud-watch-logs" ? aws_iam_role.flow_logs[0].arn : null

  log_format = "$${version} $${account-id} $${interface-id} $${srcaddr} $${dstaddr} $${srcport} $${dstport} $${protocol} $${packets} $${bytes} $${start} $${end} $${action} $${log-status} $${vpc-id} $${subnet-id} $${az-id} $${sublocation-type} $${sublocation-id} $${pkt-srcaddr} $${pkt-dstaddr} $${region} $${pkt-src-aws-service} $${pkt-dst-aws-service} $${flow-direction} $${traffic-path}"

  tags = merge(var.tags, {
    Name = "${var.name}-flow-logs"
  })
}

################################################################################
# CloudWatch Log Group for Flow Logs
################################################################################

resource "aws_cloudwatch_log_group" "flow_logs" {
  count = var.enable_flow_logs && var.flow_log_destination_type == "cloud-watch-logs" ? 1 : 0

  name              = "/aws/vpc/flow-logs/${var.name}"
  retention_in_days = var.flow_log_retention_days
  kms_key_id        = aws_kms_key.flow_logs[0].arn

  tags = var.tags
}

################################################################################
# KMS Key for Flow Log Encryption
################################################################################

resource "aws_kms_key" "flow_logs" {
  count = var.enable_flow_logs && var.flow_log_destination_type == "cloud-watch-logs" ? 1 : 0

  description             = "KMS key for VPC flow log encryption - ${var.name}"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableRootAccountFullAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowCloudWatchLogsEncryption"
        Effect = "Allow"
        Principal = {
          Service = "logs.${data.aws_region.current.name}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt*",
          "kms:Decrypt*",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:Describe*"
        ]
        Resource = "*"
        Condition = {
          ArnLike = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/vpc/flow-logs/${var.name}"
          }
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.name}-flow-logs-kms"
  })
}

resource "aws_kms_alias" "flow_logs" {
  count = var.enable_flow_logs && var.flow_log_destination_type == "cloud-watch-logs" ? 1 : 0

  name          = "alias/${var.name}-flow-logs"
  target_key_id = aws_kms_key.flow_logs[0].key_id
}

################################################################################
# S3 Bucket for Flow Logs
################################################################################

resource "aws_s3_bucket" "flow_logs" {
  count = var.enable_flow_logs && var.flow_log_destination_type == "s3" ? 1 : 0

  bucket_prefix = "${var.name}-flow-logs-"
  force_destroy = false

  tags = merge(var.tags, {
    Name = "${var.name}-flow-logs"
  })
}

resource "aws_s3_bucket_versioning" "flow_logs" {
  count = var.enable_flow_logs && var.flow_log_destination_type == "s3" ? 1 : 0

  bucket = aws_s3_bucket.flow_logs[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "flow_logs" {
  count = var.enable_flow_logs && var.flow_log_destination_type == "s3" ? 1 : 0

  bucket = aws_s3_bucket.flow_logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "flow_logs" {
  count = var.enable_flow_logs && var.flow_log_destination_type == "s3" ? 1 : 0

  bucket = aws_s3_bucket.flow_logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "flow_logs" {
  count = var.enable_flow_logs && var.flow_log_destination_type == "s3" ? 1 : 0

  bucket = aws_s3_bucket.flow_logs[0].id

  rule {
    id     = "flow-log-retention"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = var.flow_log_retention_days > 0 ? var.flow_log_retention_days : 365
    }
  }
}

################################################################################
# IAM Role for CloudWatch Flow Logs
################################################################################

resource "aws_iam_role" "flow_logs" {
  count = var.enable_flow_logs && var.flow_log_destination_type == "cloud-watch-logs" ? 1 : 0

  name_prefix = "${var.name}-flow-logs-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowFlowLogsAssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "flow_logs" {
  count = var.enable_flow_logs && var.flow_log_destination_type == "cloud-watch-logs" ? 1 : 0

  name_prefix = "${var.name}-flow-logs-"
  role        = aws_iam_role.flow_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "${aws_cloudwatch_log_group.flow_logs[0].arn}:*"
      }
    ]
  })
}
