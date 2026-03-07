# IPv6 Dual-Stack VPC Example

VPC with both IPv4 and IPv6 CIDR blocks. Public subnets receive auto-assigned IPv6 addresses, and private subnets use an Egress-Only Internet Gateway for IPv6 outbound traffic.

## Usage

```bash
terraform init
terraform plan
terraform apply
```
