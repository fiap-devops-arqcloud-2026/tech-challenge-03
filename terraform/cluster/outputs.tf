# ============================================================
# SAIDAS - camada cluster
# ============================================================
# Estes valores fecham a ponte entre o Terraform e a pasta gitops/.
# Depois do apply, o P-040 consiste em conferir se o que esta escrito
# nos patches do overlay bate com o que sai daqui.
#
# Para ver tudo de uma vez:
#   terraform -chdir=terraform/cluster output
# ============================================================

# ------------------------------------------------------------
# CLUSTER
# ------------------------------------------------------------

output "cluster_name" {
  description = <<-EOT
    Nome do cluster EKS. Primeiro comando depois do apply, para o
    kubectl passar a enxergar o cluster:

      aws eks update-kubeconfig --region us-east-2 --name <este valor>
  EOT
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "URL da API do Kubernetes. Usada pelo provider helm quando o ArgoCD for instalado (P-029)."
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority" {
  description = <<-EOT
    Certificado da autoridade certificadora do cluster, em base64.

    A camada terraform/k8s/ consome este valor para configurar o
    provider kubernetes: sem ele o cliente nao confia no endpoint da
    API e toda chamada falha com erro de TLS.
  EOT
  value       = module.eks.cluster_certificate_authority
}

output "cluster_security_group_id" {
  description = "Security group do cluster. E a origem autorizada nos firewalls do RDS e do Redis."
  value       = module.eks.cluster_security_group_id
}

output "oidc_provider_arn" {
  description = "Provedor OIDC do cluster, base do IRSA. Nao confundir com o provedor OIDC do GitHub, que fica na camada base."
  value       = module.eks.oidc_provider_arn
}

# ------------------------------------------------------------
# ENDPOINTS QUE VAO PARA O GITOPS (P-040)
# ------------------------------------------------------------

output "rds_endpoints" {
  description = <<-EOT
    Mapa <banco> = <hostname>. Entram no DATABASE_URL de cada servico,
    conforme gitops/SECRETS-CONTRATO.md:
      auth -> auth-service-secret
      flag -> flag-service-secret
  EOT
  value       = module.rds.endpoints
}

output "redis_url" {
  description = <<-EOT
    URL completa do cache, ja com o esquema correto (redis:// ou
    rediss://, conforme a criptografia em transito).

    E o valor de REDIS_URL em
    gitops/overlays/prod/patches/endpoints.yaml. Copiar daqui evita o
    erro de esquema que derrubaria o evaluation-service no boot.
  EOT
  value       = module.elasticache.redis_url
}

output "irsa_role_arns" {
  description = <<-EOT
    Mapa <servico> = <ARN da role>. Precisam ser IDENTICOS as anotacoes
    eks.amazonaws.com/role-arn em
    gitops/overlays/prod/patches/irsa.yaml.

    Divergencia aqui nao quebra o deploy: o pod sobe normalmente e so
    falha em tempo de execucao, com AccessDenied ao chamar SQS ou
    DynamoDB. Por isso vale conferir ANTES de gravar.
  EOT
  value       = module.irsa.role_arns
}

# ------------------------------------------------------------
# SEGREDOS
# ------------------------------------------------------------

output "database_urls" {
  description = <<-EOT
    Mapa <banco> = <URL de conexao completa, com senha>.

    SENSIVEL: o Terraform imprime "(sensitive value)" em vez do valor.
    Para ler de fato, quando for montar os Secrets do Kubernetes:

      terraform -chdir=terraform/cluster output -json database_urls

    Preferir a leitura pelo Secrets Manager sempre que possivel - la o
    acesso fica registrado no CloudTrail (S-07).
  EOT
  value       = module.rds.database_urls
  sensitive   = true
}

output "secretsmanager_arns" {
  description = <<-EOT
    ARNs dos segredos gravados no AWS Secrets Manager, um por banco.

    Evidencia direta para o relatorio (O-38): as senhas sao geradas pelo
    Terraform, guardadas em servico gerenciado e nunca passam por
    arquivo de texto - que e a dor descrita no enunciado.
  EOT
  value       = module.rds.secret_arns
}

# ------------------------------------------------------------
# REPASSE DA CAMADA BASE
# ------------------------------------------------------------
# Evita alternar de diretorio so para consultar um valor da base.
# ------------------------------------------------------------

output "base_vpc_id" {
  description = "VPC criada pela camada base."
  value       = local.vpc_id
}

output "base_private_subnet_ids" {
  description = "Subnets privadas da base, onde EKS, RDS e cache foram criados."
  value       = local.private_subnet_ids
}
