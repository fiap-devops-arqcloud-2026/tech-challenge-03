variable "project_name" {
  description = "Prefixo dos nomes de recurso."
  type        = string
}

variable "dynamodb_table_name" {
  description = "Nome literal da tabela DynamoDB exigido pelo enunciado."
  type        = string
  default     = "ToggleMasterAnalytics"
}
