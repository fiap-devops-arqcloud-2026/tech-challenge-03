# ============================================================
# VARIAVEIS DE ENTRADA - modulo irsa
# ============================================================

variable "name" {
  description = "Prefixo dos nomes. Gera togglemaster-evaluation-irsa e togglemaster-analytics-irsa."
  type        = string
}

variable "namespace" {
  description = <<-EOT
    Namespace onde os pods rodam. Entra na condicao "sub" da politica de
    confianca, entao precisa bater exatamente com o namespace declarado
    em gitops/base/kustomization.yaml - hoje "togglemaster" (F-019).
  EOT
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN do provedor OIDC do cluster EKS. Vem da saida oidc_provider_arn do modulo eks."
  type        = string
}

variable "oidc_provider_url" {
  description = "URL do emissor OIDC SEM o prefixo https://. Vem da saida oidc_provider_url do modulo eks."
  type        = string
}

variable "service_accounts" {
  description = <<-EOT
    Mapa <chave> = { service_account = <nome da ServiceAccount> }.

    A chave vira parte do nome da role e e usada nos blocos de policy do
    main.tf, entao "evaluation" e "analytics" sao obrigatorias - trocar
    a chave quebra a referencia aws_iam_role.this["evaluation"].
  EOT
  type = map(object({
    service_account = string
  }))
}

variable "sqs_queue_arn" {
  description = "ARN da fila de eventos. Restringe as policies a NOSSA fila, sem curinga."
  type        = string
}

variable "dynamodb_table_arn" {
  description = "ARN da tabela ToggleMasterAnalytics. Restringe a policy do analytics a essa tabela."
  type        = string
}
