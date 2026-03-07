################################################################################
# VPC
################################################################################

resource "aws_vpc" "this" {
  cidr_block                           = var.cidr_block
  instance_tenancy                     = var.instance_tenancy
  enable_dns_support                   = var.enable_dns_support
  enable_dns_hostnames                 = var.enable_dns_hostnames
  assign_generated_ipv6_cidr_block     = var.enable_ipv6

  tags = merge(local.common_tags, {
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
  count = local.public_subnet_count > 0 ? 1 : 0

  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = "${var.name}-igw"
  })
}

resource "aws_egress_only_internet_gateway" "this" {
  count = var.enable_ipv6 && local.private_subnet_count > 0 ? 1 : 0

  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = "${var.name}-eigw"
  })
}

################################################################################
# Public Subnets
################################################################################

resource "aws_subnet" "public" {
  count = local.public_subnet_count

  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index % length(var.availability_zones)]
  map_public_ip_on_launch = true

  ipv6_cidr_block                 = var.enable_ipv6 ? cidrsubnet(aws_vpc.this.ipv6_cidr_block, 8, count.index) : null
  assign_ipv6_address_on_creation = var.enable_ipv6

  tags = merge(local.common_tags, var.public_subnet_tags, {
    Name = "${var.name}-public-${var.availability_zones[count.index % length(var.availability_zones)]}"
    Tier = "public"
  })
}

resource "aws_route_table" "public" {
  count = local.public_subnet_count > 0 ? 1 : 0

  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = "${var.name}-public-rt"
  })
}

resource "aws_route" "public_internet" {
  count = local.public_subnet_count > 0 ? 1 : 0

  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this[0].id
}

resource "aws_route" "public_internet_ipv6" {
  count = var.enable_ipv6 && local.public_subnet_count > 0 ? 1 : 0

  route_table_id              = aws_route_table.public[0].id
  destination_ipv6_cidr_block = "::/0"
  gateway_id                  = aws_internet_gateway.this[0].id
}

resource "aws_route_table_association" "public" {
  count = local.public_subnet_count

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[0].id
}

################################################################################
# Private Subnets
################################################################################

resource "aws_subnet" "private" {
  count = local.private_subnet_count

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index % length(var.availability_zones)]

  tags = merge(local.common_tags, var.private_subnet_tags, {
    Name = "${var.name}-private-${var.availability_zones[count.index % length(var.availability_zones)]}"
    Tier = "private"
  })
}

resource "aws_route_table" "private" {
  count = local.private_subnet_count > 0 ? local.nat_gateway_count : 0

  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = "${var.name}-private-rt-${var.availability_zones[count.index % length(var.availability_zones)]}"
  })
}

resource "aws_route" "private_nat" {
  count = var.enable_nat_gateway && local.private_subnet_count > 0 ? local.nat_gateway_count : 0

  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[count.index].id
}

resource "aws_route" "private_ipv6_egress" {
  count = var.enable_ipv6 && local.private_subnet_count > 0 ? local.nat_gateway_count : 0

  route_table_id              = aws_route_table.private[count.index].id
  destination_ipv6_cidr_block = "::/0"
  egress_only_gateway_id      = aws_egress_only_internet_gateway.this[0].id
}

resource "aws_route_table_association" "private" {
  count = local.private_subnet_count

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[var.single_nat_gateway ? 0 : count.index % local.nat_gateway_count].id
}

################################################################################
# Database Subnets
################################################################################

resource "aws_subnet" "database" {
  count = local.database_subnet_count

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.database_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index % length(var.availability_zones)]

  tags = merge(local.common_tags, var.database_subnet_tags, {
    Name = "${var.name}-database-${var.availability_zones[count.index % length(var.availability_zones)]}"
    Tier = "database"
  })
}

resource "aws_route_table" "database" {
  count = local.database_subnet_count > 0 ? 1 : 0

  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = "${var.name}-database-rt"
  })
}

resource "aws_route_table_association" "database" {
  count = local.database_subnet_count

  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database[0].id
}

resource "aws_db_subnet_group" "this" {
  count = local.database_subnet_count > 0 && var.create_database_subnet_group ? 1 : 0

  name       = "${var.name}-db-subnet-group"
  subnet_ids = aws_subnet.database[*].id

  tags = merge(local.common_tags, {
    Name = "${var.name}-db-subnet-group"
  })
}

################################################################################
# Intra Subnets (no internet access)
################################################################################

resource "aws_subnet" "intra" {
  count = local.intra_subnet_count

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.intra_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index % length(var.availability_zones)]

  tags = merge(local.common_tags, {
    Name = "${var.name}-intra-${var.availability_zones[count.index % length(var.availability_zones)]}"
    Tier = "intra"
  })
}

resource "aws_route_table" "intra" {
  count = local.intra_subnet_count > 0 ? 1 : 0

  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = "${var.name}-intra-rt"
  })
}

resource "aws_route_table_association" "intra" {
  count = local.intra_subnet_count

  subnet_id      = aws_subnet.intra[count.index].id
  route_table_id = aws_route_table.intra[0].id
}

################################################################################
# ElastiCache Subnets
################################################################################

resource "aws_subnet" "elasticache" {
  count = local.elasticache_subnet_count

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.elasticache_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index % length(var.availability_zones)]

  tags = merge(local.common_tags, {
    Name = "${var.name}-elasticache-${var.availability_zones[count.index % length(var.availability_zones)]}"
    Tier = "elasticache"
  })
}

resource "aws_elasticache_subnet_group" "this" {
  count = local.elasticache_subnet_count > 0 ? 1 : 0

  name       = "${var.name}-elasticache-subnet-group"
  subnet_ids = aws_subnet.elasticache[*].id

  tags = merge(local.common_tags, {
    Name = "${var.name}-elasticache-subnet-group"
  })
}

################################################################################
# NAT Gateway
################################################################################

resource "aws_eip" "nat" {
  count = local.nat_gateway_count

  domain = "vpc"

  tags = merge(local.common_tags, {
    Name = "${var.name}-nat-eip-${var.availability_zones[count.index % length(var.availability_zones)]}"
  })

  depends_on = [aws_internet_gateway.this]
}

resource "aws_nat_gateway" "this" {
  count = local.nat_gateway_count

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(local.common_tags, {
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

  tags = merge(local.common_tags, {
    Name = "${var.name}-vgw"
  })
}

################################################################################
# DHCP Options
################################################################################

resource "aws_vpc_dhcp_options" "this" {
  count = var.enable_dhcp_options ? 1 : 0

  domain_name          = var.dhcp_domain_name
  domain_name_servers  = var.dhcp_domain_name_servers
  ntp_servers          = length(var.dhcp_ntp_servers) > 0 ? var.dhcp_ntp_servers : null

  tags = merge(local.common_tags, {
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

  tags = merge(local.common_tags, {
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

  tags = merge(local.common_tags, {
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

  tags = merge(local.common_tags, {
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

  tags = merge(local.common_tags, {
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

  tags = merge(local.common_tags, {
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

  tags = merge(local.common_tags, {
    Name = "${var.name}-vpc-endpoints-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}
