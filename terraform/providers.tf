# ============================================================
# PROVIDER AWS
# ============================================================
# O provider e o "tradutor" entre o codigo Terraform e a API da AWS.
# Sem ele, nenhum recurso aws_* pode ser criado.
# ============================================================

# Configura o provider "aws" declarado em backend.tf.
provider "aws" {

  # Regiao onde TODOS os recursos deste projeto serao criados.
  # Vem de variavel para nao ficar espalhado pelo codigo. Padrao: us-east-2.
  region = var.aws_region

  # Bloco especial do provider AWS: aplica estas tags automaticamente em
  # todo recurso criado por este Terraform, sem precisar repetir um bloco
  # `tags = {...}` em cada resource.
  #
  # Por que isso importa (D-009): as tags alimentam o Cost Explorer. Sem
  # elas nao da para saber quanto o projeto gastou, e o relatorio final
  # exige um print da estimativa de custos (O-39).
  default_tags {

    # Mapa de tags vindo de variavel. Ver o padrao em variables.tf.
    tags = var.default_tags
  }
}
