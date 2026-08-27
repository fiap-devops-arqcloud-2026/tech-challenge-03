variable "services" {
  description = "Lista de microsservicos. Cada item vira um repositorio <servico>-service."
  type        = list(string)
}

variable "image_tag_mutability" {
  description = "MUTABLE ou IMMUTABLE."
  type        = string
  default     = "MUTABLE"
}

variable "images_to_keep" {
  description = "Quantidade de imagens mantidas por repositorio antes da expiracao."
  type        = number
  default     = 10
}
