# ============================================================
# SAIDAS DA RAIZ
# ============================================================
# Estes valores aparecem ao final do apply e podem ser recuperados a
# qualquer momento com `terraform output` ou, individualmente, com
# `terraform output -raw <nome>`.
#
# Eles alimentam as proximas etapas: os manifestos em gitops/, os
# workflows do GitHub Actions e a Etapa 2 do Terraform.
# ============================================================

# ------------------------------------------------------------
# Rede - consumida pela Etapa 2 (EKS, RDS, ElastiCache)
# ------------------------------------------------------------

output "vpc_id" {
  description = "ID da VPC. A Etapa 2 usa para posicionar cluster, bancos e cache dentro dela."
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "Subnets privadas: onde ficam nos do EKS, RDS e ElastiCache."

  # Lista com um ID por AZ, na mesma ordem de availability_zones.
  value = module.vpc.private_subnets
}

output "public_subnet_ids" {
  description = "Subnets publicas: apenas o NAT Gateway mora aqui (nao ha Load Balancer, ver D-012)."
  value       = module.vpc.public_subnets
}

# ------------------------------------------------------------
# ECR - consumido pelo CI e pelo Kustomize
# ------------------------------------------------------------

output "ecr_repository_urls" {
  description = "URL de cada repositorio. Vai no campo images do kustomization.yaml e no docker push do pipeline."

  # Mapa: { "auth" = "891...amazonaws.com/auth-service", ... }
  value = module.ecr.repository_urls
}

# ------------------------------------------------------------
# Mensageria - consumida pelos manifestos dos servicos
# ------------------------------------------------------------

output "sqs_queue_url" {
  description = "Valor de AWS_SQS_URL nos servicos evaluation e analytics."
  value       = module.messaging.queue_url
}

output "sqs_queue_arn" {
  description = "ARN da fila. Usado nas policies IRSA da Etapa 2."
  value       = module.messaging.queue_arn
}

output "dynamodb_table_name" {
  description = "Valor de AWS_DYNAMODB_TABLE no analytics-service."
  value       = module.messaging.dynamodb_table_name
}

output "dynamodb_table_arn" {
  description = "ARN da tabela. Usado na policy IRSA do analytics-service na Etapa 2."
  value       = module.messaging.dynamodb_table_arn
}

# ------------------------------------------------------------
# CI
# ------------------------------------------------------------

output "github_actions_role_arn" {
  description = "ARN a ser usado em role-to-assume no workflow do GitHub Actions. Este e o valor que substitui a antiga dupla AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY nos secrets do repositorio."
  value       = module.iam_ci.role_arn
}
