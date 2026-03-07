# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-01-01

### Added

- Complete VPC resource with IPv4 and IPv6 dual-stack support
- Five subnet tiers: public, private, database, intra, and elasticache
- Multi-AZ and single NAT Gateway deployment options
- VPC Flow Logs to CloudWatch Logs or S3 with KMS encryption
- S3 and DynamoDB Gateway VPC Endpoints
- Interface VPC Endpoints with dedicated security group
- Custom DHCP Options Set support
- VPN Gateway with configurable ASN
- Default security group lockdown
- Default network ACL management
- DB subnet group and ElastiCache subnet group creation
- IPAM sub-module for centralized IP management
- VPC Peering sub-module with cross-account and cross-region support
- Standalone Flow Logs sub-module
- Basic, advanced, complete, and IPv6 examples
- Comprehensive documentation and architecture diagrams
