################################################################################
# IPv6 Dual-Stack VPC Example
################################################################################

provider "aws" {
  region = "us-west-2"
}

module "vpc" {
  source = "../../"

  name        = "ipv6-vpc"
  cidr_block  = "10.50.0.0/16"
  enable_ipv6 = true

  availability_zones   = ["us-west-2a", "us-west-2b"]
  public_subnet_cidrs  = ["10.50.1.0/24", "10.50.2.0/24"]
  private_subnet_cidrs = ["10.50.11.0/24", "10.50.12.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  enable_flow_logs = true

  tags = {
    Environment = "dev"
    Project     = "ipv6-dual-stack-example"
  }
}

output "vpc_ipv6_cidr" {
  value = module.vpc.vpc_ipv6_cidr_block
}
