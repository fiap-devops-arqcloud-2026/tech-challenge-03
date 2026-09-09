# ============================================================
# MODULO MESSAGING - fila SQS e tabela DynamoDB
# ============================================================
# Fluxo do ToggleMaster: o evaluation-service publica um evento na fila
# a cada avaliacao de flag, e o analytics-service consome e grava no
# DynamoDB. A fila existe para desacoplar: se o analytics cair, o
# evaluation continua respondendo rapido no hot path.
# ============================================================

# ------------------------------------------------------------
# Dead-letter queue (fila de mensagens mortas)
# ------------------------------------------------------------
# Nao e exigida pelo enunciado, mas sem ela uma mensagem malformada
# volta para a fila indefinidamente. O analytics-service so apaga a
# mensagem apos gravar no DynamoDB com sucesso, entao uma mensagem que
# sempre falha ficaria em loop eterno consumindo o worker.
#
# Precisa ser declarada ANTES da fila principal, porque a principal
# referencia o ARN dela.
# ------------------------------------------------------------

resource "aws_sqs_queue" "dlq" {

  # Sufixo -dlq deixa obvio no console qual e a fila de descarte.
  name = "${var.project_name}-events-dlq"

  # 14 dias em segundos (60*60*24*14). E o maximo que a SQS permite e da
  # tempo de sobra para investigar o que deu errado antes de a mensagem sumir.
  message_retention_seconds = 1209600

  # Criptografia em repouso com chave gerenciada pela propria SQS, sem
  # custo adicional (S-05). A alternativa seria KMS, que cobra por requisicao.
  sqs_managed_sse_enabled = true
}

# ------------------------------------------------------------
# Fila principal (O-08)
# ------------------------------------------------------------

resource "aws_sqs_queue" "events" {

  # Nome identico ao da Fase 2 (F-019). O codigo le a URL por variavel de
  # ambiente, mas manter o nome evita confusao ao conferir no console.
  name = "${var.project_name}-events"

  # 4 dias em segundos (60*60*24*4), igual a Fase 2.
  message_retention_seconds = 345600

  # Tempo que a mensagem fica invisivel para outros consumidores depois de
  # ser lida. Precisa ser MAIOR que o tempo de processamento do analytics,
  # senao um segundo worker pega a mesma mensagem antes de o primeiro
  # terminar, e o evento e gravado duas vezes.
  visibility_timeout_seconds = 30

  # Long polling: a chamada de leitura espera ate 20s por uma mensagem em
  # vez de responder vazio na hora. Reduz chamadas a API e, com isso, custo.
  receive_wait_time_seconds = 20

  sqs_managed_sse_enabled = true

  # Politica de redirecionamento para a DLQ. A API espera JSON, entao
  # jsonencode() converte a estrutura HCL.
  redrive_policy = jsonencode({

    # Para onde a mensagem vai quando desiste. Referenciar o recurso aqui
    # tambem informa ao Terraform que a DLQ precisa existir antes.
    deadLetterTargetArn = aws_sqs_queue.dlq.arn

    # Quantas vezes a mensagem pode ser lida sem ser apagada antes de ser
    # considerada "envenenada" e movida para a DLQ.
    maxReceiveCount = 5
  })
}

# ------------------------------------------------------------
# Tabela de analytics (O-07)
# ------------------------------------------------------------

resource "aws_dynamodb_table" "analytics" {

  # Nome literal exigido pelo enunciado (F-009). Nao alterar.
  name = var.dynamodb_table_name

  # Cobranca por requisicao, sem capacidade reservada. Nao ha trafego
  # previsivel num projeto de estudo, e capacidade provisionada cobraria
  # 24h por dia mesmo com a tabela parada.
  billing_mode = "PAY_PER_REQUEST"

  # Chave de particao. Confirmada em duas fontes independentes: o
  # put_item do analytics-service e o GUIA-AWS.md da Fase 2.
  hash_key = "event_id"

  # O DynamoDB so exige declarar os atributos que fazem parte de alguma
  # chave ou indice. Os demais campos do evento sao gravados livremente.
  attribute {
    name = "event_id"

    # "S" = String. As outras opcoes sao "N" (numero) e "B" (binario).
    type = "S"
  }

  # Criptografia em repouso com chave gerenciada da AWS (S-05).
  server_side_encryption {
    enabled = true
  }

  # Falso de proposito: a estrategia de custo do projeto depende de
  # conseguir rodar terraform destroy entre as sessoes de trabalho. Com
  # protecao ligada, o destroy falharia nesta tabela.
  deletion_protection_enabled = false
}
