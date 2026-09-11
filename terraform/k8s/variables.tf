# ============================================================
# VARIAVEIS DE ENTRADA - camada k8s
# ============================================================

variable "aws_region" {
  description = "Regiao AWS. Precisa ser a mesma das outras camadas (F-012)."
  type        = string
  default     = "us-east-2"
}

variable "project_name" {
  description = "Prefixo dos nomes. Mesmo valor das outras camadas."
  type        = string
  default     = "togglemaster"
}

variable "default_tags" {
  description = "Tags aplicadas a todo recurso AWS desta camada (D-009), em minusculas."
  type        = map(string)
  default = {
    project = "fiap"
    phase   = "3"
  }
}

variable "app_namespace" {
  description = <<-EOT
    Namespace das aplicacoes. Precisa bater com o declarado em
    gitops/base/kustomization.yaml e com o usado nas politicas de
    confianca do IRSA - hoje "togglemaster" (F-019).
  EOT
  type        = string
  default     = "togglemaster"
}

# ------------------------------------------------------------
# ArgoCD
# ------------------------------------------------------------

variable "argocd_namespace" {
  description = "Namespace do ArgoCD. Separado do das aplicacoes, como o chart oficial recomenda."
  type        = string
  default     = "argocd"
}

variable "argocd_chart_version" {
  description = <<-EOT
    Versao do chart argo-cd do repositorio argoproj/argo-helm.

    FIXA de proposito: com a versao em aberto, um apply feito na semana
    da gravacao poderia trazer uma release nova e mudar o comportamento
    sem ninguem pedir.
  EOT
  type        = string
  default     = "7.7.11"
}

variable "gitops_repo_url" {
  description = <<-EOT
    Repositorio que o ArgoCD observa (O-25). E o proprio monorepo: a
    area GitOps e a pasta gitops/, conforme o enunciado permite
    (O-22 e R-07).
  EOT
  type        = string
  default     = "https://github.com/fiap-devops-arqcloud-2026/tech-challenge-03.git"
}

variable "gitops_repo_path" {
  description = "Pasta observada dentro do repositorio. E o overlay do unico ambiente (D-011)."
  type        = string
  default     = "gitops/overlays/prod"
}

variable "gitops_repo_branch" {
  description = <<-EOT
    Branch observada. E a `main` porque e nela que o job `gitops` do CI
    comita a nova tag da imagem (O-24). Apontar para outra branch faria
    o ArgoCD nunca ver a atualizacao publicada pelo pipeline.
  EOT
  type        = string
  default     = "main"
}

variable "github_token" {
  description = <<-EOT
    Token de leitura do repositorio, para o ArgoCD conseguir clonar.

    NECESSARIO ENQUANTO O REPOSITORIO FOR PRIVADO. O grupo decidiu
    manter o repo privado ate a entrega (F-014), e um repositorio
    privado exige credencial: sem ela o ArgoCD mostra o erro
    "authentication required" e a Application nunca sincroniza.

    COMO PASSAR SEM COMITAR NADA - preferir a variavel de ambiente:

        $env:TF_VAR_github_token = "github_pat_xxxx"   (PowerShell)
        export TF_VAR_github_token=github_pat_xxxx     (Git Bash)

    O Terraform le TF_VAR_<nome> automaticamente. Um terraform.tfvars
    tambem funciona e esta protegido pelo .gitignore (`*.tfvars`), mas a
    variavel de ambiente nao deixa o valor em disco.

    O token precisa APENAS de leitura de conteudo do repositorio. Um
    fine-grained token com permissao "Contents: Read-only" basta.

    ATENCAO: o repositorio pertence a uma ORGANIZACAO. Ao criar o token,
    o campo "Resource owner" precisa apontar para a organizacao, e nao
    para a conta pessoal - com o dono errado o token e criado sem erro e
    so falha na hora de clonar. Passo a passo no RUNBOOK-SESSAO.md,
    FASE 0.

    Deixe vazio se o repositorio for publico: neste caso o bloco de
    credencial nem e criado.
  EOT
  type        = string
  default     = ""
  # Impede que o valor apareca no plan, no apply e nos outputs.
  sensitive = true
}

# ------------------------------------------------------------
# Armazenamento
# ------------------------------------------------------------

variable "storage_class_name" {
  description = <<-EOT
    Nome da StorageClass padrao criada por esta camada.

    Precisa ser IDENTICO ao storageClassName declarado no
    volumeClaimTemplates de gitops/base/postgres-targeting/statefulset.yaml.
    Divergencia deixa o PVC em Pending para sempre - foi o que travou a
    Fase 2 (F-025).
  EOT
  type        = string
  default     = "gp3"
}
