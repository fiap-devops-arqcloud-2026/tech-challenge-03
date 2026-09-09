# ============================================================
# VARIAVEIS DE ENTRADA - modulo elasticache
# ============================================================

variable "name" {
  description = "Prefixo dos nomes. Vira togglemaster-redis."
  type        = string
}

variable "vpc_id" {
  description = "VPC onde o security group do cache e criado."
  type        = string
}

variable "subnet_ids" {
  description = "Subnets PRIVADAS do subnet group do ElastiCache."
  type        = list(string)
}

variable "allowed_security_group_id" {
  description = <<-EOT
    Security group autorizado a abrir conexao na porta 6379. Recebe o SG
    do cluster EKS: so os nos do cluster alcancam o cache (S-06).
  EOT
  type        = string
}

variable "node_type" {
  description = "Tipo do no. cache.t3.micro e o menor disponivel e basta para o volume do projeto."
  type        = string
}

variable "transit_encryption_enabled" {
  description = <<-EOT
    Liga TLS na conexao com o Redis.

    PADRAO false, e a escolha e deliberada. O evaluation-service monta o
    cliente com redis.ParseURL da biblioteca go-redis/v8, que decide
    usar TLS pelo ESQUEMA da URL:

      redis://  -> conexao em texto claro
      rediss:// -> conexao TLS (repare no segundo "s")

    Ligar esta variavel SEM trocar o REDIS_URL do ConfigMap para
    rediss:// faz o servico morrer no boot. O codigo chama log.Fatalf
    quando a conexao inicial falha, entao o pod entra em CrashLoopBackOff
    e nao se recupera sozinho.

    A branch main liga esta opcao, mas o ConfigMap de la continua com
    redis:// - o que so nao quebrou porque o cluster nunca foi aplicado.

    PARA LIGAR, sao dois passos e nesta ordem:
      1. mudar REDIS_URL para rediss:// em
         gitops/overlays/prod/patches/endpoints.yaml;
      2. passar true aqui.

    Deixado desligado por padrao porque criptografia em transito NAO e
    item avaliado, e um erro aqui custaria tempo de uma janela de
    gravacao de 3 horas. A criptografia em repouso, essa sim, fica
    sempre ligada (S-05).
  EOT
  type        = bool
  default     = false
}
