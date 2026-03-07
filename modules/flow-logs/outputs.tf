output "flow_log_id" {
  description = "The ID of the flow log"
  value       = aws_flow_log.this.id
}

output "flow_log_arn" {
  description = "The ARN of the flow log"
  value       = aws_flow_log.this.arn
}
