# ============================================================
# MODULO ECR - um repositorio por microsservico
# ============================================================
# Nome no formato <servico>-service para bater exatamente com o que os
# deployments da Fase 2 ja referenciam (F-019). Trocar o padrao aqui
# obrigaria a reescrever os manifestos em gitops/.
# ============================================================

resource "aws_ecr_repository" "this" {
  for_each = toset(var.services)

  name                 = "${each.value}-service"
  image_tag_mutability = var.image_tag_mutability

  # Sem isto, `terraform destroy` falha em qualquer repositorio que tenha
  # imagem dentro, e alguem precisa esvaziar na mao. Como a estrategia de
  # custo do projeto e destruir e recriar entre sessoes (S-09), isso
  # deixaria o destroy travado justamente quando ele mais importa.
  force_delete = true

  # Scan basico gratuito a cada push. Nao substitui o Trivy do pipeline
  # (O-18), mas garante uma segunda camada mesmo em imagem enviada a mao.
  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
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
  for_each = aws_ecr_repository.this

  repository = each.value.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Mantem apenas as ${var.images_to_keep} imagens mais recentes"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = var.images_to_keep
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
