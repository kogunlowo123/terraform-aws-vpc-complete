# IPAM Sub-module

Manages AWS VPC IP Address Manager (IPAM) for centralized IP address planning and allocation across your AWS organization.

## Usage

```hcl
module "ipam" {
  source = "../../modules/ipam"

  name              = "corp-ipam"
  operating_regions = ["us-east-1", "eu-west-1"]
  pool_locale       = "us-east-1"
  pool_cidrs        = ["10.0.0.0/8"]

  default_netmask_length = 24
  min_netmask_length     = 16
  max_netmask_length     = 28

  tags = {
    Environment = "production"
  }
}
```

## Resources Created

- `aws_vpc_ipam` - IPAM instance
- `aws_vpc_ipam_pool` - IPv4 address pool
- `aws_vpc_ipam_pool_cidr` - CIDR provisioned into the pool

## References

- [AWS IPAM Documentation](https://docs.aws.amazon.com/vpc/latest/ipam/what-it-is-ipam.html)
- [Terraform aws_vpc_ipam](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_ipam)
