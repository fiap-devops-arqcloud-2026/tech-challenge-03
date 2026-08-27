# ============================================================
# LEITURA DO ESTADO DA CAMADA BASE
# ============================================================
# Esta camada precisa saber em qual VPC criar o cluster, em quais
# subnets colocar os nos e os bancos, e qual o ARN da fila e da tabela
# para montar as policies IRSA.
#
# Esses valores foram criados pela camada base e vivem no estado dela.
# O data source terraform_remote_state LE aquele estado, sem alterar
# nada. E somente leitura.
#
# Por que nao duplicar os valores em variaveis: se a base mudar o CIDR
# de uma subnet, aqui acompanharia sozinho. Copiar a mao criaria duas
# fontes da verdade que divergem silenciosamente.
# ============================================================

data "terraform_remote_state" "base" {
  # Mesmo tipo de backend da camada base.
  backend = "s3"

  # Aponta para o MESMO bucket, mas para a chave da base.
  config = {
    bucket = "togglemaster-tfstate-891376952395-us-east-2-an"
    key    = "prod/base.tfstate"
    region = "us-east-2"
  }
}

# ------------------------------------------------------------
# Atalhos para as saidas da base
# ------------------------------------------------------------
# Sem isto, cada uso viraria
# data.terraform_remote_state.base.outputs.vpc_id - longo e ruidoso.
# ------------------------------------------------------------

locals {
  # Identificador da VPC criada pela base.
  vpc_id = data.terraform_remote_state.base.outputs.vpc_id

  # Subnets privadas: onde entram os nos do EKS, os RDS e o ElastiCache.
  private_subnet_ids = data.terraform_remote_state.base.outputs.private_subnet_ids

  # Subnets publicas: so o NAT mora la. Nenhum recurso desta camada usa,
  # mas fica disponivel caso o EKS precise de endpoint publico.
  public_subnet_ids = data.terraform_remote_state.base.outputs.public_subnet_ids

  # ARN da fila SQS. Usado na policy IRSA do evaluation (SendMessage) e
  # do analytics (ReceiveMessage e DeleteMessage).
  sqs_queue_arn = data.terraform_remote_state.base.outputs.sqs_queue_arn

  # ARN da tabela DynamoDB. Usado na policy IRSA do analytics (PutItem).
  dynamodb_table_arn = data.terraform_remote_state.base.outputs.dynamodb_table_arn
}
