################################################################################
# AWS VPC IPAM - IP Address Management
################################################################################

resource "aws_vpc_ipam" "this" {
  description = var.description

  dynamic "operating_regions" {
    for_each = var.operating_regions

    content {
      region_name = operating_regions.value
    }
  }

  tags = merge(var.tags, {
    Name = var.name
  })
}

resource "aws_vpc_ipam_pool" "this" {
  address_family = "ipv4"
  ipam_scope_id  = aws_vpc_ipam.this.private_default_scope_id
  locale         = var.pool_locale

  allocation_default_netmask_length = var.default_netmask_length
  allocation_min_netmask_length     = var.min_netmask_length
  allocation_max_netmask_length     = var.max_netmask_length

  tags = merge(var.tags, {
    Name = "${var.name}-pool"
  })
}

resource "aws_vpc_ipam_pool_cidr" "this" {
  for_each = toset(var.pool_cidrs)

  ipam_pool_id = aws_vpc_ipam_pool.this.id
  cidr         = each.value
}
