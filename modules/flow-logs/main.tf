################################################################################
# Standalone Flow Log Configuration
################################################################################

resource "aws_flow_log" "this" {
  vpc_id          = var.vpc_id
  subnet_id       = var.subnet_id
  eni_id          = var.eni_id
  traffic_type    = var.traffic_type

  log_destination_type     = var.destination_type
  log_destination          = var.log_destination_arn
  iam_role_arn             = var.iam_role_arn
  max_aggregation_interval = var.max_aggregation_interval

  log_format = var.log_format

  dynamic "destination_options" {
    for_each = var.destination_type == "s3" ? [1] : []

    content {
      file_format                = var.s3_file_format
      hive_compatible_partitions = var.s3_hive_compatible_partitions
      per_hour_partition         = var.s3_per_hour_partition
    }
  }

  tags = merge(var.tags, {
    Name = var.name
  })
}
