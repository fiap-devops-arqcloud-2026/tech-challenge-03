# ============================================================
# VARIAVEIS DE ENTRADA
# ============================================================
# Toda variavel tem `default`, entao o projeto roda sem nenhum tfvars.
# O terraform.tfvars.example existe para deixar explicito o que da para
# ajustar - principalmente o enable_nat_gateway, que mexe no custo.
# ============================================================

# ------------------------------------------------------------
# Identidade do projeto
# ------------------------------------------------------------

variable "aws_region" {
  # `description` aparece no terraform plan e na documentacao gerada.
  description = "Regiao AWS onde toda a infraestrutura e criada. Mesma regiao da Fase 2 (F-012)."

  # Tipo de dado esperado. O Terraform recusa qualquer outro valor.
  type = string

  # Valor usado quando ninguem informa nada.
  default = "us-east-2"
}

variable "project_name" {
  # Sintaxe <<-EOT: texto de varias linhas com a indentacao removida.
  description = <<-EOT
    Prefixo dos nomes de recurso. Mantido como "togglemaster" de proposito:
    a fila e o cache da Fase 2 ja usavam esse prefixo, e o codigo dos servicos
    le esses nomes por variavel de ambiente (F-019). Mudar aqui obriga a mudar
    tambem os manifestos em gitops/.
  EOT
  type        = string
  default     = "togglemaster"
}

variable "default_tags" {
  description = "Tags aplicadas a todo recurso criado por este Terraform (D-009)."

  # map(string) = dicionario de chave/valor, ambos texto.
  type = map(string)

  # ATENCAO: chave de tag na AWS e sensivel a maiuscula/minuscula.
  # Estas estao em minusculo porque foi assim que o bucket de estado foi
  # criado manualmente. Se divergir, o Cost Explorer mostra dois grupos
  # separados e a soma de custo do projeto fica errada.
  default = {
    project = "fiap"
    phase   = "3"
  }
}

# ------------------------------------------------------------
# Rede
# ------------------------------------------------------------

variable "vpc_cidr" {
  description = "Bloco CIDR da VPC. /16 da 65.536 enderecos, folga de sobra para as 4 subnets."
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = <<-EOT
    Duas AZs, no minimo. Nao e escolha estetica: o EKS exige subnets em pelo
    menos duas zonas, e o DB subnet group do RDS tambem.
  EOT

  # list(string) = lista ordenada de textos.
  type    = list(string)
  default = ["us-east-2a", "us-east-2b"]
}

variable "private_subnet_cidrs" {
  description = "Subnets privadas: nos do EKS, RDS e ElastiCache. Nada aqui recebe IP publico."
  type        = list(string)

  # /24 = 256 enderecos por subnet. A ordem casa com availability_zones:
  # o primeiro CIDR vai para a primeira AZ, e assim por diante.
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "public_subnet_cidrs" {
  description = "Subnets publicas: apenas o NAT Gateway. Nao ha Load Balancer no projeto (D-012)."
  type        = list(string)

  # Faixa .101 e .102 so para separar visualmente das privadas nos logs.
  default = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "enable_nat_gateway" {
  description = <<-EOT
    O NAT Gateway custa cerca de US$ 33/mes e so e necessario quando existe algo
    rodando em subnet privada, ou seja, a partir da Etapa 2 (EKS, RDS, Redis).
    Durante a Etapa 1 mantenha false no seu terraform.tfvars para nao pagar por
    um recurso ocioso. O padrao e true para nao deixar o cluster sem saida por
    esquecimento.
  EOT

  # bool = true ou false.
  type    = bool
  default = true
}

# ------------------------------------------------------------
# Aplicacao
# ------------------------------------------------------------

variable "services" {
  description = "Os 5 microsservicos do ToggleMaster. Cada item vira um repositorio ECR <servico>-service."
  type        = list(string)

  # Nomes curtos. O sufixo "-service" e adicionado dentro do modulo de ECR,
  # para bater com o que os deployments da Fase 2 ja referenciam (F-019).
  default = ["auth", "flag", "targeting", "evaluation", "analytics"]
}

variable "dynamodb_table_name" {
  description = "Nome literal exigido pelo enunciado (F-009). Nao alterar."
  type        = string

  # O enunciado cita o nome com estas maiusculas exatas. Mudar quebra o requisito.
  default = "ToggleMasterAnalytics"
}

variable "ecr_image_tag_mutability" {
  description = <<-EOT
    MUTABLE permite reenviar a mesma tag. IMMUTABLE e a opcao endurecida e
    combina com tags por commit hash, mas faz falhar qualquer re-execucao do
    workflow sobre o mesmo commit - situacao comum durante a gravacao do video.
    Comeca em MUTABLE; trocar para IMMUTABLE e uma linha.
  EOT
  type        = string
  default     = "MUTABLE"

  # Bloco validation: barra valores invalidos ainda no plan, com mensagem
  # clara, em vez de deixar a API da AWS recusar durante o apply.
  validation {
    # Condicao que precisa ser verdadeira para o valor ser aceito.
    condition = contains(["MUTABLE", "IMMUTABLE"], var.ecr_image_tag_mutability)

    # Mensagem exibida quando a condicao falha.
    error_message = "Use MUTABLE ou IMMUTABLE."
  }
}

variable "ecr_images_to_keep" {
  description = "Quantas imagens manter por repositorio. As mais antigas expiram para conter custo."

  # number = numerico.
  type = number

  # 10 e suficiente para voltar algumas versoes sem acumular lixo indefinidamente.
  default = 10
}

# ------------------------------------------------------------
# CI
# ------------------------------------------------------------

variable "github_repository" {
  description = <<-EOT
    Repositorio autorizado a assumir a role do CI via OIDC, no formato owner/repo.
    Qualquer outro repositorio recebe AccessDenied, mesmo dentro da mesma organizacao.
  EOT
  type        = string

  # Confirmado em 2026-08-27 pelo `git remote -v` deste repositorio.
  default = "fiap-devops-arqcloud-2026/tech-challenge-03"
}
