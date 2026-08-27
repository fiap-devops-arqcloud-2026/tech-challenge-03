# ============================================================
# SAIDAS
# ============================================================
# Estes valores alimentam as proximas etapas: os manifestos em gitops/,
# os workflows do GitHub Actions e a Etapa 2 do Terraform.
# Recupere a qualquer momento com `terraform output`.
# ============================================================

# ------------------------------------------------------------
# Rede - consumida pela Etapa 2 (EKS, RDS, ElastiCache)
# ------------------------------------------------------------

output "vpc_id" {
  description = "ID da VPC."
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "Subnets privadas: nos do EKS, RDS e ElastiCache."
  value       = module.vpc.private_subnets
}

output "public_subnet_ids" {
  description = "Subnets publicas: apenas o NAT Gateway."
  value       = module.vpc.public_subnets
}

# ------------------------------------------------------------
# ECR - consumido pelo CI e pelo Kustomize
# ------------------------------------------------------------

output "ecr_repository_urls" {
  description = "URL de cada repositorio. Vai no campo images do kustomization.yaml e no docker push do pipeline."
  value       = module.ecr.repository_urls
}

# ------------------------------------------------------------
# Mensageria - consumida pelos manifestos dos servicos
# ------------------------------------------------------------

output "sqs_queue_url" {
  description = "Valor de AWS_SQS_URL nos servicos evaluation e analytics."
  value       = module.messaging.queue_url
}

output "sqs_queue_arn" {
  description = "ARN da fila, usado nas policies IRSA da Etapa 2."
  value       = module.messaging.queue_arn
}

output "dynamodb_table_name" {
  description = "Valor de AWS_DYNAMODB_TABLE no analytics-service."
  value       = module.messaging.dynamodb_table_name
}

output "dynamodb_table_arn" {
  description = "ARN da tabela, usado na policy IRSA do analytics-service."
  value       = module.messaging.dynamodb_table_arn
}

# ------------------------------------------------------------
# CI
# ------------------------------------------------------------

output "github_actions_role_arn" {
  description = "ARN a ser usado em role-to-assume no workflow do GitHub Actions."
  value       = module.iam_ci.role_arn
}
