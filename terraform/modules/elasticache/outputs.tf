# ============================================================
# SAIDAS - modulo elasticache
# ============================================================

output "primary_endpoint" {
  description = <<-EOT
    Hostname do no primario. E o que entra no REDIS_URL do
    evaluation-service, no patch de endpoints do overlay prod.
  EOT
  value       = aws_elasticache_replication_group.this.primary_endpoint_address
}

output "redis_url" {
  description = <<-EOT
    URL de conexao ja montada, pronta para o ConfigMap.

    O esquema acompanha a criptografia em transito: com ela desligada
    sai "redis://", com ela ligada sai "rediss://". Assim os dois lados
    nunca divergem - que e justamente o erro que derrubaria o servico no
    boot (ver a variavel transit_encryption_enabled).
  EOT
  value = format(
    "%s://%s:6379",
    var.transit_encryption_enabled ? "rediss" : "redis",
    aws_elasticache_replication_group.this.primary_endpoint_address,
  )
}

output "security_group_id" {
  description = "ID do security group do cache. Util para depurar conectividade."
  value       = aws_security_group.this.id
}
