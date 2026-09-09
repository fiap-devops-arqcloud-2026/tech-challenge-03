# ============================================================
# ARGOCD - a entrega continua por GitOps (O-23, O-25)
# ============================================================
# O ArgoCD e o vigia do projeto: ele observa a pasta gitops/ no
# repositorio e, quando algo muda la, aplica a mudanca no cluster
# sozinho. E o que permite abandonar o `kubectl apply` do CI (O-26).
#
# O CICLO COMPLETO, ponta a ponta:
#   1. alguem faz push de codigo na main;
#   2. o pipeline compila, roda linter, SAST e SCA;
#   3. passando, publica a imagem no ECR com a tag do commit;
#   4. o ultimo job do pipeline roda `kustomize edit set image` e comita
#      a tag nova em gitops/overlays/prod/kustomization.yaml;
#   5. o ArgoCD percebe o commit, renderiza o Kustomize e aplica a
#      diferenca no cluster.
#
# O passo 5 e este arquivo. Do 1 ao 4 e .github/workflows/.
# ============================================================

# ------------------------------------------------------------
# BLOCO 1 - NAMESPACE DO ARGOCD
# ------------------------------------------------------------
# Separado do namespace das aplicacoes: o ArgoCD e infraestrutura, nao
# aplicacao. Se um dia alguem apagar o namespace togglemaster inteiro, o
# ArgoCD sobrevive e reconstroi tudo a partir do Git.
# ------------------------------------------------------------

resource "kubernetes_namespace_v1" "argocd" {
  metadata {
    name = var.argocd_namespace
  }
}

# ------------------------------------------------------------
# BLOCO 2 - CREDENCIAL DE LEITURA DO REPOSITORIO
# ------------------------------------------------------------
# O repositorio do grupo e PRIVADO ate a entrega (F-014). Repositorio
# privado exige credencial: sem ela o ArgoCD falha ao clonar com
# "authentication required" e a Application nunca sai de Unknown.
#
# O ArgoCD descobre credenciais lendo Secrets do proprio namespace que
# tenham o rotulo argocd.argoproj.io/secret-type = repository. Nao e
# preciso configurar nada alem disso.
#
# count = 0 ou 1: se var.github_token vier vazio, o recurso nem e
# criado. Isso mantem a configuracao valida caso o repositorio venha a
# ser publico na entrega.
# ------------------------------------------------------------

