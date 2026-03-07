# VPC Peering Sub-module

Manages VPC peering connections with support for cross-account, cross-region peering, DNS resolution, and automatic route creation.

## Usage

```hcl
module "vpc_peering" {
  source = "../../modules/vpc-peering"

  name              = "prod-to-shared"
  requester_vpc_id  = module.vpc_prod.vpc_id
  accepter_vpc_id   = module.vpc_shared.vpc_id
  requester_vpc_cidr = "10.0.0.0/16"
  accepter_vpc_cidr  = "10.1.0.0/16"
  auto_accept        = true

  requester_route_table_ids = module.vpc_prod.private_route_table_ids
  accepter_route_table_ids  = module.vpc_shared.private_route_table_ids

  tags = { Environment = "production" }
}
```

## References

- [VPC Peering Documentation](https://docs.aws.amazon.com/vpc/latest/peering/what-is-vpc-peering.html)
- [Terraform aws_vpc_peering_connection](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_peering_connection)
