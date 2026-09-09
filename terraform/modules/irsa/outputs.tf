# ============================================================
# SAIDAS - modulo irsa
# ============================================================

output "role_arns" {
  description = <<-EOT
    Mapa <chave> = <ARN da role>. Sao EXATAMENTE os valores que precisam
    estar em gitops/overlays/prod/patches/irsa.yaml, na anotacao
    eks.amazonaws.com/role-arn de cada ServiceAccount.

    Conferir depois do apply com:
      terraform -chdir=terraform/cluster output irsa_role_arns

    Se divergir do que esta no patch, o pod sobe mas nao consegue
    assumir a role, e as chamadas a SQS e ao DynamoDB falham com
    AccessDenied - erro que so aparece em tempo de execucao.
  EOT
  value       = { for k, v in aws_iam_role.this : k => v.arn }
}

output "role_names" {
  description = "Mapa <chave> = <nome da role>. Util para consultas na AWS CLI e no console."
  value       = { for k, v in aws_iam_role.this : k => v.name }
}
