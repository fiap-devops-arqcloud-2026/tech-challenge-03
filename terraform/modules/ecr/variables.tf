# ============================================================
# ENTRADAS DO MODULO ECR
# ============================================================
# Variaveis sem `default` sao obrigatorias: quem chama o modulo em
# main.tf precisa informar o valor, senao o plan falha.
# ============================================================

variable "services" {
  description = "Lista de microsservicos. Cada item vira um repositorio <servico>-service."
  type        = list(string)
  # Sem default de proposito: nao ha lista "natural" de servicos, quem
  # chama precisa dizer explicitamente quais sao.
}

variable "image_tag_mutability" {
  description = "MUTABLE permite sobrescrever tag existente; IMMUTABLE proibe."
  type        = string

  # Padrao seguro para nao quebrar re-execucao de workflow no mesmo commit.
  default = "MUTABLE"
}

variable "images_to_keep" {
  description = "Quantidade de imagens mantidas por repositorio antes da expiracao."
  type        = number

  # 10 permite voltar algumas versoes sem acumular lixo indefinidamente.
  default = 10
}
