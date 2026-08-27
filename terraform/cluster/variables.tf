# ============================================================
# VARIAVEIS DE ENTRADA - camada cluster
# ============================================================
# Repetem alguns valores da base de proposito: sao dois root modules
# independentes, e um nao le as variaveis do outro. Só o ESTADO e
# compartilhado, via remote state em data.tf.
# ============================================================

variable "aws_region" {
  description = "Regiao AWS. Precisa ser a mesma da camada base (F-012)."
  type        = string
  default     = "us-east-2"
}

variable "project_name" {
  description = "Prefixo dos nomes de recurso. Mesmo valor da base."
  type        = string
  default     = "togglemaster"
}

variable "default_tags" {
  description = "Tags aplicadas a todo recurso (D-009). Em minusculas, igual a base."
  type        = map(string)
  default = {
    project = "fiap"
    phase   = "3"
  }
}

# ------------------------------------------------------------
# Cluster EKS
# ------------------------------------------------------------

variable "kubernetes_version" {
  description = "Versao do Kubernetes no EKS."
  type        = string
  default     = "1.31"
}

variable "node_instance_type" {
  description = <<-EOT
    Tipo de instancia dos nos. `c7i-flex.large` (2 vCPU / 4 GB) e nao
    `t3.medium` por bloqueio da conta: o plano gratuito recusa a t3.medium
    com "The specified instance type is not eligible for Free Tier"
    (F-023, D-016). A t3.micro e inviavel: ~4 pods por no e 1 GB de RAM.
    A familia t4g e ARM e as imagens do projeto sao x86.
  EOT
  type        = string
  default     = "c7i-flex.large"
}

variable "node_group_min_size" {
  description = "Minimo de nos."
  type        = number
  default     = 1
}

variable "node_group_desired_size" {
  description = <<-EOT
    Nos desejados. 2 e nao 1 porque com um unico no o HPA do
    evaluation-service nao teria onde colocar o pod extra: ele ficaria
    Pending e a demonstracao de escalabilidade falharia no video.
  EOT
  type        = number
  default     = 2
}

variable "node_group_max_size" {
  description = "Maximo de nos, para o auto scaling do node group."
  type        = number
  default     = 4
}

# ------------------------------------------------------------
# Bancos de dados
# ------------------------------------------------------------

variable "rds_instance_class" {
  description = "Classe das instancias RDS. db.t3.micro e a menor elegivel ao Free Tier."
  type        = string
  default     = "db.t3.micro"
}

variable "rds_allocated_storage" {
  description = "Armazenamento por instancia RDS, em GB. 20 e o minimo."
  type        = number
  default     = 20
}

variable "rds_databases" {
  description = <<-EOT
    Bancos que ficam no RDS. Apenas DOIS, nao tres: o plano gratuito da
    conta recusa a terceira instancia com "maximum number of instances
    available with free plan accounts" (F-023). O terceiro banco,
    targeting_db, roda como StatefulSet no cluster (D-015), com aprovacao
    do professor. Os manifestos estao em gitops/base/postgres-targeting/.
  EOT
  type        = map(string)
  default = {
    auth = "auth_db"
    flag = "flags_db"
  }
}

# ------------------------------------------------------------
# Cache
# ------------------------------------------------------------

variable "elasticache_node_type" {
  description = "Tipo do no do ElastiCache. cache.t3.micro e o menor disponivel."
  type        = string
  default     = "cache.t3.micro"
}
