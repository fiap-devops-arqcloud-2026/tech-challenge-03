# ============================================================
# MODULO ECR - um repositorio por microsservico
# ============================================================
# O ECR e o "Docker Hub privado" da AWS. O pipeline de CI constroi a
# imagem de cada servico e envia para o repositorio correspondente.
#
# Nome no formato <servico>-service para bater exatamente com o que os
# deployments da Fase 2 ja referenciam (F-019). Trocar o padrao aqui
# obrigaria a reescrever os manifestos em gitops/.
# ============================================================

resource "aws_ecr_repository" "this" {

  # for_each cria UM recurso para cada item da lista, em vez de escrever
  # cinco blocos quase iguais. toset() converte a lista em conjunto, que e
  # o tipo que o for_each exige. Cada instancia fica enderecavel por nome,
  # ex.: aws_ecr_repository.this["auth"].
  for_each = toset(var.services)

  # each.value e o item atual do conjunto ("auth", "flag", ...).
  # O sufixo "-service" completa o nome usado na Fase 2.
  name = "${each.value}-service"

  # MUTABLE permite sobrescrever uma tag ja existente; IMMUTABLE proibe.
  image_tag_mutability = var.image_tag_mutability

  # Permite que o terraform destroy apague o repositorio mesmo com imagens
  # dentro. Sem isto o destroy falha e alguem precisa esvaziar na mao.
  # Como a estrategia de custo do projeto e destruir e recriar entre
  # sessoes (S-09), isso travaria o destroy justamente quando ele importa.
  force_delete = true

  # Scan basico e gratuito de vulnerabilidades a cada push.
  image_scanning_configuration {

    # Dispara a analise automaticamente quando a imagem chega.
    # Nao substitui o Trivy do pipeline (O-18), mas garante uma segunda
    # camada mesmo em imagem enviada a mao, fora do CI.
    scan_on_push = true
  }

  # Criptografia em repouso das camadas da imagem.
  encryption_configuration {

    # AES256 usa chave gerenciada pela propria AWS, sem custo adicional.
    # A alternativa, KMS, cobra por requisicao e nao agrega aqui.
    encryption_type = "AES256"
  }
}

# ------------------------------------------------------------
# Expiracao de imagens antigas
# ------------------------------------------------------------
# Cada commit gera uma imagem nova. Sem esta politica, o repositorio
# cresce para sempre e o armazenamento vira custo silencioso.
# ------------------------------------------------------------

resource "aws_ecr_lifecycle_policy" "this" {

  # Itera sobre os repositorios criados acima. Passar o proprio recurso
  # ao for_each mantem as chaves alinhadas ("auth" aqui e o "auth" de la).
  for_each = aws_ecr_repository.this

  # each.value e o objeto do repositorio; .name e o atributo dele.
  repository = each.value.name

  # A API do ECR espera a politica como texto JSON. jsonencode() converte
  # a estrutura HCL abaixo em JSON, evitando escrever aspas na mao.
  policy = jsonencode({

    # A API aceita uma lista de regras avaliadas por prioridade.
    rules = [
      {
        # Menor numero = avaliado primeiro. Com uma regra so, e sempre 1.
        rulePriority = 1

        # Texto livre, aparece no console da AWS.
        description = "Mantem apenas as ${var.images_to_keep} imagens mais recentes"

        # Quais imagens a regra alcanca.
        selection = {
          # "any" = com tag ou sem tag, tanto faz.
          tagStatus = "any"

          # Criterio por quantidade, nao por idade.
          countType = "imageCountMoreThan"

          # Limite: o que passar disso e alvo da acao abaixo.
          countNumber = var.images_to_keep
        }

        # O que fazer com as imagens selecionadas.
        action = {
          # "expire" = apagar. E a unica acao que o ECR suporta hoje.
          type = "expire"
        }
      }
    ]
  })
}
