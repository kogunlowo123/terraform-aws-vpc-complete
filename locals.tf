locals {
  nat_gateway_count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.availability_zones)) : 0

  common_tags = merge(var.tags, {
    ManagedBy = "terraform"
    Module    = "terraform-aws-vpc-complete"
  })

  public_subnet_count      = length(var.public_subnet_cidrs)
  private_subnet_count     = length(var.private_subnet_cidrs)
  database_subnet_count    = length(var.database_subnet_cidrs)
  intra_subnet_count       = length(var.intra_subnet_cidrs)
  elasticache_subnet_count = length(var.elasticache_subnet_cidrs)

  max_subnet_length = max(
    local.public_subnet_count,
    local.private_subnet_count,
    local.database_subnet_count,
    local.intra_subnet_count,
    local.elasticache_subnet_count,
  )
}
