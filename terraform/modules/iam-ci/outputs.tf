# ============================================================
# SAIDAS DO MODULO IAM-CI
# ============================================================

output "role_arn" {
  description = "ARN da role do CI. Vai no workflow do GitHub Actions, em role-to-assume da action aws-actions/configure-aws-credentials. Nao e segredo: sem um token OIDC vindo do repositorio autorizado, o ARN sozinho nao da acesso a nada."
  value       = aws_iam_role.github_actions.arn
}

output "role_name" {
  description = "Nome da role, util para consultas na AWS CLI e no console."
  value       = aws_iam_role.github_actions.name
}

output "oidc_provider_arn" {
  description = "ARN do provedor OIDC do GitHub. A Etapa 2 nao usa este valor - o EKS cria o proprio provedor OIDC, separado deste, para o IRSA dos pods."
  value       = aws_iam_openid_connect_provider.github.arn
}
