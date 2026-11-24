# ADR-001: Adoção do AWS DataSync Gerenciado vs. Scripts Customizados em EC2 para Transferência Corporativa de Dados

* **Status:** Aprovado
* **Contexto:** Necessidade de padronizar a ingestão e movimentação de grandes volumes de dados (on-premises para nuvem e inter-buckets) em ambiente regulado, substituindo rotinas artesanais (`aws s3 sync` em VMs/EC2) sem rastreabilidade, controle de banda ou validação de integridade.
* **Decisão:** Adotar o **AWS DataSync** empacotado em um módulo Terraform *Self-Service* como padrão corporativo "de prateleira" para transferência gerenciada de arquivos e objetos.
* **Alternativas Avaliadas:**
  * *Scripts CLI/Python em EC2:* Rejeitado por exigir manutenção de SO, gestão manual de paralelismo, ausência nativa de checksum ponta a ponta e alto custo operacional.
  * *AWS Transfer Family (SFTP):* Mantido apenas para parceiros externos legados que exigem protocolo SFTP; preterido para movimentação interna de alto throughput devido ao custo por hora de endpoint.
* **Consequências:**
  * **Positivas:** Validação automática de integridade (checksum), criptografia em trânsito (TLS 1.2+) e em repouso (KMS CMK), controle granular de throttling de rede e modelo de custo estritamente por GB transferido.
  * **Negativas / Trade-offs:** Necessidade de provisionar DataSync Agents (VMware/Hyper-V/KVM) e VPC Endpoints (Interface) no ambiente híbrido para evitar tráfego pela internet pública.
