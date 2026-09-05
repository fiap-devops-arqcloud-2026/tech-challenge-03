output "eks_cluster_name" { value = module.eks.cluster_name }
output "ecr_repository_urls" { value = module.ecr.repository_urls }
output "rds_endpoints" { value = module.rds.endpoints }
output "redis_endpoint" { value = module.elasticache.primary_endpoint }
output "sqs_queue_url" { value = module.sqs.queue_url }
output "dynamodb_table" { value = module.dynamodb.table_name }

output "database_passwords" {
  value       = module.rds.passwords
  sensitive   = true
  description = "Recupere somente quando for criar Secrets; nunca salve em arquivos versionados."
}

