# ============================================================
# BACKEND REMOTO E VERSOES - CAMADA CLUSTER (efemera)
# ============================================================
# Esta pasta concentra TUDO que cobra por hora: EKS, node group, os 2
# RDS e o ElastiCache. Ela sobe no inicio da sessao de trabalho e e
# destruida no fim.
#
# A camada base (terraform/) fica de pe permanentemente e nao e tocada
# por um destroy aqui. E isso que preserva os repositorios ECR, as
# imagens ja publicadas, a fila e a tabela entre uma sessao e outra.
#
# Ordem obrigatoria:
#   1. terraform -chdir=terraform apply          (base, uma vez so)
#   2. terraform -chdir=terraform/cluster apply  (a cada sessao)
#   3. ... trabalho ...
#   4. terraform -chdir=terraform/cluster destroy
#
# O passo 2 FALHA se o passo 1 nunca rodou, porque este modulo le as
# saidas da base por remote state (ver data.tf).
# ============================================================

terraform {
  # Mesma exigencia da base: use_lockfile so existe a partir da 1.11.
  required_version = ">= 1.11.0"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      # Mesmo criterio da base: piso sem teto, para nao conflitar com a
      # restricao interna dos modulos da comunidade. O lock file trava.
      version = ">= 5.46"
    }
  }

  backend "s3" {
    # Mesmo bucket da base - um bucket por projeto, nao por camada.
    bucket = "togglemaster-tfstate-891376952395-us-east-2-an"

    # Chave DIFERENTE da base. E isto que cria dois estados independentes
    # dentro do mesmo bucket e permite destruir um sem afetar o outro.
    key = "prod/cluster.tfstate"

    region  = "us-east-2"
    encrypt = true

    # Lock nativo do S3 (R-03), igual a base.
    use_lockfile = true
  }
}
