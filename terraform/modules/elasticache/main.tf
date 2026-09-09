# ============================================================
# MODULO ELASTICACHE - cache Redis do evaluation-service (O-06)
# ============================================================
# O evaluation-service e o caminho quente do ToggleMaster: cada
# avaliacao de flag consulta o cache antes de bater nos servicos de flag
# e targeting. E o unico consumidor deste cluster.
#
# Baseado em terraform/modules/elasticache/ da branch main, com duas
# mudancas:
#   1. o security group libera a origem pelo SG do cluster EKS, e nao
#      pelo CIDR inteiro da VPC - menor privilegio (S-06);
#   2. a criptografia EM TRANSITO virou variavel, desligada por padrao.
#      O motivo esta documentado na variavel: ligar sem trocar o esquema
#      da URL para rediss:// derruba o servico no boot.
# ============================================================

# ------------------------------------------------------------
# BLOCO 1 - REDE
# ------------------------------------------------------------

# Diz ao ElastiCache em quais subnets ele pode colocar o no.
resource "aws_elasticache_subnet_group" "this" {
  name = "${var.name}-redis"
  # Subnets PRIVADAS: o cache nunca deve ser alcancavel da internet.
  subnet_ids = var.subnet_ids
}

# Firewall do cache.
resource "aws_security_group" "this" {
  name        = "${var.name}-redis"
  description = "Acesso Redis restrito aos nos do cluster EKS."
  vpc_id      = var.vpc_id

  ingress {
    description = "Redis vindo apenas dos nos do EKS."
    # 6379 e a porta padrao do Redis.
    from_port = 6379
    to_port   = 6379
    protocol  = "tcp"
    # Origem pelo SECURITY GROUP do cluster, nao por bloco de IPs: so os
    # nos do EKS alcancam o cache, mesmo havendo outros recursos na VPC.
    security_groups = [var.allowed_security_group_id]
  }

  egress {
    description = "Saida liberada para o servico gerenciado operar."
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-redis"
  }
}

# ------------------------------------------------------------
# BLOCO 2 - O CLUSTER DE CACHE
# ------------------------------------------------------------
# Usa replication_group e nao cache_cluster porque e o recurso que
# suporta criptografia. Com num_cache_clusters = 1 ele se comporta como
# um no unico, sem custo de replica.
# ------------------------------------------------------------

resource "aws_elasticache_replication_group" "this" {
  # Identificador na AWS. Vira parte do hostname de conexao.
  replication_group_id = "${var.name}-redis"

  # Campo obrigatorio, aparece no console.
  description = "Cache do evaluation-service do ToggleMaster."

  # Menor tipo disponivel. O cache guarda flags avaliadas, um volume
  # pequeno; memoria nao e o gargalo aqui.
  node_type = var.node_type

  # UM no. Sem replica: o enunciado nao pede alta disponibilidade de
  # cache, e uma replica dobraria o custo por hora.
  num_cache_clusters = 1

  port = 6379

  # Grupo de parametros padrao da linha 7 do Redis.
  parameter_group_name = "default.redis7"

  # Rede dos blocos anteriores.
  subnet_group_name  = aws_elasticache_subnet_group.this.name
  security_group_ids = [aws_security_group.this.id]

  # CRIPTOGRAFIA EM REPOUSO (S-05). Nao afeta o cliente em nada: o
  # servico nem sabe que existe. Ligada sempre.
  at_rest_encryption_enabled = true

  # CRIPTOGRAFIA EM TRANSITO. Vem de variavel, desligada por padrao.
  # Ler o comentario da variavel antes de ligar - exige trocar o
  # esquema da URL no ConfigMap.
  transit_encryption_enabled = var.transit_encryption_enabled

  # Failover automatico desligado: so faz sentido com replica, e nao ha.
  automatic_failover_enabled = false

  tags = {
    Name = "${var.name}-redis"
  }
}
