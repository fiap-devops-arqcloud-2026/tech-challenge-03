# ============================================================
# COMPOSICAO DA CAMADA CLUSTER - recursos que cobram por hora
# ============================================================
# Este arquivo nao cria recurso direto: ele CHAMA os modulos e liga a
# saida de um na entrada do outro. A logica de cada peca vive em
# terraform/modules/.
#
# O que nasce aqui: cluster EKS e node group (O-03, O-04), 2 instancias
# RDS PostgreSQL (O-05 parcial - ver D-015), 1 cluster ElastiCache
# Redis (O-06) e as duas roles IRSA dos pods (S-06).
#
# ORIGEM DOS MODULOS
# Os modulos eks, rds e elasticache foram derivados dos equivalentes na
# branch main e adaptados as restricoes desta conta - principalmente por
# dois bloqueios comprovados do plano gratuito (F-023): a t3.medium e
# recusada, e a terceira instancia RDS tambem. O cabecalho de cada
# modulo detalha o que mudou e por que.
#
# LEMBRETE DE CUSTO
# Com tudo isto de pe a conta corre a cerca de US$ 0,37/h (F-026), ou
# US$ 8,80 por dia. Rodar `terraform destroy` NESTA PASTA ao fim de cada
# sessao nao e otimizacao, e requisito - restavam US$ 70 de credito.
# ============================================================

# Valores calculados uma vez e reutilizados. Diferente de variable, nao
# pode ser sobrescrito de fora.
locals {
  # Atalho para nao repetir var.project_name em toda chamada.
  name = var.project_name

  # Namespace onde os 5 servicos rodam. Precisa bater com o declarado em
  # gitops/base/kustomization.yaml, senao a politica de confianca do
  # IRSA nao casa com a ServiceAccount real (F-019).
  namespace = "togglemaster"
}

# ------------------------------------------------------------
# CLUSTER EKS (O-03 e O-04)
# ------------------------------------------------------------
# Primeiro da fila: o RDS e o ElastiCache dependem do security group
# dele para saber quem autorizar, e o IRSA depende do provedor OIDC que
# so existe depois que o cluster sobe.
# ------------------------------------------------------------

module "eks" {
  # Caminho relativo a esta pasta: terraform/cluster/ -> terraform/modules/eks/
  source = "../modules/eks"

  # Nome do cluster e prefixo das roles.
  name = local.name

  # Subnets PRIVADAS lidas do estado da camada base (ver data.tf).
  subnet_ids = local.private_subnet_ids

  # Versao do Kubernetes. Confirmado em 2026-09-08 que a 1.31 esta
  # disponivel em us-east-2.
  kubernetes_version = var.kubernetes_version

  # c7i-flex.large por bloqueio da conta a t3.medium (F-023, D-016).
  node_instance_type = var.node_instance_type

  # Dimensionamento do node group. O desejado e 2 para o HPA do
  # evaluation ter onde agendar o pod extra (F-020).
  node_group_min_size     = var.node_group_min_size
  node_group_desired_size = var.node_group_desired_size
  node_group_max_size     = var.node_group_max_size
}

# ------------------------------------------------------------
# BANCOS RDS (O-05, parcial por D-015)
# ------------------------------------------------------------
# Dois bancos: auth_db e flags_db. O terceiro, targeting_db, roda como
# StatefulSet no cluster porque a conta recusa a terceira instancia RDS
# (F-023) - arranjo aprovado pelo professor.
# ------------------------------------------------------------

module "rds" {
  source = "../modules/rds"

  name = local.name

  # VPC e subnets vem da camada base.
  vpc_id     = local.vpc_id
  subnet_ids = local.private_subnet_ids

  # Autoriza a porta 5432 apenas para quem estiver no security group do
  # cluster - ou seja, os nos do EKS. E menor privilegio de verdade: nao
  # basta estar na VPC (S-06).
  allowed_security_group_id = module.eks.cluster_security_group_id

  # Mapa com os dois bancos, definido em variables.tf.
  databases = var.rds_databases

  # db.t3.micro, a menor classe elegivel ao Free Tier.
  instance_class    = var.rds_instance_class
  allocated_storage = var.rds_allocated_storage
}

# ------------------------------------------------------------
# CACHE REDIS (O-06)
# ------------------------------------------------------------
# Consumido apenas pelo evaluation-service, no caminho quente.
# ------------------------------------------------------------

module "elasticache" {
  source = "../modules/elasticache"

  name = local.name

  vpc_id     = local.vpc_id
  subnet_ids = local.private_subnet_ids

  # Mesma logica do RDS: origem pelo security group do cluster.
  allowed_security_group_id = module.eks.cluster_security_group_id

  node_type = var.elasticache_node_type

  # Criptografia em transito DESLIGADA de proposito. Ligar sem trocar o
  # REDIS_URL do ConfigMap para "rediss://" derruba o evaluation-service
  # no boot - o codigo chama log.Fatalf quando a conexao inicial falha.
  # O passo a passo para ligar esta na descricao da variavel do modulo.
  transit_encryption_enabled = var.redis_transit_encryption
}

# ------------------------------------------------------------
# IDENTIDADE DOS PODS - IRSA (S-06)
# ------------------------------------------------------------
# Substitui as chaves estaticas AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY
# que a Fase 2 guardava dentro de um Secret do Kubernetes (F-017).
# Depende do provedor OIDC criado junto com o cluster.
# ------------------------------------------------------------

module "irsa" {
  source = "../modules/irsa"

  name = local.name

  # Namespace dos pods. Entra na condicao "sub" da politica de confianca.
  namespace = local.namespace

  # Provedor OIDC do cluster, saida do modulo eks.
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url

  # As duas ServiceAccounts que precisam falar com a AWS. Os nomes
  # precisam bater com gitops/base/*/serviceaccount.yaml.
  service_accounts = {
    evaluation = {
      service_account = "evaluation-service"
    }
    analytics = {
      service_account = "analytics-service"
    }
  }

  # ARNs lidos do estado da camada base. Restringem cada policy aos
  # recursos deste projeto, sem curinga.
  sqs_queue_arn      = local.sqs_queue_arn
  dynamodb_table_arn = local.dynamodb_table_arn
}
