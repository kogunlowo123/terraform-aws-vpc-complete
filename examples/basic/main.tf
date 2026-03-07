################################################################################
# Basic VPC Example
# Creates a simple 2-tier VPC with public and private subnets
################################################################################

provider "aws" {
  region = "us-east-1"
}

module "vpc" {
  source = "../../"

  name       = "basic-vpc"
  cidr_block = "10.0.0.0/16"

  availability_zones   = ["us-east-1a", "us-east-1b"]
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  enable_flow_logs = true

  tags = {
    Environment = "dev"
    Project     = "basic-vpc-example"
  }
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnets" {
  value = module.vpc.public_subnet_ids
}

output "private_subnets" {
  value = module.vpc.private_subnet_ids
}
