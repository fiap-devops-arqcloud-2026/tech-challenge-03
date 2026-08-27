# ============================================================
# COMPOSICAO DA INFRAESTRUTURA - ETAPA 1
# ============================================================
# Esta etapa cria apenas o que e barato e rapido (~5 min de apply):
# rede, ECR, SQS, DynamoDB e a role OIDC do CI.
#
# Por que separar: com o ECR e a role do CI existindo, o pipeline de
# DevSecOps (O-10 a O-21) ja pode ser construido e rodar em paralelo,
# sem esperar os ~25 minutos do EKS + 3 RDS + ElastiCache da Etapa 2.
# ============================================================

locals {
  name = var.project_name

  # Subnets privadas recebem esta tag para que, se um dia houver um
  # Load Balancer interno, o controller saiba onde criar. E gratuito
  # e evita retrabalho.
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }
}

# ------------------------------------------------------------
# REDE (O-02)
# ------------------------------------------------------------
# Usa o modulo oficial da comunidade (D-010). Escrever VPC, IGW, NAT,
# route tables e associacoes a mao seria cerca de 150 linhas para
# reproduzir exatamente o que este modulo ja faz e testa.
# ------------------------------------------------------------

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = local.name
  cidr = var.vpc_cidr

  azs             = var.availability_zones
  private_subnets = var.private_subnet_cidrs
  public_subnets  = var.public_subnet_cidrs

  # Um unico NAT em vez de um por AZ. Producao de verdade usaria um por
  # zona; aqui isso economiza cerca de US$ 33/mes ao custo de um ponto
  # unico de falha, aceitavel num projeto de estudo.
  enable_nat_gateway = var.enable_nat_gateway
  single_nat_gateway = true

  # Necessario para que os nos do EKS resolvam nomes internos.
  enable_dns_hostnames = true
  enable_dns_support   = true

  private_subnet_tags = local.private_subnet_tags
  public_subnet_tags  = local.public_subnet_tags
}

# ------------------------------------------------------------
# REGISTRO DE IMAGENS (O-21 / R-02)
# ------------------------------------------------------------

module "ecr" {
  source = "./modules/ecr"

  services             = var.services
  image_tag_mutability = var.ecr_image_tag_mutability
  images_to_keep       = var.ecr_images_to_keep
}

# ------------------------------------------------------------
# MENSAGERIA E ANALYTICS (O-07 e O-08)
# ------------------------------------------------------------

module "messaging" {
  source = "./modules/messaging"

  project_name        = local.name
  dynamodb_table_name = var.dynamodb_table_name
}

# ------------------------------------------------------------
# IDENTIDADE DO CI (S-01 / S-06)
# ------------------------------------------------------------
# OIDC no lugar de access key estatica guardada no GitHub. O pipeline
# troca um token de curta duracao por credenciais temporarias, e a role
# so aceita ser assumida por este repositorio.
# ------------------------------------------------------------

module "iam_ci" {
  source = "./modules/iam-ci"

  project_name        = local.name
  github_repository   = var.github_repository
  ecr_repository_arns = module.ecr.repository_arns
}
