# ============================================================
# MODULO IRSA - identidade dos pods sem chave de acesso (S-06)
# ============================================================
# IRSA significa "IAM Roles for Service Accounts". A ideia em uma frase:
# em vez de guardar AWS_ACCESS_KEY_ID num Secret do Kubernetes, o pod
# recebe um TOKEN de identidade assinado pelo cluster e o troca por
# credencial temporaria da AWS.
#
# Como funciona, passo a passo:
#   1. a ServiceAccount do pod ganha a anotacao eks.amazonaws.com/role-arn;
#   2. ao criar o pod, o EKS injeta nele um token OIDC e as variaveis
#      que o SDK da AWS procura;
#   3. o SDK chama sts:AssumeRoleWithWebIdentity com esse token;
#   4. a AWS confere a assinatura contra o provedor OIDC do cluster e
#      devolve credencial temporaria, que expira e se renova sozinha.
#
# Nenhuma chave em lugar nenhum. Isso ataca de frente o que a Fase 2
# fazia (F-017: chaves estaticas dentro de um Secret) e o que o
# enunciado descreve como a dor a resolver.
#
# ATENCAO AOS NOMES: as roles precisam se chamar exatamente
# togglemaster-evaluation-irsa e togglemaster-analytics-irsa, porque
# gitops/overlays/prod/patches/irsa.yaml ja referencia esses ARNs. Mudar
# aqui sem mudar la faz o pod subir sem permissao nenhuma.
# ============================================================

# ------------------------------------------------------------
# BLOCO 1 - POLITICA DE CONFIANCA, GERADA POR SERVICO
# ------------------------------------------------------------
# Cada role so pode ser assumida por UMA ServiceAccount, em UM
# namespace. Sem essa amarracao, qualquer pod do cluster poderia assumir
# qualquer role - e o menor privilegio viraria ficcao.
# ------------------------------------------------------------

data "aws_iam_policy_document" "assume" {
  # Um documento por servico do mapa recebido.
  for_each = var.service_accounts

  statement {
    # Acao especifica do IRSA. Note o sufixo WithWebIdentity: nao e o
    # sts:AssumeRole comum, e sim a troca de um token OIDC.
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      # "Federated" = a identidade vem de um provedor externo, neste caso
      # o provedor OIDC do proprio cluster EKS.
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test = "StringEquals"
      # "sub" (subject) identifica QUEM esta pedindo. O formato do EKS e
      # system:serviceaccount:<namespace>:<nome-da-serviceaccount>.
      variable = "${var.oidc_provider_url}:sub"
      values   = ["system:serviceaccount:${var.namespace}:${each.value.service_account}"]
    }

    condition {
      test = "StringEquals"
      # "aud" (audience) confirma que o token foi emitido PARA o STS.
      # Sem esta condicao, um token gerado para outro destino poderia ser
      # reaproveitado aqui.
      variable = "${var.oidc_provider_url}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

# ------------------------------------------------------------
# BLOCO 2 - AS ROLES
# ------------------------------------------------------------

resource "aws_iam_role" "this" {
  for_each = var.service_accounts

  # Nome final: togglemaster-evaluation-irsa / togglemaster-analytics-irsa.
  # Precisa bater com o patch do overlay (ver cabecalho).
  name = "${var.name}-${each.key}-irsa"

  description        = "Role IRSA do pod ${each.value.service_account}, sem chave estatica."
  assume_role_policy = data.aws_iam_policy_document.assume[each.key].json
}

# ------------------------------------------------------------
# BLOCO 3 - PERMISSOES DO EVALUATION-SERVICE
# ------------------------------------------------------------
# Ele PRODUZ eventos: publica na fila e nada mais. Nao le, nao apaga,
# nao toca no DynamoDB.
# ------------------------------------------------------------

data "aws_iam_policy_document" "evaluation" {
  statement {
    sid    = "PublicarEventosNaFila"
    effect = "Allow"
    actions = [
      # Enviar mensagem: a unica escrita que este servico faz.
      "sqs:SendMessage",
      # Resolver a URL da fila a partir do nome. O SDK usa em alguns
      # caminhos mesmo quando a URL vem por variavel de ambiente.
      "sqs:GetQueueUrl",
      # Ler atributos da fila. Somente leitura de metadados.
      "sqs:GetQueueAttributes",
    ]
    # Restrito a NOSSA fila. Sem "*": o servico nao enxerga outras filas
    # da conta, nem as que existirem no futuro.
    resources = [var.sqs_queue_arn]
  }
}

resource "aws_iam_policy" "evaluation" {
  name        = "${var.name}-evaluation-irsa"
  description = "Permite ao evaluation-service publicar na fila de eventos do ToggleMaster."
  policy      = data.aws_iam_policy_document.evaluation.json
}

resource "aws_iam_role_policy_attachment" "evaluation" {
  role       = aws_iam_role.this["evaluation"].name
  policy_arn = aws_iam_policy.evaluation.arn
}

# ------------------------------------------------------------
# BLOCO 4 - PERMISSOES DO ANALYTICS-SERVICE
# ------------------------------------------------------------
# Ele CONSOME eventos: le da fila, apaga o que processou e grava no
# DynamoDB. Repare que NAO tem sqs:SendMessage - um consumidor nao
# precisa publicar, e separar isso e o que torna o menor privilegio
# visivel na avaliacao (S-06).
# ------------------------------------------------------------

data "aws_iam_policy_document" "analytics" {
  statement {
    sid    = "ConsumirEventosDaFila"
    effect = "Allow"
    actions = [
      # Ler mensagens da fila.
      "sqs:ReceiveMessage",
      # Apagar a mensagem depois de processada. Sem isto a mensagem
      # voltaria a ficar visivel e seria processada de novo em laco.
      "sqs:DeleteMessage",
      "sqs:GetQueueUrl",
      "sqs:GetQueueAttributes",
    ]
    resources = [var.sqs_queue_arn]
  }

  statement {
    sid    = "GravarNaTabelaDeAnalytics"
    effect = "Allow"
    actions = [
      # Inserir um item. E a unica escrita que o worker faz.
      "dynamodb:PutItem",
      # Inserir varios de uma vez, caso o codigo agrupe.
      "dynamodb:BatchWriteItem",
    ]
    # Restrito a tabela ToggleMasterAnalytics. Nao ha permissao de
    # leitura, de Scan nem de delecao: o worker so escreve.
    resources = [var.dynamodb_table_arn]
  }
}

resource "aws_iam_policy" "analytics" {
  name        = "${var.name}-analytics-irsa"
  description = "Permite ao analytics-service consumir a fila e gravar na tabela de analytics."
  policy      = data.aws_iam_policy_document.analytics.json
}

resource "aws_iam_role_policy_attachment" "analytics" {
  role       = aws_iam_role.this["analytics"].name
  policy_arn = aws_iam_policy.analytics.arn
}
