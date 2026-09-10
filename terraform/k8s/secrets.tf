# ============================================================
# SECRETS DAS APLICACOES (D-018)
# ============================================================
# ESTE ARQUIVO FECHA A LACUNA MAIS GRAVE DO PROJETO.
#
# Ao cortar o External Secrets Operator (D-018), os 5 arquivos
# externalsecret.yaml sairam de gitops/base/. O plano era o Terraform
# passar a criar os Secrets - mas esse codigo nunca foi escrito, e a
# auditoria de 2026-09-09 mostrou que os pods referenciavam Secrets que
# NINGUEM criava. Todos os 5 servicos ficariam em
# CreateContainerConfigError e nada subiria.
#
# O contrato de nomes e chaves esta em gitops/SECRETS-CONTRATO.md.
# Qualquer alteracao aqui precisa ser refletida la, e vice-versa.
#
# DE ONDE VEM CADA VALOR
#   - DATABASE_URL de auth e flag: do estado da camada cluster, montado
#     pelo modulo rds a partir de random_password;
#   - DATABASE_URL do targeting: montado aqui, porque aponta para o
#     Service interno do banco em pod, nao para um endpoint da AWS;
#   - POSTGRES_USER / POSTGRES_PASSWORD: a MESMA senha usada no
#     DATABASE_URL do targeting (ver o alerta no bloco 2);
#   - MASTER_KEY e SERVICE_API_KEY: geradas aqui.
# ============================================================

# ------------------------------------------------------------
# BLOCO 1 - NAMESPACE
# ------------------------------------------------------------
# Criado aqui, e nao so no gitops/, por uma questao de ordem: os Secrets
# precisam de um namespace existente, e o namespace do gitops/ so nasce
# quando o ArgoCD sincroniza - o que acontece DEPOIS.
#
# Os rotulos sao identicos aos de gitops/base/namespace.yaml de
# proposito. Assim, quando o ArgoCD encontrar o namespace ja existente,
# ele o adota como esta em vez de marcar OutOfSync e ficar corrigindo.
# ------------------------------------------------------------

resource "kubernetes_namespace_v1" "app" {
  metadata {
    name = var.app_namespace

    labels = {
      # Mesmo rotulo do manifesto da base.
      "app.kubernetes.io/part-of" = "togglemaster"
    }
  }
}

# ------------------------------------------------------------
# BLOCO 2 - SENHAS GERADAS NESTA CAMADA
# ------------------------------------------------------------

# Senha do banco do targeting, que roda em pod (D-015).
#
# ATENCAO - O PONTO MAIS FACIL DE ERRAR DO PROJETO INTEIRO:
# esta MESMA senha e usada em dois lugares. O StatefulSet a le em
# POSTGRES_PASSWORD para CRIAR o usuario do banco; o targeting-service a
# le dentro do DATABASE_URL para CONECTAR. Gerar duas senhas diferentes
# faz o servico subir normalmente e falhar na conexao com
# "password authentication failed" - erro que so aparece em execucao.
resource "random_password" "targeting_db" {
  length = 24
  # Sem caracteres especiais: a senha entra numa URL de conexao, e @, /
  # ou : quebrariam o parsing.
  special = false
}

# Chave administrativa do auth-service. Usada apenas para criar chaves
# de API via POST /admin/keys.
resource "random_password" "master_key" {
  length  = 32
  special = false
}

# Chave de API que o evaluation-service usa para falar com os demais.
#
# LIMITACAO CONHECIDA: na Fase 2 esta chave nao e escolhida, e sim
# CRIADA pelo auth-service em POST /admin/keys, que devolve o valor.
# O valor gerado aqui serve para o pod subir com a variavel preenchida,
# mas as chamadas autenticadas so passam a funcionar depois do seed
# (P-034), que precisa criar a chave no auth-service e atualizar este
# Secret com o valor devolvido.
resource "random_password" "service_api_key" {
  length  = 32
  special = false
}

# ------------------------------------------------------------
# BLOCO 3 - SECRET DO AUTH-SERVICE
# ------------------------------------------------------------

resource "kubernetes_secret_v1" "auth" {
  metadata {
    # Precisa bater com o secretKeyRef.name do deployment.
    name      = "auth-service-secret"
    namespace = kubernetes_namespace_v1.app.metadata[0].name

    labels = {
      app = "auth-service"
    }
  }

  # As chaves aqui viram as chaves do Secret. O provider cuida da
  # codificacao base64 exigida pelo Kubernetes.
  data = {
    # URL vinda do modulo rds, ja com host, senha e nome do banco.
    DATABASE_URL = local.database_urls["auth"]

    # Chave administrativa gerada no bloco 2.
    MASTER_KEY = random_password.master_key.result
  }

  # Opaque e o tipo generico, para dado arbitrario.
  type = "Opaque"
}

# ------------------------------------------------------------
# BLOCO 4 - SECRET DO FLAG-SERVICE
# ------------------------------------------------------------

