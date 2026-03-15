# Industry Adaptation Guide

## Overview
The `terraform-aws-vpc-complete` module creates a full-featured AWS VPC with public, private, database, intra, and ElastiCache subnets, NAT gateways, VPN gateway, VPC flow logs, gateway and interface endpoints, DHCP options, and default security group lockdown. Its layered network architecture makes it the foundation for any industry's cloud infrastructure.

## Healthcare
### Compliance Requirements
- HIPAA, HITRUST, HL7 FHIR
### Configuration Changes
- Use `database_subnet_cidrs` and `intra_subnet_cidrs` to isolate PHI-hosting databases in subnets with no internet route.
- Set `enable_flow_logs = true` with `flow_log_retention_days = 365` for HIPAA audit trail requirements.
- Set `flow_log_max_aggregation_interval = 60` for near-real-time traffic monitoring.
- Set `instance_tenancy = "dedicated"` if regulatory counsel requires physical isolation.
- Enable `interface_endpoints` for services like STS, ECR, and KMS to keep PHI traffic off the public internet.
- Set `manage_default_security_group = true` to lock down the default SG (deny all).
- Use `enable_vpn_gateway = true` to establish encrypted connectivity to on-premises clinical systems.
### Example Use Case
A health IT vendor deploys its EHR platform in private subnets with database subnets for RDS, intra subnets for internal APIs, VPC endpoints for AWS services, and a VPN gateway connecting to hospital data centers.

## Finance
### Compliance Requirements
- SOX, PCI-DSS, SOC 2
### Configuration Changes
- Deploy cardholder data environment (CDE) resources into `database_subnet_cidrs` and `intra_subnet_cidrs` with no internet access (PCI-DSS Requirement 1).
- Set `enable_flow_logs = true` with `flow_log_destination_type = "s3"` for long-term archival and `flow_log_retention_days = 365` for SOX.
- Set `single_nat_gateway = false` to ensure per-AZ NAT gateways for high availability of trading and payment systems.
- Configure `interface_endpoints` for `com.amazonaws.<region>.sts`, `com.amazonaws.<region>.kms`, and `com.amazonaws.<region>.secretsmanager`.
- Use `manage_default_network_acl = true` and restrict ACLs to known ports and CIDR ranges.
- Use `public_subnet_tags` and `private_subnet_tags` to apply PCI scope tags (e.g., `pci-scope: in-scope`).
### Example Use Case
A bank segments its VPC into public subnets for load balancers, private subnets for application servers, database subnets for its core banking database, and intra subnets for internal settlement services, with per-AZ NAT gateways and VPC flow logs shipped to S3.

## Government
### Compliance Requirements
- FedRAMP, CMMC, NIST 800-53
### Configuration Changes
- Deploy in GovCloud regions with `availability_zones` set to GovCloud AZs.
- Set `enable_flow_logs = true` with `flow_log_max_aggregation_interval = 60` for continuous monitoring (NIST SI-4).
- Set `flow_log_retention_days = 365` (NIST AU-11).
- Enable `enable_s3_endpoint = true` and `enable_dynamodb_endpoint = true` to keep traffic within the AWS backbone (NIST SC-7).
- Use `intra_subnet_cidrs` for sensitive workloads requiring zero internet egress.
- Configure `enable_dhcp_options = true` with `dhcp_domain_name_servers` pointing to internal DNS.
- Set `manage_default_security_group = true` and `manage_default_network_acl = true` for defense-in-depth.
### Example Use Case
A defense contractor deploys its CMMC Level 3 environment in GovCloud with intra subnets for CUI processing, VPN gateway for SIPR connectivity, and flow logs aggregated every 60 seconds for real-time SIEM ingestion.

## Retail / E-Commerce
### Compliance Requirements
- PCI-DSS, CCPA/GDPR
### Configuration Changes
- Use `public_subnet_cidrs` for internet-facing ALBs/NLBs and `private_subnet_cidrs` for application servers.
- Deploy payment services in `intra_subnet_cidrs` with no internet route.
- Set `single_nat_gateway = false` for HA across AZs during peak traffic.
- Enable `elasticache_subnet_cidrs` for session and product catalog caching with ElastiCache.
- Set `enable_flow_logs = true` for PCI-DSS network monitoring requirements.
- Use `create_database_subnet_group = true` for RDS deployments housing customer data.
### Example Use Case
An e-commerce company uses the VPC with public subnets for CDN origins, private subnets for microservices, database subnets for product and order databases, ElastiCache subnets for Redis-based session stores, and intra subnets for the payment gateway backend.

## Education
### Compliance Requirements
- FERPA, COPPA
### Configuration Changes
- Use `private_subnet_cidrs` for student information systems and `database_subnet_cidrs` for student records databases.
- Set `enable_flow_logs = true` and `flow_log_retention_days = 365` for FERPA audit requirements.
- Set `manage_default_security_group = true` to prevent accidental data exposure.
- Use `enable_vpn_gateway = true` for secure connectivity to campus networks.
- Enable `enable_s3_endpoint = true` for private access to S3-hosted educational content.
### Example Use Case
A university IT department creates a VPC with private subnets for the student portal, database subnets for the registrar's PostgreSQL database, and a VPN gateway connecting to the campus network for single sign-on integration.

## SaaS / Multi-Tenant
### Compliance Requirements
- SOC 2, ISO 27001
### Configuration Changes
- Use `secondary_cidr_blocks` to expand address space as the tenant count grows.
- Configure per-tenant or per-tier subnets using `private_subnet_cidrs` with appropriate sizing.
- Set `single_nat_gateway = false` for production environments requiring high availability.
- Enable `interface_endpoints` to reduce data transfer costs and improve latency for AWS API calls.
- Set `enable_flow_logs = true` with `flow_log_destination_type = "s3"` for cost-effective long-term retention.
- Use `enable_ipv6 = true` if supporting IPv6-native tenant workloads.
- Use `tags` with tenant-tier labels for cost allocation and governance.
### Example Use Case
A SaaS platform allocates separate private subnets per availability zone, uses secondary CIDR blocks for tenant expansion, routes all traffic through per-AZ NAT gateways, and enables VPC flow logs to S3 for SOC 2 audit evidence.

## Cross-Industry Best Practices
- Use environment-based configuration by parameterizing `name`, `cidr_block`, and subnet CIDRs per environment.
- Always enable encryption in transit by using VPC endpoints (`enable_s3_endpoint`, `interface_endpoints`) to avoid public internet traversal.
- Enable audit logging via `enable_flow_logs = true` with appropriate retention.
- Enforce least-privilege access by setting `manage_default_security_group = true` and restricting NACLs via `manage_default_network_acl = true`.
- Implement network segmentation using the five subnet tiers: public, private, database, intra, and ElastiCache.
- Plan for disaster recovery by deploying across multiple `availability_zones` with per-AZ NAT gateways (`single_nat_gateway = false`).
