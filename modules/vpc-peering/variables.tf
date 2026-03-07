variable "name" {
  description = "Name tag for the peering connection"
  type        = string
}

variable "requester_vpc_id" {
  description = "VPC ID of the requester side"
  type        = string
}

variable "accepter_vpc_id" {
  description = "VPC ID of the accepter side"
  type        = string
}

variable "accepter_account_id" {
  description = "AWS account ID of the accepter VPC owner (for cross-account peering)"
  type        = string
  default     = null
}

variable "accepter_region" {
  description = "AWS region of the accepter VPC (for cross-region peering)"
  type        = string
  default     = null
}

variable "auto_accept" {
  description = "Auto-accept the peering connection (only works for same-account, same-region)"
  type        = bool
  default     = false
}

variable "allow_remote_vpc_dns_resolution" {
  description = "Allow DNS resolution of hostnames in the peer VPC"
  type        = bool
  default     = true
}

variable "requester_vpc_cidr" {
  description = "CIDR block of the requester VPC for route creation"
  type        = string
}

variable "accepter_vpc_cidr" {
  description = "CIDR block of the accepter VPC for route creation"
  type        = string
}

variable "requester_route_table_ids" {
  description = "List of route table IDs in the requester VPC to add routes"
  type        = list(string)
  default     = []
}

variable "accepter_route_table_ids" {
  description = "List of route table IDs in the accepter VPC to add routes"
  type        = list(string)
  default     = []
}

variable "create_accepter_routes" {
  description = "Whether to create routes on the accepter side"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Map of tags to apply to peering resources"
  type        = map(string)
  default     = {}
}
