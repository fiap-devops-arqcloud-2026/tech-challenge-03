# ============================================================
# SAIDAS DO MODULO MESSAGING
# ============================================================
# Estes valores so existem depois do apply (a URL da fila inclui o
# numero da conta, por exemplo). Por isso eles sao lidos com
# `terraform output` e usados para preencher os manifestos em gitops/.
# ============================================================

output "queue_url" {
  description = "Valor de AWS_SQS_URL nos servicos evaluation e analytics."

  # .url e o atributo que a AWS devolve apos criar a fila.
  value = aws_sqs_queue.events.url
}

output "queue_arn" {
  description = "ARN da fila. Usado nas policies IRSA da Etapa 2: evaluation recebe SendMessage, analytics recebe ReceiveMessage e DeleteMessage."

  # ARN (Amazon Resource Name) e o identificador global do recurso. Policy
  # IAM trabalha com ARN, nao com URL.
  value = aws_sqs_queue.events.arn
}

output "dlq_url" {
  description = "URL da dead-letter queue, para inspecionar mensagens que falharam."
  value       = aws_sqs_queue.dlq.url
}

output "dlq_arn" {
  description = "ARN da dead-letter queue."
  value       = aws_sqs_queue.dlq.arn
}

output "dynamodb_table_name" {
  description = "Valor de AWS_DYNAMODB_TABLE no analytics-service."

  # Devolve o nome ja confirmado pela AWS, e nao a variavel de entrada.
  # Assim a saida reflete o que existe de fato na conta.
  value = aws_dynamodb_table.analytics.name
}

output "dynamodb_table_arn" {
  description = "ARN da tabela. Usado na policy IRSA do analytics-service na Etapa 2."
  value       = aws_dynamodb_table.analytics.arn
}
