# HLD / LLD — Self-Service Corporate Data Transfer Blueprint (AWS)

## 1. High-Level Design (HLD)
### 1.1 Objetivo e Escopo
Fornecer uma capacidade corporativa padronizada e auditável para transferência de grandes volumes de dados entre ambientes **On-Premises (NFS/SMB)** e **AWS S3**, eliminando exposição à internet pública e aplicando controles nativos de **Zero Trust** e **FinOps**.

### 1.2 Pilares Arquiteturais (Well-Architected & Zero Trust)
* **Segurança (Zero Trust):** Comunicação estritamente privada via **AWS PrivateLink (VPC Interface Endpoints)**; criptografia obrigatória em repouso com chave gerenciada pelo cliente (**AWS KMS CMK** com rotação anual) e bloqueio total de acesso público no S3.
* **Otimização de Custos (FinOps):** Políticas automáticas de **S3 Lifecycle** (transição para *Standard-IA* após 30 dias, *Glacier Instant Retrieval* após 90 dias e expiração configurável) e controle de banda no DataSync para não saturar links híbridos (Direct Connect/VPN).
* **Confiabilidade & Excelência Operacional:** Verificação automática de integridade pós-transferência, logs centralizados no **Amazon CloudWatch Logs** e retenção auditável.

---

## 2. Low-Level Design (LLD)
### 2.1 Fluxo de Dados
1. **Origem (On-Premises):** O *DataSync Agent* lê os arquivos via NFS/SMB e estabelece túnel TLS 1.2+ autenticado com os *VPC Interface Endpoints* (`com.amazonaws.<region>.datasync`).
2. **Controle & Orquestração:** A *DataSync Task* executa a cópia incremental aplicando filtros de inclusão/exclusão, preservação de metadados POSIX e limite de banda (`bandwidth_limit_bps`).
3. **Destino (AWS S3):** Os objetos são gravados no bucket corporativo com criptografia `aws:kms`, versionamento habilitado e auditados via CloudWatch Logs.

### 2.2 Parâmetros de Governança (Self-Service Inputs)
| Parâmetro | Regra de Governança | Padrão Corporativo |
| :--- | :--- | :--- |
| `enable_kms_rotation` | Obrigatório | `true` (Rotação automática a cada 365 dias) |
| `transition_to_ia_days` | FinOps Guardrail | `30` dias |
| `transition_to_glacier_days` | FinOps Guardrail | `90` dias |
| `verify_mode` | Integridade de Dados | `ONLY_FILES_TRANSFERRED` |
| `log_level` | Auditoria & Observabilidade | `TRANSFER` (Registra cada arquivo movido) |
