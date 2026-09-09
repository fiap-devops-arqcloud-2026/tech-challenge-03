# ============================================================
# BACKEND REMOTO E VERSOES - CAMADA BASE (permanente)
# ============================================================
# O terraform.tfstate NAO fica local (O-09). Ele vive no bucket S3
# criado uma unica vez pelo procedimento de BOOTSTRAP-BACKEND-S3.md.
#
# Por que isso importa: o estado guarda o mapa de tudo que foi criado,
# incluindo senhas de banco em texto puro. Se ficasse no notebook de
# uma pessoa, o grupo nao conseguiria aplicar em paralelo e um HD
# queimado deixaria a infraestrutura orfa cobrando na fatura.
#
# ------------------------------------------------------------
# POR QUE EXISTEM DOIS ESTADOS SEPARADOS (D-017)
# ------------------------------------------------------------
# Esta pasta e a camada BASE: rede, ECR, SQS, DynamoDB e IAM. Tudo aqui
# custa praticamente zero parado e NUNCA e destruido.
#
# A camada CARA - EKS, RDS e ElastiCache - vive em terraform/cluster/,
# com estado proprio, e sobe e desce a cada sessao de trabalho.
#
# Se as duas dividissem o mesmo estado, o `terraform destroy` feito para
# parar de gastar credito levaria junto os repositorios ECR. Como eles
# usam force_delete, as imagens iriam junto, e o CI teria de reconstruir
# e reenviar as 5 imagens antes de cada sessao.
# ============================================================

# Bloco de configuracao do proprio Terraform (nao cria recurso na AWS).
terraform {

  # Versao minima do Terraform aceita para rodar este projeto.
  # >= 1.11 porque a flag use_lockfile (mais abaixo) so existe a partir dela.
  # Rodando com versao anterior, o terraform init falha com erro explicito.
  required_version = ">= 1.11.0"

  # Declara de quais providers este projeto depende e em que versao.
  required_providers {

    # "aws" e o nome local usado nos blocos provider/resource deste projeto.
    aws = {

      # Endereco do provider no registro publico do Terraform.
      source = "hashicorp/aws"

      # Piso de versao, sem teto de proposito. O modulo de VPC da comunidade
      # declara a propria restricao; fixar "~> 6.0" aqui poderia gerar
      # conflito insoluvel no terraform init. Quem trava a versao exata e o
      # .terraform.lock.hcl, que e versionado no Git justamente para isso.
      # Resolvido em 2026-08-27: provider 6.62.0 com modulo VPC 5.21.0.
      version = ">= 5.46"
    }
  }

  # Onde o arquivo de estado sera gravado. "s3" e o tipo de backend.
  backend "s3" {

    # Bucket criado manualmente pelo bootstrap (a unica excecao do projeto
    # a regra "se nao esta no codigo, nao existe" - ver BOOTSTRAP-BACKEND-S3.md).
    bucket = "togglemaster-tfstate-891376952395-us-east-2-an"

    # Caminho do arquivo de estado DENTRO do bucket.
    # Ha um unico ambiente (D-011), por isso o prefixo "prod/".
    # O sufixo "base" separa este estado do "prod/cluster.tfstate", usado
    # pela camada efemera em terraform/cluster/.
    key = "prod/base.tfstate"

    # Regiao do bucket. Precisa ser a mesma onde ele foi criado, senao o
    # terraform init falha dizendo que a regiao nao confere.
    region = "us-east-2"

    # Criptografa o objeto do estado no envio.
    # Redundante com a criptografia padrao do bucket, e de proposito: garante
    # protecao mesmo se alguem desligar o padrao do bucket por engano.
    encrypt = true

    # Lock nativo do S3 (atende R-03). Durante o apply, o Terraform cria um
    # arquivo prod/terraform.tfstate.tflock ao lado do estado. Se outra pessoa
    # tentar aplicar ao mesmo tempo, ela recebe erro em vez de corromper o
    # estado. Substitui a antiga tabela DynamoDB de lock, hoje depreciada.
    use_lockfile = true
  }
}
