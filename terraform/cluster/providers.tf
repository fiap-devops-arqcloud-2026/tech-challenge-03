# ============================================================
# PROVIDER AWS - camada cluster
# ============================================================
# Mesma configuracao da base. As tags precisam ser identicas para que o
# Cost Explorer some as duas camadas no mesmo grupo (D-009).
# ============================================================

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.default_tags
  }
}
