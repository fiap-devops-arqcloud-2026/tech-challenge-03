# ============================================================
# ENTRADAS DO MODULO MESSAGING
# ============================================================

variable "project_name" {
  description = "Prefixo dos nomes da fila e da dead-letter queue."
  type        = string
  # Sem default: quem chama precisa informar, para nao criar recurso
  # com nome generico por acidente.
}

variable "dynamodb_table_name" {
  description = "Nome literal da tabela DynamoDB exigido pelo enunciado."
  type        = string

  # Tem default porque o nome e fixo por requisito, nao por escolha.
  default = "ToggleMasterAnalytics"
}
