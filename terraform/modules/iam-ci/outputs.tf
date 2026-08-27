output "role_arn" {
  description = "ARN da role do CI. Vai no workflow do GitHub Actions, em role-to-assume da action aws-actions/configure-aws-credentials. Nao e segredo: sem o token OIDC do repositorio autorizado, o ARN sozinho nao da acesso a nada."
  value       = aws_iam_role.github_actions.arn
}

output "role_name" {
  description = "Nome da role do CI."
  value       = aws_iam_role.github_actions.name
}

output "oidc_provider_arn" {
  description = "ARN do provedor OIDC do GitHub."
  value       = aws_iam_openid_connect_provider.github.arn
}
