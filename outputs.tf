################################################################################
# VPC
################################################################################

output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.this.id
}

output "vpc_arn" {
  description = "The ARN of the VPC"
  value       = aws_vpc.this.arn
}

output "vpc_cidr_block" {
  description = "The primary CIDR block of the VPC"
  value       = aws_vpc.this.cidr_block
}

output "vpc_ipv6_cidr_block" {
  description = "The IPv6 CIDR block of the VPC"
  value       = aws_vpc.this.ipv6_cidr_block
}

output "vpc_default_security_group_id" {
  description = "The ID of the default security group"
  value       = aws_vpc.this.default_security_group_id
}

output "vpc_default_route_table_id" {
  description = "The ID of the default route table"
  value       = aws_vpc.this.default_route_table_id
}

################################################################################
# Subnets
################################################################################

output "public_subnet_ids" {
  description = "List of IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "public_subnet_arns" {
  description = "List of ARNs of public subnets"
  value       = aws_subnet.public[*].arn
}

output "public_subnet_cidr_blocks" {
  description = "List of CIDR blocks of public subnets"
  value       = aws_subnet.public[*].cidr_block
}

output "private_subnet_ids" {
  description = "List of IDs of private subnets"
  value       = aws_subnet.private[*].id
}

output "private_subnet_arns" {
  description = "List of ARNs of private subnets"
  value       = aws_subnet.private[*].arn
}

output "private_subnet_cidr_blocks" {
  description = "List of CIDR blocks of private subnets"
  value       = aws_subnet.private[*].cidr_block
}

output "database_subnet_ids" {
  description = "List of IDs of database subnets"
  value       = aws_subnet.database[*].id
}

output "database_subnet_arns" {
  description = "List of ARNs of database subnets"
  value       = aws_subnet.database[*].arn
}

output "database_subnet_cidr_blocks" {
  description = "List of CIDR blocks of database subnets"
  value       = aws_subnet.database[*].cidr_block
}

output "database_subnet_group_name" {
  description = "Name of the database subnet group"
  value       = try(aws_db_subnet_group.this[0].name, null)
}

output "intra_subnet_ids" {
  description = "List of IDs of intra subnets"
  value       = aws_subnet.intra[*].id
}

output "intra_subnet_cidr_blocks" {
  description = "List of CIDR blocks of intra subnets"
  value       = aws_subnet.intra[*].cidr_block
}

output "elasticache_subnet_ids" {
  description = "List of IDs of ElastiCache subnets"
  value       = aws_subnet.elasticache[*].id
}

output "elasticache_subnet_group_name" {
  description = "Name of the ElastiCache subnet group"
  value       = try(aws_elasticache_subnet_group.this[0].name, null)
}

################################################################################
# Route Tables
################################################################################

output "public_route_table_id" {
  description = "ID of the public route table"
  value       = try(aws_route_table.public[0].id, null)
}

output "private_route_table_ids" {
  description = "List of IDs of private route tables"
  value       = aws_route_table.private[*].id
}

output "database_route_table_id" {
  description = "ID of the database route table"
  value       = try(aws_route_table.database[0].id, null)
}

################################################################################
# NAT Gateway
################################################################################

output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs"
  value       = aws_nat_gateway.this[*].id
}

output "nat_gateway_public_ips" {
  description = "List of public Elastic IPs associated with NAT Gateways"
  value       = aws_eip.nat[*].public_ip
}

################################################################################
# Internet Gateway
################################################################################

output "internet_gateway_id" {
  description = "The ID of the Internet Gateway"
  value       = try(aws_internet_gateway.this[0].id, null)
}

################################################################################
# VPN Gateway
################################################################################

output "vpn_gateway_id" {
  description = "The ID of the VPN Gateway"
  value       = try(aws_vpn_gateway.this[0].id, null)
}

################################################################################
# VPC Endpoints
################################################################################

output "s3_endpoint_id" {
  description = "The ID of the S3 VPC endpoint"
  value       = try(aws_vpc_endpoint.s3[0].id, null)
}

output "dynamodb_endpoint_id" {
  description = "The ID of the DynamoDB VPC endpoint"
  value       = try(aws_vpc_endpoint.dynamodb[0].id, null)
}

################################################################################
# Flow Logs
################################################################################

output "flow_log_id" {
  description = "The ID of the VPC Flow Log"
  value       = try(aws_flow_log.this[0].id, null)
}

output "flow_log_cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group for flow logs"
  value       = try(aws_cloudwatch_log_group.flow_logs[0].arn, null)
}
