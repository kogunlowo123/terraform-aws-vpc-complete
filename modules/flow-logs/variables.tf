variable "name" {
  description = "Name tag for the flow log"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID to attach the flow log to (mutually exclusive with subnet_id and eni_id)"
  type        = string
  default     = null
}

variable "subnet_id" {
  description = "Subnet ID to attach the flow log to"
  type        = string
  default     = null
}

variable "eni_id" {
  description = "ENI ID to attach the flow log to"
  type        = string
  default     = null
}

variable "traffic_type" {
  description = "Type of traffic to capture (ACCEPT, REJECT, or ALL)"
  type        = string
  default     = "ALL"

  validation {
    condition     = contains(["ACCEPT", "REJECT", "ALL"], var.traffic_type)
    error_message = "Traffic type must be ACCEPT, REJECT, or ALL."
  }
}

variable "destination_type" {
  description = "Destination type (cloud-watch-logs or s3)"
  type        = string
  default     = "cloud-watch-logs"
}

variable "log_destination_arn" {
  description = "ARN of the log destination (CloudWatch Log Group or S3 bucket)"
  type        = string
}

variable "iam_role_arn" {
  description = "IAM role ARN for publishing to CloudWatch Logs"
  type        = string
  default     = null
}

variable "max_aggregation_interval" {
  description = "Maximum aggregation interval in seconds (60 or 600)"
  type        = number
  default     = 600
}

variable "log_format" {
  description = "Custom log format string"
  type        = string
  default     = null
}

variable "s3_file_format" {
  description = "File format for S3 destination (plain-text or parquet)"
  type        = string
  default     = "parquet"
}

variable "s3_hive_compatible_partitions" {
  description = "Use Hive-compatible S3 prefixes for partitioning"
  type        = bool
  default     = true
}

variable "s3_per_hour_partition" {
  description = "Partition flow logs per hour instead of per day"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Map of tags to apply to the flow log"
  type        = map(string)
  default     = {}
}
