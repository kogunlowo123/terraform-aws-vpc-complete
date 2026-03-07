output "peering_connection_id" {
  description = "The ID of the VPC peering connection"
  value       = aws_vpc_peering_connection.this.id
}

output "peering_connection_status" {
  description = "The status of the VPC peering connection"
  value       = aws_vpc_peering_connection.this.accept_status
}
