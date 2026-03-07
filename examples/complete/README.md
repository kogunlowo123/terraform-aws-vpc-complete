# Complete Enterprise VPC Example

Full-featured enterprise VPC deployment with IPv6 dual-stack, secondary CIDR blocks, VPN Gateway, interface VPC endpoints, custom DHCP options, and all security controls enabled.

## Features

- IPv6 dual-stack with Amazon-provided CIDR
- Secondary CIDR block (100.64.0.0/16) for container networking
- Five subnet tiers across three AZs
- Multi-AZ NAT Gateways
- VPN Gateway with custom ASN
- Eight interface VPC endpoints (SSM, ECR, CloudWatch, STS, KMS)
- S3 and DynamoDB gateway endpoints
- VPC Flow Logs to S3 with 60-second aggregation and 365-day retention
- Default security group lockdown
- Custom DHCP options with NTP
- EKS-ready subnet tagging
- PCI-DSS compliance tagging

## Usage

```bash
terraform init
terraform plan
terraform apply
```

## Cost Considerations

- NAT Gateways: ~$32/month per AZ ($96/month for 3 AZs) + data processing
- VPN Gateway: ~$36/month
- Interface VPC Endpoints: ~$7.20/month per endpoint per AZ ($172.80/month for 8 endpoints x 3 AZs)
- VPC Flow Logs to S3: Depends on traffic volume
