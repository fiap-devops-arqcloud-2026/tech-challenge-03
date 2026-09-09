# ============================================================
# PROVIDERS - camada k8s
# ============================================================
# Tres providers: aws (le o Secrets Manager), kubernetes (cria Secrets,
# namespace e StorageClass) e helm (instala o ArgoCD).
#
# Os dois ultimos se configuram a partir de valores lidos do estado da
# camada cluster. Como aquele estado JA EXISTE quando esta camada roda,
# os valores sao conhecidos em tempo de plan e nao ha o problema de
# "provider configuration cannot be evaluated" descrito em backend.tf.
# ============================================================

# ------------------------------------------------------------
# AWS
# ------------------------------------------------------------
provider "aws" {
  region = var.aws_region

  # Mesmas tags das outras camadas, para o Cost Explorer somar tudo no
  # mesmo grupo (D-009).
  default_tags {
    tags = var.default_tags
  }
}

# ------------------------------------------------------------
# KUBERNETES
# ------------------------------------------------------------
provider "kubernetes" {
  # Endereco da API, vindo do estado da camada cluster.
  host = local.cluster_endpoint

  # Certificado da CA. Vem em base64 e precisa ser decodificado aqui.
  cluster_ca_certificate = base64decode(local.cluster_ca)

  # AUTENTICACAO POR TOKEN TEMPORARIO
  # ---------------------------------
  # Em vez de guardar um kubeconfig em disco, o provider executa a AWS
  # CLI a cada operacao e pega um token valido por 15 minutos.
  #
  # Vantagens: nada de credencial em arquivo, e o acesso usa a mesma
  # identidade IAM ja configurada na maquina (o usuario que rodou o
  # apply do cluster e admin dele por bootstrap_cluster_creator_admin).
  #
  # Requisito: a AWS CLI precisa estar instalada e no PATH.
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      local.cluster_name,
      "--region",
      var.aws_region,
    ]
  }
}

# ------------------------------------------------------------
# HELM
# ------------------------------------------------------------
# Mesma configuracao de acesso do provider kubernetes, so que passada
# dentro do atributo kubernetes = { ... }.
# ------------------------------------------------------------
provider "helm" {
  # ATENCAO A SINTAXE: no provider helm 3.x "kubernetes" e um ATRIBUTO
  # (com sinal de igual e chaves), e nao mais um bloco aninhado como era
  # na linha 2.x. Escrever `kubernetes { ... }` aqui falha o validate com
  # "Blocks of type kubernetes are not expected here".
  kubernetes = {
    host                   = local.cluster_endpoint
    cluster_ca_certificate = base64decode(local.cluster_ca)

    # Mesma autenticacao por token temporario do provider kubernetes.
    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = [
        "eks",
        "get-token",
        "--cluster-name",
        local.cluster_name,
        "--region",
        var.aws_region,
      ]
    }
  }
}
