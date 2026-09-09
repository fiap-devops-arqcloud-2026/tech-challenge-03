# ============================================================
# MODULO RDS - bancos PostgreSQL gerenciados (O-05 parcial)
# ============================================================
# DOIS bancos, nao tres. O enunciado pede 3 instancias RDS, mas esta
# conta esta no plano gratuito novo da AWS, que recusa a terceira com
# "maximum number of instances available with free plan accounts"
# (F-023). O terceiro banco - targeting_db - roda como StatefulSet
# dentro do cluster (D-015), arranjo confirmado com o professor e ja
# usado na Fase 2. Os manifestos estao em gitops/base/postgres-targeting/.
#
# Baseado em terraform/modules/rds/ da branch main, com tres mudancas:
#   1. o security group libera a origem pelo SECURITY GROUP do cluster,
#      e nao pelo CIDR inteiro da VPC - menor privilegio (S-06);
#   2. as senhas vao para o AWS Secrets Manager (S-02, D-013);
#   3. a lista de bancos vem de variavel, ja com apenas dois.
# ============================================================

# ------------------------------------------------------------
# BLOCO 1 - SENHAS
# ------------------------------------------------------------
# Uma senha aleatoria por banco, gerada pelo proprio Terraform. Ninguem
# digita, ninguem escolhe, ninguem comita. E o oposto direto da dor
# descrita no enunciado: "credenciais passadas em arquivos de texto".
# ------------------------------------------------------------

resource "random_password" "db" {
  # Uma senha por entrada do mapa de bancos.
  for_each = var.databases

  # 24 caracteres. Bem acima do minimo do RDS (8).
  length = 24

  # SEM caracteres especiais, de proposito. A senha entra numa URL de
  # conexao (postgres://usuario:senha@host/banco); caracteres como @, /
  # e : quebrariam o parsing da URL e dariam erro de autenticacao
  # dificil de diagnosticar. 24 caracteres alfanumericos ja dao entropia
  # de sobra.
  special = false
}

# ------------------------------------------------------------
# BLOCO 2 - REDE
# ------------------------------------------------------------

# Agrupa as subnets onde o RDS pode colocar a instancia. Exige no minimo
# duas zonas, mesmo sem Multi-AZ.
resource "aws_db_subnet_group" "this" {
  name = "${var.name}-db"
  # Subnets PRIVADAS: o banco nunca deve ter rota para a internet.
  subnet_ids = var.subnet_ids

  tags = {
    Name = "${var.name}-db"
  }
}

# Firewall das instancias.
resource "aws_security_group" "this" {
  name        = "${var.name}-rds"
  description = "Acesso PostgreSQL restrito aos nos do cluster EKS."
  vpc_id      = var.vpc_id

  ingress {
    description = "PostgreSQL vindo apenas dos nos do EKS."
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    # A origem e o SECURITY GROUP do cluster, nao um bloco de IPs. Isso
    # e menor privilegio de verdade: qualquer coisa que nao seja um no
    # do cluster fica de fora, mesmo estando na mesma VPC.
    security_groups = [var.allowed_security_group_id]
  }

  egress {
    description = "Saida liberada: o RDS gerenciado precisa falar com servicos da AWS."
    from_port   = 0
    to_port     = 0
    # "-1" significa qualquer protocolo.
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-rds"
  }
}

# ------------------------------------------------------------
# BLOCO 3 - AS INSTANCIAS
# ------------------------------------------------------------