resource "kubernetes_secret_v1" "argocd_repo" {
  # Cria apenas se um token foi informado.
  count = var.github_token != "" ? 1 : 0

  metadata {
    name      = "repo-tech-challenge-03"
    namespace = kubernetes_namespace_v1.argocd.metadata[0].name

    labels = {
      # E ESTE rotulo que faz o ArgoCD enxergar o Secret como credencial
      # de repositorio. Sem ele, o Secret e ignorado.
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }

  data = {
    # Tipo de repositorio. "git" e o unico usado aqui.
    type = "git"

    # URL exata do repositorio. Precisa casar com o repoURL da
    # Application do bloco 4, caractere por caractere.
    url = var.gitops_repo_url

    # Em token do GitHub, o usuario pode ser qualquer coisa nao vazia -
    # o que autentica e a senha. "git" e a convencao.
    username = "git"

    # O token propriamente dito. Vem de variavel sensivel, tipicamente
    # por TF_VAR_github_token; nunca fica em arquivo versionado.
    password = var.github_token
  }

  type = "Opaque"
}

# ------------------------------------------------------------
# BLOCO 3 - INSTALACAO DO ARGOCD (O-23)
# ------------------------------------------------------------
# Instalado pelo chart oficial via provider helm, que e uma das formas
# que o enunciado cita explicitamente.
# ------------------------------------------------------------

resource "helm_release" "argocd" {
  # Nome da release. Vira prefixo dos recursos criados pelo chart.
  name = "argocd"

  # Repositorio oficial do projeto Argo.
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"

  # Versao FIXA. Com a versao em aberto, um apply feito na semana da
  # gravacao poderia trazer release nova e mudar o comportamento.
  version = var.argocd_chart_version

  namespace = kubernetes_namespace_v1.argocd.metadata[0].name

  # Espera todos os pods ficarem prontos antes de dar o apply por
  # concluido. Sem isto, a Application do bloco 4 seria criada antes de
  # a API do ArgoCD existir e falharia.
  wait = true

  # 10 minutos de teto. O chart sobe varios componentes (server, repo
  # server, controller, redis) e num cluster novo isso leva alguns
  # minutos.
  timeout = 600

  # ----------------------------------------------------------
  # AJUSTES DE CONFIGURACAO
  # ----------------------------------------------------------
  # Passados por "values" com yamlencode, e nao por "set".
  #
  # POR QUE: no `set`, o nome do parametro e uma string com pontos como
  # separador de nivel. Quando a propria CHAVE contem um ponto - o caso
  # de "server.insecure" dentro de configs.params - e preciso escapar
  # com barra invertida, e o HCL trata barra invertida como escape dele
  # mesmo. O resultado e uma barra dupla fragil, que ja falhou aqui com
  # "The symbol . is not a valid escape sequence selector".
  #
  # Com yamlencode a estrutura e declarada como mapa de verdade: nao ha
  # string com separador, nao ha escape, e o resultado e legivel.
  values = [
    yamlencode({
      # Desliga o Dex, componente de login federado (Google, GitHub...).
      # Nao ha uso aqui e ele consome memoria de um cluster de 2 nos.
      dex = {
        enabled = false
      }

      # Desliga o ApplicationSet controller: ele gera Applications em
      # massa a partir de geradores, e o projeto tem UMA Application so.
      applicationSet = {
        enabled = false
      }

      # Desliga as notificacoes (Slack, e-mail). Nao usadas.
      notifications = {
        enabled = false
      }

      configs = {
        params = {
          # Servidor em HTTP interno, sem TLS proprio.
          #
          # Nao ha Ingress nem Load Balancer no projeto (D-012), entao o
          # acesso a interface na gravacao e por `kubectl port-forward`.
          # Com TLS ligado, o port-forward exigiria aceitar certificado
          # autoassinado no navegador - ruido desnecessario no video.
          #
          # Repare que a chave tem um ponto no NOME e aqui isso nao e
          # problema nenhum: e so uma chave de mapa entre aspas.
          "server.insecure" = true
        }
      }

      # Uma replica de cada componente. O padrao do chart e maior e nao
      # cabe confortavelmente em 2 nos c7i-flex.large (F-020).
      controller = {
        replicas = 1
      }

      server = {
        replicas = 1
      }

      repoServer = {
        replicas = 1
      }
    })
  ]

  # O Secret de credencial precisa existir ANTES do ArgoCD subir, senao
  # a primeira tentativa de sincronizar falha por autenticacao.
  depends_on = [kubernetes_secret_v1.argocd_repo]
}

# ------------------------------------------------------------
# BLOCO 4 - A APPLICATION (O-25, O-32)
# ------------------------------------------------------------
# Este objeto e a instrucao permanente dada ao ArgoCD: "observe esta
# pasta deste repositorio e mantenha o cluster igual a ela".
#
# E criado com kubernetes_manifest porque Application e um recurso
# customizado (CRD) instalado pelo proprio chart - nao faz parte da API
# padrao do Kubernetes.
# ------------------------------------------------------------

resource "kubernetes_manifest" "app_togglemaster" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"

    metadata = {
      # Nome exibido na interface do ArgoCD. E o card que aparece no
      # video mostrando os 5 microsservicos (O-32).
      name = "togglemaster"

      # A Application mora no namespace do ArgoCD, nao no das apps.
      namespace = kubernetes_namespace_v1.argocd.metadata[0].name
    }

    spec = {
      # "default" e o projeto padrao criado pelo chart, sem restricoes.
      project = "default"

      # ONDE ESTA A VERDADE
      source = {
        # Repositorio observado. Precisa ser identico ao url do Secret
        # de credencial do bloco 2.
        repoURL = var.gitops_repo_url

        # Pasta observada: o overlay do unico ambiente (D-011). O ArgoCD
        # detecta o kustomization.yaml e renderiza sozinho, sem precisar
        # de configuracao extra.
        path = var.gitops_repo_path

        # Branch observada. E a `main` porque e nela que o job gitops do
        # CI comita a tag nova (O-24).
        targetRevision = var.gitops_repo_branch
      }

      # ONDE APLICAR
      destination = {
        # "in-cluster" e o apelido que o ArgoCD da ao proprio cluster
        # onde esta instalado.
        server = "https://kubernetes.default.svc"

        # Namespace das aplicacoes.
        namespace = var.app_namespace
      }

      # COMO SINCRONIZAR (O-25)
      syncPolicy = {
        automated = {
          # prune: apaga do cluster o que foi removido do Git. Sem isso,
          # um recurso deletado do repositorio continuaria vivo para
          # sempre - e o Git deixaria de ser a fonte da verdade.
          prune = true

          # selfHeal: desfaz alteracao feita a mao no cluster. Se alguem
          # rodar um `kubectl edit`, o ArgoCD reverte para o que esta no
          # Git. E o que torna a demonstracao do GitOps convincente.
          selfHeal = true
        }

        syncOptions = [
          # Cria o namespace de destino se nao existir. Aqui e
          # redundante - o namespace ja nasce em secrets.tf - mas
          # protege caso alguem o apague.
          "CreateNamespace=true",
        ]

        retry = {
          # Ate 5 tentativas em caso de falha temporaria.
          limit = 5

          backoff = {
            # Espera 5s, depois 10s, 20s... ate o teto de 3 minutos.
            duration    = "5s"
            factor      = 2
            maxDuration = "3m"
          }
        }
      }
    }
  }

  # O CRD Application so existe depois que o chart e instalado. Sem este
  # depends_on, o apply falha com "no matches for kind Application".
  depends_on = [helm_release.argocd]
}
