data "aws_caller_identity" "current" {}

# 1. Chave KMS dedicada com rotação automática (Zero Trust / Compliance)
resource "aws_kms_key" "transfer_key" {
  description             = "KMS CMK para criptografia de dados em trânsito/repouso - ${var.project_name}-${var.environment}"
  deletion_window_in_days = 14
  enable_key_rotation     = true
}

resource "aws_kms_alias" "transfer_key_alias" {
  name          = "alias/datatransfer-${var.project_name}-${var.environment}"
  target_key_id = aws_kms_key.transfer_key.key_id
}

# 2. IAM Role de Privilégio Mínimo para o AWS DataSync gravar no S3
resource "aws_iam_role" "datasync_s3_role" {
  name = "role-datasync-${var.project_name}-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "datasync.amazonaws.com"
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
}

resource "aws_iam_role_policy" "datasync_s3_policy" {
  name = "policy-datasync-least-privilege-${var.project_name}"
  role = aws_iam_role.datasync_s3_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowBucketInspection"
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads"
        ]
        Resource = aws_s3_bucket.landing_bucket.arn
      },
      {
        Sid    = "AllowObjectReadWrite"
        Effect = "Allow"
        Action = [
          "s3:AbortMultipartUpload",
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:GetObjectTagging",
          "s3:GetObjectVersion",
          "s3:GetObjectVersionTagging",
          "s3:ListMultipartUploadParts",
          "s3:PutObject",
          "s3:PutObjectTagging"
        ]
        Resource = "${aws_s3_bucket.landing_bucket.arn}/*"
      },
      {
        Sid    = "AllowKMSUsage"
        Effect = "Allow"
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = aws_kms_key.transfer_key.arn
      }
    ]
  })
}
