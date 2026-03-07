# Advanced VPC Example

3-AZ high-availability VPC with five subnet tiers, multi-AZ NAT Gateways, VPC Gateway Endpoints, custom DHCP options, and Kubernetes-ready subnet tags.

## Features

- Public, private, database, ElastiCache, and intra subnet tiers
- One NAT Gateway per AZ for fault isolation
- S3 and DynamoDB Gateway Endpoints
- Custom DHCP options with internal domain
- EKS-compatible subnet tagging
- VPC Flow Logs with 60-second aggregation

## Usage

```bash
terraform init
terraform plan
terraform apply
```
