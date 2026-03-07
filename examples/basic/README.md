# Basic VPC Example

This example creates a simple 2-tier VPC with public and private subnets across two availability zones, a single shared NAT Gateway, and VPC Flow Logs.

## Architecture

```
                    ┌─────────────────────────────────────────────────┐
                    │                   VPC 10.0.0.0/16               │
                    │                                                 │
                    │  ┌──────────────┐    ┌──────────────┐          │
 Internet ◄────────►│  │  Public 1a   │    │  Public 1b   │          │
                    │  │  10.0.1.0/24 │    │  10.0.2.0/24 │          │
                    │  └──────┬───────┘    └──────────────┘          │
                    │         │ NAT GW                                │
                    │  ┌──────▼───────┐    ┌──────────────┐          │
                    │  │  Private 1a  │    │  Private 1b  │          │
                    │  │ 10.0.11.0/24 │    │ 10.0.12.0/24 │          │
                    │  └──────────────┘    └──────────────┘          │
                    └─────────────────────────────────────────────────┘
```

## Usage

```bash
terraform init
terraform plan
terraform apply
```
