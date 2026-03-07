output "ipam_id" {
  description = "The ID of the IPAM instance"
  value       = aws_vpc_ipam.this.id
}

output "ipam_arn" {
  description = "The ARN of the IPAM instance"
  value       = aws_vpc_ipam.this.arn
}

output "pool_id" {
  description = "The ID of the IPAM pool"
  value       = aws_vpc_ipam_pool.this.id
}

output "pool_arn" {
  description = "The ARN of the IPAM pool"
  value       = aws_vpc_ipam_pool.this.arn
}

output "private_default_scope_id" {
  description = "The ID of the IPAM private default scope"
  value       = aws_vpc_ipam.this.private_default_scope_id
}
