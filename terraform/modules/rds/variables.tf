# ============================================================
# VARIAVEIS DE ENTRADA - modulo rds
# ============================================================

variable "name" {
  description = "Prefixo dos nomes. Vira togglemaster-auth, togglemaster-flag, etc."
  type        = string
}

variable "vpc_id" {
  description = "VPC onde o security group do banco e criado."
  type        = string
}

variable "subnet_ids" {
  description = "Subnets PRIVADAS do db subnet group. O RDS exige pelo menos duas zonas."
  type        = list(string)
}

variable "allowed_security_group_id" {
  description = <<-EOT
    Security group autorizado a abrir conexao na porta 5432. Recebe o SG
    do cluster EKS, e nao um CIDR: assim so os nos do cluster alcancam o
    banco, mesmo que apareca outro recurso na mesma VPC (S-06).
  EOT
  type        = string
}

variable "databases" {
  description = <<-EOT
    Mapa <sufixo do identificador> = <nome do banco>. Apenas DOIS
    bancos: a conta recusa a terceira instancia RDS (F-023) e o
    targeting_db roda em pod (D-015).
  EOT
  type        = map(string)
}

variable "instance_class" {
  description = "Classe da instancia. db.t3.micro e a menor elegivel ao Free Tier."
  type        = string
}

variable "allocated_storage" {
  description = "Disco inicial em GB. 20 e o minimo aceito pelo RDS."
  type        = number
}

variable "max_allocated_storage" {
  description = "Teto do crescimento automatico de disco, em GB."
  type        = number
  default     = 40
}

variable "backup_retention_period" {
  description = "Dias de retencao de backup. 1 mantem o recurso ligado sem custo relevante; 0 desligaria."
  type        = number
  default     = 1
}
