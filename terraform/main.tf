# 1. Bucket S3 de Destino (Landing Zone de Dados)
resource "aws_s3_bucket" "landing_bucket" {
  bucket = "corp-datatransfer-${var.project_name}-${var.environment}-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket_public_access_block" "block_public" {
  bucket                  = aws_s3_bucket.landing_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.landing_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.landing_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.transfer_key.arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true # FinOps: reduz em até 99% chamadas de API ao KMS
  }
}

# Força transporte apenas via HTTPS (TLS)
resource "aws_s3_bucket_policy" "enforce_tls" {
  bucket = aws_s3_bucket.landing_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.landing_bucket.arn,
          "${aws_s3_bucket.landing_bucket.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

# 2. Log Group para Auditoria das Transferências
resource "aws_cloudwatch_log_group" "datasync_logs" {
  name              = "/aws/datasync/${var.project_name}-${var.environment}"
  retention_in_days = 90
  kms_key_id        = aws_kms_key.transfer_key.arn
}

# 3. Location de Destino S3 no DataSync
resource "aws_datasync_location_s3" "destination" {
  s3_bucket_arn = aws_s3_bucket.landing_bucket.arn
  subdirectory  = var.destination_prefix

  s3_config {
    bucket_access_role_arn = aws_iam_role.datasync_s3_role.arn
  }
}

# 4. Task de Transferência Gerenciada com Guardrails
resource "aws_datasync_task" "corporate_transfer" {
  name                     = "task-transfer-${var.project_name}-${var.environment}"
  source_location_arn      = var.source_location_arn
  destination_location_arn = aws_datasync_location_s3.destination.arn
  cloudwatch_log_group_arn = aws_cloudwatch_log_group.datasync_logs.arn

  options {
    bytes_per_second       = var.bandwidth_limit_bps
    verify_mode            = "ONLY_FILES_TRANSFERRED"
    overwrite_mode         = "ALWAYS"
    preserve_deleted_files = "PRESERVE"
    log_level              = "TRANSFER"
    transfer_mode          = "CHANGED"
  }
}
