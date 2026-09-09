# ============================================================
# BACKEND E VERSOES - CAMADA K8S (objetos dentro do cluster)
# ============================================================
# TERCEIRA e ultima camada do projeto. Enquanto as duas anteriores
# criam recursos NA AWS, esta cria objetos DENTRO do cluster: os Secrets
# das aplicacoes, a StorageClass padrao e o ArgoCD.
#
# POR QUE UMA CAMADA SEPARADA, e nao tudo em terraform/cluster/
# ------------------------------------------------------------
# Os providers kubernetes e helm precisam do endereco e do certificado
# do cluster para se configurar. Se estivessem na mesma raiz que cria o
# cluster, o Terraform teria de configurar o provider com valores que so
# existem DEPOIS do apply - e falha no plan com "Provider configuration
# cannot be evaluated".
#
# Separando, o problema desaparece: quando esta camada roda, o cluster ja
# existe e seus dados vem prontos do estado da camada anterior.
#
# ORDEM OBRIGATORIA DE APLICACAO
#   1. terraform -chdir=terraform         apply   (base, permanente)
#   2. terraform -chdir=terraform/cluster apply   (EKS, RDS, Redis)
#   3. terraform -chdir=terraform/k8s     apply   (ESTA camada)
#   4. ... trabalho / gravacao ...
#   5. terraform -chdir=terraform/k8s     destroy
#   6. terraform -chdir=terraform/cluster destroy
#
# O destroy segue a ordem inversa. Na pratica, destruir o cluster (passo
# 6) leva junto tudo que esta dentro dele, mas rodar o passo 5 antes
# mantem o estado coerente e evita recurso orfao no proximo apply.
# ============================================================

terraform {
  # Mesma exigencia das outras camadas.
  required_version = ">= 1.11.0"

  required_providers {
    # Ainda necessario: esta camada le segredos do Secrets Manager.
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.46"
    }

    # Cria os Secrets, o namespace do ArgoCD e a StorageClass.
    kubernetes = {
      source = "hashicorp/kubernetes"
      # Travado na linha 3.x, e nao ">= 2.30". Motivo: entre a 2 e a 3 os
      # recursos sem sufixo (kubernetes_secret) foram depreciados em favor
      # dos com _v1, e o codigo aqui ja usa os novos. Um ">= " sem teto
      # deixaria um v4 futuro entrar sozinho e quebrar sem aviso.
      version = "~> 3.0"
    }

    # Instala o ArgoCD a partir do chart oficial (O-23).
    helm = {
      source = "hashicorp/helm"
      # Travado na linha 3.x pelo mesmo motivo: na 3 o "kubernetes" do
      # provider virou ATRIBUTO em vez de bloco, e providers.tf ja usa a
      # sintaxe nova. Com a 2.x instalada, o validate falharia.
      version = "~> 3.0"
    }

    # Gera a MASTER_KEY do auth-service e a SERVICE_API_KEY provisoria.
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5"
    }
  }

  backend "s3" {
    # Mesmo bucket das outras camadas.
    bucket = "togglemaster-tfstate-891376952395-us-east-2-an"

    # Terceira chave, terceiro estado independente.
    key = "prod/k8s.tfstate"

    region  = "us-east-2"
    encrypt = true

    # Lock nativo do S3 (R-03).
    use_lockfile = true
  }
}
