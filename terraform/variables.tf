# ============================================================
# VARIAVEIS DE ENTRADA
# ============================================================

variable "aws_region" {
  description = "Regiao AWS onde toda a infraestrutura e criada. Mesma regiao da Fase 2 (F-012)."
  type        = string
  default     = "us-east-2"
}

variable "project_name" {
  description = <<-EOT
    Prefixo dos nomes de recurso. Mantido como "togglemaster" de proposito:
    a fila e o cache da Fase 2 ja usavam esse prefixo, e o codigo dos servicos
    le esses nomes por variavel de ambiente (F-019). Mudar aqui obriga a mudar
    tambem os manifestos em gitops/.
  EOT
  type        = string
  default     = "togglemaster"
}

variable "default_tags" {
  description = "Tags aplicadas a todo recurso criado por este Terraform (D-009)."
  type        = map(string)
  default = {
    Project = "fiap"
    Phase   = "3"
  }
}

# ------------------------------------------------------------
# Rede
# ------------------------------------------------------------

variable "vpc_cidr" {
  description = "Bloco CIDR da VPC. /16 da folga de sobra para as 4 subnets."
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = <<-EOT
    Duas AZs, no minimo. Nao e escolha estetica: o EKS exige subnets em pelo
    menos duas zonas, e o DB subnet group do RDS tambem.
  EOT
  type        = list(string)
  default     = ["us-east-2a", "us-east-2b"]
}

variable "private_subnet_cidrs" {
  description = "Subnets privadas: nos do EKS, RDS e ElastiCache. Nada aqui tem IP publico."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "public_subnet_cidrs" {
  description = "Subnets publicas: apenas o NAT Gateway. Nao ha Load Balancer no projeto (D-012)."
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "enable_nat_gateway" {
  description = <<-EOT
    O NAT Gateway custa cerca de US$ 33/mes e so e necessario quando existe algo
    rodando em subnet privada, ou seja, a partir da Etapa 2 (EKS, RDS, Redis).
    Durante a Etapa 1 mantenha false no seu terraform.tfvars para nao pagar por
    um recurso ocioso. O padrao e true para nao deixar o cluster sem saida por
    esquecimento.
  EOT
  type        = bool
  default     = true
}

# ------------------------------------------------------------
# Aplicacao
# ------------------------------------------------------------

variable "services" {
  description = "Os 5 microsservicos do ToggleMaster. Vira 1 repositorio ECR por item, no formato <servico>-service."
  type        = list(string)
  default     = ["auth", "flag", "targeting", "evaluation", "analytics"]
}

variable "dynamodb_table_name" {
  description = "Nome literal exigido pelo enunciado (F-009). Nao alterar."
  type        = string
  default     = "ToggleMasterAnalytics"
}

variable "ecr_image_tag_mutability" {
  description = <<-EOT
    MUTABLE permite reenviar a mesma tag. IMMUTABLE e a opcao endurecida e
    combina com tags por commit hash, mas faz falhar qualquer re-execucao do
    workflow sobre o mesmo commit - situacao comum durante a gravacao do video.
    Comeca em MUTABLE; trocar para IMMUTABLE e uma linha.
  EOT
  type        = string
  default     = "MUTABLE"

  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.ecr_image_tag_mutability)
    error_message = "Use MUTABLE ou IMMUTABLE."
  }
}

variable "ecr_images_to_keep" {
  description = "Quantas imagens manter por repositorio. As mais antigas expiram para conter custo."
  type        = number
  default     = 10
}

# ------------------------------------------------------------
# CI
# ------------------------------------------------------------

variable "github_repository" {
  description = <<-EOT
    Repositorio autorizado a assumir a role do CI via OIDC, no formato owner/repo.
    Qualquer outro repositorio recebe AccessDenied, mesmo dentro da mesma organizacao.
  EOT
  type        = string
  default     = "fiap-devops-arqcloud-2026/tech-challenge-03"
}
