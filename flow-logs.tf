################################################################################
# VPC Flow Logs
################################################################################

resource "aws_flow_log" "this" {
  count = var.enable_flow_logs ? 1 : 0

  vpc_id                   = aws_vpc.this.id
  traffic_type             = "ALL"
  max_aggregation_interval = var.flow_log_max_aggregation_interval

  log_destination_type = var.flow_log_destination_type
  log_destination      = var.flow_log_destination_type == "cloud-watch-logs" ? aws_cloudwatch_log_group.flow_logs[0].arn : aws_s3_bucket.flow_logs[0].arn
  iam_role_arn         = var.flow_log_destination_type == "cloud-watch-logs" ? aws_iam_role.flow_logs[0].arn : null

  log_format = "$${version} $${account-id} $${interface-id} $${srcaddr} $${dstaddr} $${srcport} $${dstport} $${protocol} $${packets} $${bytes} $${start} $${end} $${action} $${log-status} $${vpc-id} $${subnet-id} $${az-id} $${sublocation-type} $${sublocation-id} $${pkt-srcaddr} $${pkt-dstaddr} $${region} $${pkt-src-aws-service} $${pkt-dst-aws-service} $${flow-direction} $${traffic-path}"

  tags = merge(local.common_tags, {
    Name = "${var.name}-flow-logs"
  })
}

################################################################################
# CloudWatch Log Group for Flow Logs
################################################################################

resource "aws_cloudwatch_log_group" "flow_logs" {
  count = var.enable_flow_logs && var.flow_log_destination_type == "cloud-watch-logs" ? 1 : 0

  name              = "/aws/vpc/flow-logs/${var.name}"
  retention_in_days = var.flow_log_retention_days
  kms_key_id        = aws_kms_key.flow_logs[0].arn

  tags = local.common_tags
}

################################################################################
# KMS Key for Flow Log Encryption
################################################################################

resource "aws_kms_key" "flow_logs" {
  count = var.enable_flow_logs && var.flow_log_destination_type == "cloud-watch-logs" ? 1 : 0

  description             = "KMS key for VPC flow log encryption - ${var.name}"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableRootAccountFullAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowCloudWatchLogsEncryption"
        Effect = "Allow"
        Principal = {
          Service = "logs.${data.aws_region.current.name}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt*",
          "kms:Decrypt*",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:Describe*"
        ]
        Resource = "*"
        Condition = {
          ArnLike = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/vpc/flow-logs/${var.name}"
          }
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${var.name}-flow-logs-kms"
  })
}

resource "aws_kms_alias" "flow_logs" {
  count = var.enable_flow_logs && var.flow_log_destination_type == "cloud-watch-logs" ? 1 : 0

  name          = "alias/${var.name}-flow-logs"
  target_key_id = aws_kms_key.flow_logs[0].key_id
}

################################################################################
# S3 Bucket for Flow Logs
################################################################################

resource "aws_s3_bucket" "flow_logs" {
  count = var.enable_flow_logs && var.flow_log_destination_type == "s3" ? 1 : 0

  bucket_prefix = "${var.name}-flow-logs-"
  force_destroy = false

  tags = merge(local.common_tags, {
    Name = "${var.name}-flow-logs"
  })
}

resource "aws_s3_bucket_versioning" "flow_logs" {
  count = var.enable_flow_logs && var.flow_log_destination_type == "s3" ? 1 : 0

  bucket = aws_s3_bucket.flow_logs[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "flow_logs" {
  count = var.enable_flow_logs && var.flow_log_destination_type == "s3" ? 1 : 0

  bucket = aws_s3_bucket.flow_logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "flow_logs" {
  count = var.enable_flow_logs && var.flow_log_destination_type == "s3" ? 1 : 0

  bucket = aws_s3_bucket.flow_logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "flow_logs" {
  count = var.enable_flow_logs && var.flow_log_destination_type == "s3" ? 1 : 0

  bucket = aws_s3_bucket.flow_logs[0].id

  rule {
    id     = "flow-log-retention"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = var.flow_log_retention_days > 0 ? var.flow_log_retention_days : 365
    }
  }
}

################################################################################
# IAM Role for CloudWatch Flow Logs
################################################################################

resource "aws_iam_role" "flow_logs" {
  count = var.enable_flow_logs && var.flow_log_destination_type == "cloud-watch-logs" ? 1 : 0

  name_prefix = "${var.name}-flow-logs-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowFlowLogsAssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "flow_logs" {
  count = var.enable_flow_logs && var.flow_log_destination_type == "cloud-watch-logs" ? 1 : 0

  name_prefix = "${var.name}-flow-logs-"
  role        = aws_iam_role.flow_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "${aws_cloudwatch_log_group.flow_logs[0].arn}:*"
      }
    ]
  })
}
