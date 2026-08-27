# ============================================================
# MODULO MESSAGING - fila SQS e tabela DynamoDB
# ============================================================
# Fluxo do ToggleMaster: o evaluation-service publica um evento na fila
# a cada avaliacao de flag, e o analytics-service consome e grava no
# DynamoDB. A fila existe para desacoplar: se o analytics cair, o
# evaluation continua respondendo rapido no hot path.
# ============================================================

# ------------------------------------------------------------
# Dead-letter queue
# ------------------------------------------------------------
# Nao e exigida pelo enunciado, mas sem ela uma mensagem malformada
# volta para a fila indefinidamente. O analytics-service so apaga a
# mensagem apos gravar no DynamoDB com sucesso, entao uma mensagem que
# sempre falha ficaria em loop eterno consumindo o worker.
# ------------------------------------------------------------

resource "aws_sqs_queue" "dlq" {
  name = "${var.project_name}-events-dlq"

  # 14 dias: tempo de sobra para investigar o que deu errado.
  message_retention_seconds = 1209600

  sqs_managed_sse_enabled = true
}

# ------------------------------------------------------------
# Fila principal (O-08)
# ------------------------------------------------------------

resource "aws_sqs_queue" "events" {
  # Nome identico ao da Fase 2 (F-019): o codigo le a URL por variavel
  # de ambiente, mas manter o nome evita confusao na hora de conferir.
  name = "${var.project_name}-events"

  # 4 dias, igual a Fase 2.
  message_retention_seconds = 345600

  # Tempo que a mensagem fica invisivel apos ser lida. Precisa ser maior
  # que o tempo de processamento do analytics, senao outro worker pega a
  # mesma mensagem antes de o primeiro terminar.
  visibility_timeout_seconds = 30

  # Long polling: reduz chamadas vazias a API e, com isso, custo.
  receive_wait_time_seconds = 20

  sqs_managed_sse_enabled = true

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 5
  })
}

# ------------------------------------------------------------
# Tabela de analytics (O-07)
# ------------------------------------------------------------

resource "aws_dynamodb_table" "analytics" {
  # Nome literal exigido pelo enunciado. Nao alterar.
  name = var.dynamodb_table_name

  # Sob demanda: nao ha trafego previsivel num projeto de estudo, e
  # capacidade provisionada cobraria mesmo com a tabela parada.
  billing_mode = "PAY_PER_REQUEST"

  # Chave confirmada no codigo do analytics-service e no guia da Fase 2.
  hash_key = "event_id"

  attribute {
    name = "event_id"
    type = "S"
  }

  # Criptografia em repouso com chave gerenciada da AWS (S-05).
  server_side_encryption {
    enabled = true
  }

  # Falso de proposito: a estrategia de custo do projeto depende de
  # conseguir rodar terraform destroy entre as sessoes de trabalho.
  deletion_protection_enabled = false
}
