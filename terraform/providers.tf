# ============================================================
# PROVIDER AWS
# ============================================================
# default_tags aplica as tags do projeto (D-009) em TODO recurso
# criado por este Terraform, sem precisar repetir bloco `tags` em
# cada resource. Isso alimenta o Cost Explorer e viabiliza o print
# de estimativa de custos exigido no relatorio (O-39).
# ============================================================

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.default_tags
  }
}
