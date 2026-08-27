# ============================================================
# SAIDAS - camada cluster
# ============================================================
# Ficarao aqui, na Fase B, os valores que precisam ser copiados para os
# manifestos em gitops/overlays/prod/patches/ (P-040):
#
#   cluster_name          nome do EKS, para o `aws eks update-kubeconfig`
#   cluster_endpoint      usado pelo provider helm da camada argocd
#   redis_endpoint        vira REDIS_URL no ConfigMap do evaluation
#   irsa_role_arns        viram as anotacoes em patches/irsa.yaml
#   secretsmanager_names  nomes dos segredos gerados
#
# Nao ha saidas ainda porque nao ha recursos. Declarar output de
# recurso inexistente quebraria o `terraform validate`.
# ============================================================

# Repassa as saidas da base para quem trabalha nesta pasta, evitando
# alternar de diretorio so para consultar um valor.
output "base_vpc_id" {
  description = "VPC criada pela camada base. Repassado por conveniencia."
  value       = local.vpc_id
}

output "base_private_subnet_ids" {
  description = "Subnets privadas da base, onde EKS, RDS e cache serao criados."
  value       = local.private_subnet_ids
}
