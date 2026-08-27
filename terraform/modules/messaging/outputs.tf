output "queue_url" {
  description = "URL da fila. E o valor de AWS_SQS_URL nos servicos evaluation e analytics."
  value       = aws_sqs_queue.events.url
}

output "queue_arn" {
  description = "ARN da fila principal. Usado nas policies IRSA do evaluation (SendMessage) e do analytics (Receive/Delete)."
  value       = aws_sqs_queue.events.arn
}

output "dlq_url" {
  description = "URL da dead-letter queue."
  value       = aws_sqs_queue.dlq.url
}

output "dlq_arn" {
  description = "ARN da dead-letter queue."
  value       = aws_sqs_queue.dlq.arn
}

output "dynamodb_table_name" {
  description = "Nome da tabela. E o valor de AWS_DYNAMODB_TABLE no analytics-service."
  value       = aws_dynamodb_table.analytics.name
}

output "dynamodb_table_arn" {
  description = "ARN da tabela. Usado na policy IRSA do analytics-service."
  value       = aws_dynamodb_table.analytics.arn
}
