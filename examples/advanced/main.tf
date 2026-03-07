################################################################################
# Advanced VPC Example
# 3-AZ VPC with all subnet tiers, multi-AZ NAT, VPC endpoints, and DHCP
################################################################################

provider "aws" {
  region = "us-east-1"
}

module "vpc" {
  source = "../../"

  name       = "advanced-vpc"
  cidr_block = "10.10.0.0/16"

  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

  public_subnet_cidrs      = ["10.10.1.0/24", "10.10.2.0/24", "10.10.3.0/24"]
  private_subnet_cidrs     = ["10.10.11.0/24", "10.10.12.0/24", "10.10.13.0/24"]
  database_subnet_cidrs    = ["10.10.21.0/24", "10.10.22.0/24", "10.10.23.0/24"]
  elasticache_subnet_cidrs = ["10.10.31.0/24", "10.10.32.0/24", "10.10.33.0/24"]
  intra_subnet_cidrs       = ["10.10.41.0/24", "10.10.42.0/24", "10.10.43.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = false

  enable_flow_logs              = true
  flow_log_destination_type     = "cloud-watch-logs"
  flow_log_retention_days       = 90
  flow_log_max_aggregation_interval = 60

  enable_s3_endpoint       = true
  enable_dynamodb_endpoint = true

  enable_dhcp_options      = true
  dhcp_domain_name         = "corp.internal"
  dhcp_domain_name_servers = ["AmazonProvidedDNS"]

  create_database_subnet_group = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }

  tags = {
    Environment = "staging"
    Project     = "advanced-vpc-example"
    CostCenter  = "engineering"
  }
}
