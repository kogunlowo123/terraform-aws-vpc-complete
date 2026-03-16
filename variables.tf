variable "name" {
  description = "Name prefix for all resources created by this module."
  type        = string

  validation {
    condition     = length(var.name) > 0 && length(var.name) <= 64
    error_message = "Name must be between 1 and 64 characters."
  }
}

variable "cidr_block" {
  description = "Primary IPv4 CIDR block for the VPC."
  type        = string

  validation {
    condition     = can(cidrhost(var.cidr_block, 0))
    error_message = "Must be a valid IPv4 CIDR block."
  }
}

variable "secondary_cidr_blocks" {
  description = "List of secondary IPv4 CIDR blocks to associate with the VPC."
  type        = list(string)
  default     = []
}

variable "enable_ipv6" {
  description = "Enable IPv6 support with Amazon-provided IPv6 CIDR block."
  type        = bool
  default     = false
}

variable "instance_tenancy" {
  description = "Tenancy option for instances launched into the VPC (default or dedicated)."
  type        = string
  default     = "default"

  validation {
    condition     = contains(["default", "dedicated"], var.instance_tenancy)
    error_message = "Instance tenancy must be 'default' or 'dedicated'."
  }
}

variable "enable_dns_support" {
  description = "Enable DNS resolution support in the VPC."
  type        = bool
  default     = true
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC."
  type        = bool
  default     = true
}

variable "availability_zones" {
  description = "List of availability zones to deploy subnets into."
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) >= 1
    error_message = "At least one availability zone must be specified."
  }
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets (one per AZ)."
  type        = list(string)
  default     = []
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets (one per AZ)."
  type        = list(string)
  default     = []
}

variable "database_subnet_cidrs" {
  description = "List of CIDR blocks for database subnets (one per AZ)."
  type        = list(string)
  default     = []
}

variable "intra_subnet_cidrs" {
  description = "List of CIDR blocks for intra subnets with no internet access (one per AZ)."
  type        = list(string)
  default     = []
}

variable "elasticache_subnet_cidrs" {
  description = "List of CIDR blocks for ElastiCache subnets (one per AZ)."
  type        = list(string)
  default     = []
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnet internet access."
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway for all AZs instead of one per AZ."
  type        = bool
  default     = false
}

variable "enable_vpn_gateway" {
  description = "Create a VPN Gateway attached to the VPC."
  type        = bool
  default     = false
}

variable "vpn_gateway_asn" {
  description = "ASN for the Amazon side of the VPN Gateway."
  type        = number
  default     = 64512
}

variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs."
  type        = bool
  default     = true
}

variable "flow_log_destination_type" {
  description = "Destination type for VPC Flow Logs (cloud-watch-logs or s3)."
  type        = string
  default     = "cloud-watch-logs"

  validation {
    condition     = contains(["cloud-watch-logs", "s3"], var.flow_log_destination_type)
    error_message = "Flow log destination must be 'cloud-watch-logs' or 's3'."
  }
}

variable "flow_log_retention_days" {
  description = "Number of days to retain VPC Flow Logs in CloudWatch."
  type        = number
  default     = 30
}

variable "flow_log_max_aggregation_interval" {
  description = "Maximum interval in seconds for flow log aggregation (60 or 600)."
  type        = number
  default     = 600

  validation {
    condition     = contains([60, 600], var.flow_log_max_aggregation_interval)
    error_message = "Aggregation interval must be 60 or 600 seconds."
  }
}

variable "enable_s3_endpoint" {
  description = "Create a Gateway VPC Endpoint for S3."
  type        = bool
  default     = true
}

variable "enable_dynamodb_endpoint" {
  description = "Create a Gateway VPC Endpoint for DynamoDB."
  type        = bool
  default     = false
}

variable "interface_endpoints" {
  description = "Map of interface VPC endpoints to create."
  type = map(object({
    service_name        = string
    private_dns_enabled = optional(bool, true)
    security_group_ids  = optional(list(string), [])
    subnet_ids          = optional(list(string), [])
  }))
  default = {}
}

variable "enable_dhcp_options" {
  description = "Create custom DHCP options set for the VPC."
  type        = bool
  default     = false
}

variable "dhcp_domain_name" {
  description = "DNS domain name for the DHCP options set."
  type        = string
  default     = ""
}

variable "dhcp_domain_name_servers" {
  description = "List of DNS server addresses for the DHCP options set."
  type        = list(string)
  default     = ["AmazonProvidedDNS"]
}

variable "dhcp_ntp_servers" {
  description = "List of NTP server addresses for the DHCP options set."
  type        = list(string)
  default     = []
}

variable "manage_default_security_group" {
  description = "Manage the default security group to restrict all traffic."
  type        = bool
  default     = true
}

variable "manage_default_network_acl" {
  description = "Manage the default network ACL."
  type        = bool
  default     = true
}

variable "public_subnet_tags" {
  description = "Additional tags for public subnets."
  type        = map(string)
  default     = {}
}

variable "private_subnet_tags" {
  description = "Additional tags for private subnets."
  type        = map(string)
  default     = {}
}

variable "database_subnet_tags" {
  description = "Additional tags for database subnets."
  type        = map(string)
  default     = {}
}

variable "create_database_subnet_group" {
  description = "Create a DB subnet group from database subnets."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}
