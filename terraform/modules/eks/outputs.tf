# ============================================================
# SAIDAS - modulo eks
# ============================================================
# O que outros modulos e o root precisam saber sobre o cluster.
# ============================================================

output "cluster_name" {
  description = "Nome do cluster. Usado no comando de kubeconfig: aws eks update-kubeconfig --name <isto>."
  value       = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  description = "URL da API do Kubernetes. E o server: do kubeconfig."
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority" {
  description = "Certificado da CA do cluster, em base64. Vai no kubeconfig para o kubectl confiar no endpoint."
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "cluster_security_group_id" {
  description = <<-EOT
    Security group que o EKS cria sozinho para o cluster. Os nos entram
    nele automaticamente, entao liberar este SG na origem do RDS e do
    Redis e o que permite os pods alcancarem banco e cache.
  EOT
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

output "oidc_provider_arn" {
  description = <<-EOT
    ARN do provedor OIDC do cluster. E a base do IRSA (S-06): o modulo
    irsa usa este ARN para escrever a politica de confianca das roles
    dos pods de evaluation e analytics.
  EOT
  value       = aws_iam_openid_connect_provider.cluster.arn
}

output "oidc_provider_url" {
  description = "URL do emissor OIDC, sem o prefixo https://. Entra na condicao 'sub' das roles IRSA."
  value       = replace(aws_iam_openid_connect_provider.cluster.url, "https://", "")
}
