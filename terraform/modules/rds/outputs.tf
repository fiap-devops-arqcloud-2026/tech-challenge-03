# ============================================================
# SAIDAS - modulo rds
# ============================================================

output "endpoints" {
  description = "Mapa <chave do banco> = <hostname>. Ex.: auth = togglemaster-auth.xxxx.us-east-2.rds.amazonaws.com."
  value       = { for k, v in aws_db_instance.this : k => v.address }
}

output "database_urls" {
  description = <<-EOT
    Mapa <chave> = <URL de conexao completa>. E o valor que vai para a
    chave DATABASE_URL do Secret do Kubernetes de cada servico, conforme
    gitops/SECRETS-CONTRATO.md.

    MARCADO COMO SENSITIVE: contem a senha em texto puro. Com isso o
    Terraform imprime "(sensitive value)" no plan e no apply em vez de
    despejar a senha no terminal - e no log da gravacao do video.
  EOT
  value = {
    for k, v in aws_db_instance.this :
    k => format(
      "postgres://toggle:%s@%s:5432/%s",
      random_password.db[k].result,
      v.address,
      var.databases[k],
    )
  }
  sensitive = true
}

output "security_group_id" {
  description = "ID do security group das instancias. Util para depurar conectividade."
  value       = aws_security_group.this.id
}

output "secret_arns" {
  description = "ARNs dos segredos no Secrets Manager, um por banco. Evidencia para o relatorio (O-38)."
  value       = { for k, v in aws_secretsmanager_secret.db : k => v.arn }
}
