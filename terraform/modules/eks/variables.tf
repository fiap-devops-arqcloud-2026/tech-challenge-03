# ============================================================
# VARIAVEIS DE ENTRADA - modulo eks
# ============================================================
# Todas obrigatorias, sem default. Um modulo com default escondido e um
# modulo que cria recurso errado em silencio: quem chama tem de declarar
# o que quer. Os defaults ficam em terraform/cluster/variables.tf, que e
# onde a decisao do projeto mora e esta documentada.
# ============================================================

variable "name" {
  description = "Prefixo dos nomes. Vira o nome do cluster e o prefixo das roles."
  type        = string
}

variable "subnet_ids" {
  description = <<-EOT
    Subnets onde ficam o control plane e os nos. Sao as PRIVADAS da
    camada base. O EKS exige no minimo duas, em zonas diferentes.
  EOT
  type        = list(string)
}

variable "kubernetes_version" {
  description = "Versao do Kubernetes. Confirmado em 2026-09-08 que 1.31 a 1.36 estao disponiveis em us-east-2."
  type        = string
}

variable "node_instance_type" {
  description = <<-EOT
    Tipo EC2 dos nos. Esta conta RECUSA t3.medium por estar no plano
    gratuito novo (F-023); o valor usado e c7i-flex.large (D-016).
  EOT
  type        = string
}

variable "node_group_min_size" {
  description = "Minimo de nos no auto scaling do node group."
  type        = number
}

variable "node_group_desired_size" {
  description = "Nos desejados. 2 para o HPA ter onde agendar o pod extra (F-020)."
  type        = number
}

variable "node_group_max_size" {
  description = "Maximo de nos no auto scaling do node group."
  type        = number
}
