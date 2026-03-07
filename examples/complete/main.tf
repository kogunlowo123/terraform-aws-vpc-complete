################################################################################
# Complete VPC Example
# Full enterprise VPC with all features enabled
################################################################################

provider "aws" {
  region = "us-east-1"
}

module "vpc" {
  source = "../../"

  name             = "enterprise-vpc"
  cidr_block       = "10.100.0.0/16"
  instance_tenancy = "default"
  enable_ipv6      = true

  secondary_cidr_blocks = ["100.64.0.0/16"]

  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

  public_subnet_cidrs      = ["10.100.1.0/24", "10.100.2.0/24", "10.100.3.0/24"]
  private_subnet_cidrs     = ["10.100.11.0/24", "10.100.12.0/24", "10.100.13.0/24"]
  database_subnet_cidrs    = ["10.100.21.0/24", "10.100.22.0/24", "10.100.23.0/24"]
  elasticache_subnet_cidrs = ["10.100.31.0/24", "10.100.32.0/24", "10.100.33.0/24"]
  intra_subnet_cidrs       = ["10.100.41.0/24", "10.100.42.0/24", "10.100.43.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = false

  enable_vpn_gateway = true
  vpn_gateway_asn    = 65000

  enable_flow_logs                  = true
  flow_log_destination_type         = "s3"
  flow_log_retention_days           = 365
  flow_log_max_aggregation_interval = 60

  enable_s3_endpoint       = true
  enable_dynamodb_endpoint = true

  interface_endpoints = {
    ssm = {
      service_name = "com.amazonaws.us-east-1.ssm"
    }
    ssmmessages = {
      service_name = "com.amazonaws.us-east-1.ssmmessages"
    }
    ec2messages = {
      service_name = "com.amazonaws.us-east-1.ec2messages"
    }
    ecr_api = {
      service_name = "com.amazonaws.us-east-1.ecr.api"
    }
    ecr_dkr = {
      service_name = "com.amazonaws.us-east-1.ecr.dkr"
    }
    logs = {
      service_name = "com.amazonaws.us-east-1.logs"
    }
    sts = {
      service_name = "com.amazonaws.us-east-1.sts"
    }
    kms = {
      service_name = "com.amazonaws.us-east-1.kms"
    }
  }

  enable_dhcp_options      = true
  dhcp_domain_name         = "enterprise.internal"
  dhcp_domain_name_servers = ["AmazonProvidedDNS"]
  dhcp_ntp_servers         = ["169.254.169.123"]

  manage_default_security_group = true
  manage_default_network_acl    = true
  create_database_subnet_group  = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
    Tier                     = "public"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
    Tier                              = "private"
  }

  database_subnet_tags = {
    Tier = "database"
  }

  tags = {
    Environment  = "production"
    Project      = "enterprise-platform"
    CostCenter   = "infrastructure"
    Compliance   = "pci-dss"
    ManagedBy    = "terraform"
  }
}