resource "kubernetes_secret_v1" "flag" {
  metadata {
    name      = "flag-service-secret"
    namespace = kubernetes_namespace_v1.app.metadata[0].name

    labels = {
      app = "flag-service"
    }
  }

  data = {
    # Segundo banco RDS. Note a chave "flag" no mapa, que casa com
    # var.rds_databases da camada cluster.
    DATABASE_URL = local.database_urls["flag"]
  }

  type = "Opaque"
}

# ------------------------------------------------------------
# BLOCO 5 - SECRET DO TARGETING-SERVICE
# ------------------------------------------------------------
# O unico cujo host NAO e um endpoint da AWS: aponta para o Service
# interno do banco em pod. O nome "postgres-targeting" e resolvido pelo
# DNS do cluster (CoreDNS).
# ------------------------------------------------------------

resource "kubernetes_secret_v1" "targeting" {
  metadata {
    name      = "targeting-service-secret"
    namespace = kubernetes_namespace_v1.app.metadata[0].name

    labels = {
      app = "targeting-service"
    }
  }

  data = {
    # Montada aqui, com a senha do bloco 2. O host e o nome do Service,
    # a porta e a padrao do PostgreSQL e o banco e targeting_db (F-019).
    DATABASE_URL = format(
      "postgres://toggle:%s@postgres-targeting:5432/targeting_db",
      random_password.targeting_db.result,
    )
  }

  type = "Opaque"
}

# ------------------------------------------------------------
# BLOCO 6 - SECRET DO BANCO EM POD
# ------------------------------------------------------------
# Consumido pelo StatefulSet postgres-targeting na inicializacao, para
# criar o usuario e definir a senha do banco.
# ------------------------------------------------------------

resource "kubernetes_secret_v1" "postgres_targeting" {
  metadata {
    name      = "postgres-targeting-secret"
    namespace = kubernetes_namespace_v1.app.metadata[0].name

    labels = {
      app = "postgres-targeting"
    }
  }

  data = {
    # Mesmo usuario da Fase 2 e dos bancos RDS (F-019).
    POSTGRES_USER = "toggle"

    # A MESMA senha usada no DATABASE_URL do bloco 5. Repare que as duas
    # referenciam random_password.targeting_db - e isso que garante que
    # nao divirjam.
    POSTGRES_PASSWORD = random_password.targeting_db.result
  }

  type = "Opaque"
}

# ------------------------------------------------------------
# BLOCO 7 - SECRET DO EVALUATION-SERVICE
# ------------------------------------------------------------
# Nao tem banco: o evaluation le do Redis e publica na SQS. O unico
# segredo dele e a chave de API da aplicacao.
#
# O acesso a SQS NAO passa por aqui - vem de IRSA (S-06), sem
# credencial nenhuma no Secret. E a diferenca direta para a Fase 2, que
# guardava AWS_ACCESS_KEY_ID e AWS_SECRET_ACCESS_KEY aqui (F-017).
# ------------------------------------------------------------

resource "kubernetes_secret_v1" "evaluation" {
  metadata {
    name      = "evaluation-service-secret"
    namespace = kubernetes_namespace_v1.app.metadata[0].name

    labels = {
      app = "evaluation-service"
    }
  }

  data = {
    # Valor provisorio - ver a limitacao anotada no bloco 2.
    SERVICE_API_KEY = random_password.service_api_key.result
  }

  type = "Opaque"

  # ------------------------------------------------------------
  # QUEM MANDA NESTE VALOR DEPOIS DE CRIADO (F-046)
  # ------------------------------------------------------------
  # Este e o unico Secret do projeto com DOIS donos, e sem esta regra
  # eles brigam:
  #
  #   - o Terraform cria o Secret com um valor aleatorio, so para o pod
  #     conseguir subir com a variavel preenchida;
  #   - o seed (runbook, passo 2.2) descobre a chave REAL - a que o
  #     auth-service devolveu em POST /admin/keys - e sobrescreve o
  #     Secret com ela.
  #
  # A partir dai, o valor no cluster e o certo e o valor no estado do
  # Terraform e o provisorio. Num proximo `terraform apply`, o Terraform
  # veria "alguem mudou meu recurso" e restauraria o valor provisorio -
  # derrubando a autenticacao entre os servicos no reinicio seguinte do
  # pod, com um erro (401 no hot path) que nao lembra em nada a causa.
  #
  # ignore_changes = [data] resolve dizendo: crie uma vez, e depois nao
  # olhe mais para o conteudo. E o padrao do Terraform para valor de
  # bootstrap que passa a ser gerido em tempo de execucao.
  #
  # Consequencia aceita: se alguem apagar o Secret na mao, o Terraform
  # recria com o valor provisorio e o passo 2.2 do runbook precisa ser
  # refeito. E o comportamento desejado - recriar e diferente de mexer.
  lifecycle {
    ignore_changes = [data]
  }
}
