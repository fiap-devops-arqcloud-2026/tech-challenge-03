variable "project_name" {
  description = "Prefixo dos nomes de recurso."
  type        = string
}

variable "github_repository" {
  description = "Repositorio autorizado a assumir a role, no formato owner/repo."
  type        = string
}

variable "ecr_repository_arns" {
  description = "ARNs dos repositorios ECR aos quais o CI pode enviar imagens."
  type        = list(string)
}
