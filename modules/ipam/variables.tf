variable "name" {
  description = "Name for the IPAM instance"
  type        = string
}

variable "description" {
  description = "Description for the IPAM instance"
  type        = string
  default     = "VPC IPAM for centralized IP address management"
}

variable "operating_regions" {
  description = "List of AWS regions where IPAM will manage IP addresses"
  type        = list(string)
}

variable "pool_locale" {
  description = "Locale (AWS region) for the IPAM pool"
  type        = string
}

variable "pool_cidrs" {
  description = "List of CIDR blocks to provision in the IPAM pool"
  type        = list(string)
}

variable "default_netmask_length" {
  description = "Default netmask length for allocations from this pool"
  type        = number
  default     = 24
}

variable "min_netmask_length" {
  description = "Minimum netmask length for allocations from this pool"
  type        = number
  default     = 16
}

variable "max_netmask_length" {
  description = "Maximum netmask length for allocations from this pool"
  type        = number
  default     = 28
}

variable "tags" {
  description = "Map of tags to apply to IPAM resources"
  type        = map(string)
  default     = {}
}
