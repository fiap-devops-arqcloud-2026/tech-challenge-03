# ============================================================
# ENTRADAS DO MODULO IAM-CI
# ============================================================

variable "project_name" {
  description = "Prefixo do nome da role e da policy."
  type        = string
}

variable "github_repository" {
  description = "Repositorio autorizado a assumir a role, no formato owner/repo."
  type        = string
  # Sem default de proposito: um valor errado aqui abriria a role para
  # outro repositorio. Melhor obrigar quem chama a declarar.
}

variable "ecr_repository_arns" {
  description = "ARNs dos repositorios ECR aos quais o CI pode enviar imagens."
  type        = list(string)
  # Recebido de module.ecr.repository_arns em main.tf. E o que garante que a
  # permissao acompanhe automaticamente os repositorios que existem de fato.
}
