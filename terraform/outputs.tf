output "landing_bucket_name" {
  description = "Nome do bucket S3 corporativo provisionado"
  value       = aws_s3_bucket.landing_bucket.id
}

output "datasync_task_arn" {
  description = "ARN da Task do AWS DataSync pronta para execução/agendamento"
  value       = aws_datasync_task.corporate_transfer.arn
}

output "kms_key_arn" {
  description = "ARN da chave KMS CMK dedicada ao fluxo"
  value       = aws_kms_key.transfer_key.arn
}
