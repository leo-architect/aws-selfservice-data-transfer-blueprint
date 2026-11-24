# Guardrails de Ciclo de Vida FinOps para redução automática de custos de armazenamento
resource "aws_s3_bucket_lifecycle_configuration" "finops_lifecycle" {
  bucket = aws_s3_bucket.landing_bucket.id

  rule {
    id     = "corporate-finops-tiering"
    status = "Enabled"

    transition {
      days          = var.transition_to_ia_days
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = var.transition_to_glacier_days
      storage_class = "GLACIER_IR"
    }

    dynamic "expiration" {
      for_each = var.expiration_days > 0 ? [1] : []
      content {
        days = var.expiration_days
      }
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}
