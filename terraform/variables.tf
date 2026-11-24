variable "aws_region" {
  description = "Região AWS onde a capacidade de transferência será provisionada"
  type        = string
  default     = "sa-east-1"
}

variable "project_name" {
  description = "Identificador único do fluxo de transferência (usado na nomenclatura dos recursos)"
  type        = string
}

variable "environment" {
  description = "Ambiente de implantação (dev, uat, prd)"
  type        = string
  validation {
    condition     = contains(["dev", "uat", "prd"], var.environment)
    error_message = "O ambiente deve ser dev, uat ou prd."
  }
}

variable "cost_center" {
  description = "Centro de custo / Squad consumidora para rastreabilidade FinOps"
  type        = string
}

variable "source_location_arn" {
  description = "ARN da Location de origem no AWS DataSync (ex: NFS/SMB On-Premises ou S3)"
  type        = string
}

variable "destination_prefix" {
  description = "Prefixo/pasta dentro do bucket S3 de destino"
  type        = string
  default     = "/landing"
}

variable "bandwidth_limit_bps" {
  description = "Limite máximo de banda em Bytes/s para proteger links híbridos (-1 para ilimitado)"
  type        = number
  default     = 52428800 # 50 MB/s (Guardrail padrão de rede)
}

variable "transition_to_ia_days" {
  description = "Dias para mover objetos para S3 Standard-IA (FinOps)"
  type        = number
  default     = 30
}

variable "transition_to_glacier_days" {
  description = "Dias para mover objetos para S3 Glacier Instant Retrieval (FinOps)"
  type        = number
  default     = 90
}

variable "expiration_days" {
  description = "Dias para expiração definitiva dos dados de landing (0 para não expirar)"
  type        = number
  default     = 365
}