resource "aws_db_instance" "this" {
  # Uma instancia por entrada do mapa. A chave vira parte do nome; o
  # valor e o nome do banco dentro dela.
  for_each = var.databases

  # Nome da instancia na AWS. Ex.: togglemaster-auth.
  identifier = "${var.name}-${each.key}"

  # Motor e versao. 16 e a mesma linha usada na Fase 2 e no pod do
  # targeting (postgres:16-alpine), evitando divergencia de dialeto.
  engine         = "postgres"
  engine_version = "16"

  # Classe da instancia. db.t3.micro e a menor elegivel ao Free Tier.
  instance_class = var.instance_class

  # Disco inicial em GB. 20 e o minimo aceito pelo RDS.
  allocated_storage = var.allocated_storage

  # Teto do crescimento automatico. Protege contra o disco encher no
  # meio da demonstracao sem virar conta alta.
  max_allocated_storage = var.max_allocated_storage

  # gp3 e mais barato e mais rapido que gp2 para o mesmo tamanho.
  storage_type = "gp3"

  # CRIPTOGRAFIA EM REPOUSO (S-05). Nao pode ser ligada depois: exigiria
  # recriar a instancia e perder os dados.
  storage_encrypted = true

  # Nome do banco criado na inicializacao. Ex.: auth_db, flags_db.
  db_name = each.value

  # Usuario administrador. "toggle" e o mesmo nome da Fase 2 (F-019),
  # para que as URLs de conexao nao precisem mudar.
  username = "toggle"

  # Senha gerada no bloco 1. Nunca aparece em tfvars nem no Git - so no
  # estado, que vive cifrado no S3.
  password = random_password.db[each.key].result

  # Rede: subnets privadas e o firewall do bloco 2.
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.this.id]

  # NAO acessivel pela internet. Combinado com a subnet privada, sao
  # duas barreiras independentes.
  publicly_accessible = false

  # Sem replica em outra zona. Multi-AZ dobraria o custo e o enunciado
  # nao pede alta disponibilidade de banco.
  multi_az = false

  # Sem snapshot final ao destruir. Em projeto que sobe e desce a cada
  # sessao, o snapshot so acumularia custo e tempo de destroy.
  skip_final_snapshot = true

  # Protecao contra delecao DESLIGADA de proposito: com ela ligada, o
  # terraform destroy de fim de sessao falharia (S-09).
  deletion_protection = false

  # Backup minimo. 0 desligaria o backup automatico por completo; 1 dia
  # mantem a funcionalidade ligada sem custo relevante.
  backup_retention_period = var.backup_retention_period

  tags = {
    Name = "${var.name}-${each.key}"
  }
}

# ------------------------------------------------------------
# BLOCO 4 - SEGREDOS NO SECRETS MANAGER (S-02, D-013)
# ------------------------------------------------------------
# A URL de conexao completa e gravada no Secrets Manager. Duas razoes:
#
#   1. E a evidencia para o relatorio (O-38) de que o projeto atacou a
#      dor citada no enunciado - nenhuma credencial em arquivo de texto.
#   2. Da um lugar unico para consultar a senha durante a operacao, sem
#      precisar abrir o estado do Terraform.
#
# Quem entrega isso ao pod NAO e o Secrets Manager: e o Terraform, que
# cria o Secret do Kubernetes direto (D-018, apos o corte do External
# Secrets Operator). O contrato de nomes esta em
# gitops/SECRETS-CONTRATO.md.
# ------------------------------------------------------------

resource "aws_secretsmanager_secret" "db" {
  for_each = var.databases

  # Nome hierarquico, no padrao togglemaster/<servico>-service.
  name = "${var.name}/${each.key}-service"

  description = "Credenciais do banco ${each.value}, geradas pelo Terraform."

  # Zero dias de espera: por padrao o Secrets Manager mantem o segredo
  # por 30 dias apos a delecao, e um nome apagado NAO pode ser reusado
  # nesse periodo. Como este projeto sobe e desce varias vezes, o padrao
  # faria o proximo apply falhar com "already scheduled for deletion".
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "db" {
  for_each = var.databases

  secret_id = aws_secretsmanager_secret.db[each.key].id

  # O valor e um JSON com as partes separadas mais a URL montada.
  # Guardar as partes, e nao so a URL, permite reaproveitar o segredo se
  # algum dia outra ferramenta precisar so do host ou so da senha.
  secret_string = jsonencode({
    username = "toggle"
    password = random_password.db[each.key].result
    # `address` e o hostname puro; `endpoint` traria host:porta junto.
    host   = aws_db_instance.this[each.key].address
    port   = 5432
    dbname = each.value
    # URL pronta, no formato que os servicos esperam em DATABASE_URL.
    DATABASE_URL = format(
      "postgres://toggle:%s@%s:5432/%s",
      random_password.db[each.key].result,
      aws_db_instance.this[each.key].address,
      each.value,
    )
  })
}
