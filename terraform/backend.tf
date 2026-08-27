# ============================================================
# BACKEND REMOTO E VERSOES
# ============================================================
# O terraform.tfstate NAO fica local (O-09). Ele vive no bucket S3
# criado uma unica vez pelo procedimento de BOOTSTRAP-BACKEND-S3.md.
#
# Por que isso importa: o estado guarda o mapa de tudo que foi criado,
# incluindo senhas de banco em texto puro. Se ficasse no notebook de
# uma pessoa, o grupo nao conseguiria aplicar em paralelo e um HD
# queimado deixaria a infraestrutura orfa cobrando na fatura.
# ============================================================

terraform {
  # use_lockfile exige Terraform 1.11 ou superior.
  required_version = ">= 1.11.0"

  required_providers {
    aws = {
      source = "hashicorp/aws"

      # Piso, sem teto de proposito. O modulo de VPC da comunidade tem a
      # propria restricao de versao; fixar "~> 6.0" aqui poderia gerar
      # conflito insoluvel no `terraform init`. Quem define a versao exata
      # e o .terraform.lock.hcl, que e versionado justamente para isso.
      version = ">= 5.46"
    }
  }

  backend "s3" {
    bucket = "togglemaster-tfstate-891376952395-us-east-2-an"

    # Caminho do arquivo de estado dentro do bucket. Se um dia houver
    # mais de um ambiente, viram prod/, hml/ etc. no mesmo bucket.
    key    = "prod/terraform.tfstate"
    region = "us-east-2"

    # Criptografa o objeto mesmo se o padrao do bucket mudar.
    encrypt = true

    # Lock nativo do S3 (R-03): cria um .tflock ao lado do estado durante
    # o apply, impedindo que duas pessoas apliquem ao mesmo tempo.
    # Substitui a antiga tabela DynamoDB de lock, que esta depreciada.
    use_lockfile = true
  }
}
