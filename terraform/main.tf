# ============================================================
# COMPOSICAO DA INFRAESTRUTURA - ETAPA 1
# ============================================================
# Este arquivo nao cria recurso diretamente: ele CHAMA os modulos e
# liga a saida de um na entrada do outro. Toda a logica de cada peca
# fica dentro de modules/.
#
# Esta etapa cria apenas o que e barato e rapido (~5 min de apply):
# rede, ECR, SQS, DynamoDB e a role OIDC do CI.
#
# Por que separar: com o ECR e a role do CI existindo, o pipeline de
# DevSecOps (O-10 a O-21) ja pode ser construido e rodar em paralelo,
# sem esperar os ~25 minutos do EKS + 3 RDS + ElastiCache da Etapa 2.
# ============================================================

# Bloco locals: valores calculados uma vez e reutilizados no arquivo.
# Diferente de variable, nao pode ser sobrescrito de fora.
locals {

  # Atalho para nao repetir var.project_name em toda chamada de modulo.
  name = var.project_name

  # Tags de descoberta de subnet usadas pelo Kubernetes.
  # Nao ha Load Balancer no projeto (D-012), mas a tag e gratuita e evita
  # retrabalho caso o grupo decida expor algo depois.
  private_subnet_tags = {
    # Marca a subnet como candidata a Load Balancer INTERNO.
    "kubernetes.io/role/internal-elb" = "1"
  }

  public_subnet_tags = {
    # Marca a subnet como candidata a Load Balancer voltado para a internet.
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
  # Endereco do modulo no registro publico do Terraform.
  source = "terraform-aws-modules/vpc/aws"

  # Trava a linha 5.x. Resolvido para 5.21.0 em 2026-08-27.
  version = "~> 5.0"

  # Nome base: a VPC e todos os recursos filhos herdam este prefixo.
  name = local.name

  # Faixa de IPs privados da VPC inteira.
  cidr = var.vpc_cidr

  # Zonas de disponibilidade usadas. A ordem casa com as listas de CIDR abaixo.
  azs = var.availability_zones

  # Subnets sem rota direta para a internet: EKS, RDS e ElastiCache.
  private_subnets = var.private_subnet_cidrs

  # Subnets com rota para o Internet Gateway: apenas o NAT mora aqui.
  public_subnets = var.public_subnet_cidrs

  # Liga ou desliga o NAT. Desligado, nada em subnet privada alcanca a
  # internet - o que e aceitavel na Etapa 1, onde nada roda la ainda.
  enable_nat_gateway = var.enable_nat_gateway

  # Um unico NAT em vez de um por AZ. Producao de verdade usaria um por
  # zona; aqui isso economiza cerca de US$ 33/mes ao custo de um ponto
  # unico de falha, aceitavel num projeto de estudo.
  single_nat_gateway = true

  # Habilita nomes DNS internos na VPC. Sem isso, os nos do EKS nao
  # resolvem os enderecos dos servicos da AWS nem uns aos outros.
  enable_dns_hostnames = true

  # Habilita o resolvedor DNS da propria VPC. Pre-requisito do item acima.
  enable_dns_support = true

  # Aplica as tags de descoberta definidas em locals.
  private_subnet_tags = local.private_subnet_tags
  public_subnet_tags  = local.public_subnet_tags
}

# ------------------------------------------------------------
# REGISTRO DE IMAGENS (O-21 / R-02)
# ------------------------------------------------------------

module "ecr" {
  # Caminho relativo: modulo escrito por nos, dentro deste repositorio.
  source = "./modules/ecr"

  # Lista dos 5 servicos. O modulo cria um repositorio para cada um.
  services = var.services

  # MUTABLE ou IMMUTABLE - ver a explicacao em variables.tf.
  image_tag_mutability = var.ecr_image_tag_mutability

  # Quantas imagens sobrevivem antes de a politica de lifecycle expirar as antigas.
  images_to_keep = var.ecr_images_to_keep
}

# ------------------------------------------------------------
# MENSAGERIA E ANALYTICS (O-07 e O-08)
# ------------------------------------------------------------

module "messaging" {
  source = "./modules/messaging"

  # Prefixo dos nomes da fila e da dead-letter queue.
  project_name = local.name

  # Nome literal da tabela, exigido pelo enunciado.
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

  # Prefixo do nome da role e da policy.
  project_name = local.name

  # Unico repositorio autorizado a assumir a role.
  github_repository = var.github_repository

  # AQUI ESTA A LIGACAO ENTRE MODULOS: a saida do modulo de ECR vira a
  # entrada do modulo de IAM. E isso que permite restringir a permissao
  # do CI exatamente aos 5 repositorios criados, em vez de liberar ecr:*
  # na conta inteira. O Terraform tambem usa essa referencia para saber
  # que o ECR precisa ser criado ANTES da policy.
  ecr_repository_arns = module.ecr.repository_arns

  # Criar o provedor OIDC do GitHub ou reaproveitar o que ja existe na
  # conta. A explicacao dos dois modos esta em modules/iam-ci/main.tf.
  create_oidc_provider = var.create_github_oidc_provider
}
