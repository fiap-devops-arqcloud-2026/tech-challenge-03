# ============================================================
# MODULO IAM-CI - identidade do GitHub Actions na AWS via OIDC
# ============================================================
# O enunciado descreve como dor "credenciais em arquivos de texto sem
# seguranca". A resposta mais direta a isso no pipeline e nao existir
# credencial nenhuma: em vez de guardar AWS_ACCESS_KEY_ID nos secrets do
# GitHub, o workflow apresenta um token OIDC assinado pelo proprio GitHub
# e recebe credenciais temporarias da AWS.
#
# Vantagem pratica: nao ha chave para vazar, rotacionar ou revogar.
# ============================================================

# ------------------------------------------------------------
# Provedor de identidade
# ------------------------------------------------------------

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  # Publico esperado dentro do token. A action oficial da AWS usa este valor.
  client_id_list = ["sts.amazonaws.com"]

  # Impressoes digitais dos certificados da GitHub. A AWS hoje valida pela
  # cadeia de CA e ignora este campo na pratica, mas o provider ainda o exige.
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd",
  ]
}

# ------------------------------------------------------------
# Politica de confianca: QUEM pode assumir a role
# ------------------------------------------------------------

data "aws_iam_policy_document" "trust" {
  statement {
    sid     = "GithubOidcAssume"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    # Sem esta condicao, qualquer repositorio do GitHub no mundo poderia
    # assumir a role. E o erro mais comum e mais grave em setup de OIDC.
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_repository}:*"]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = "${var.project_name}-github-actions"
  description        = "Role assumida pelo GitHub Actions via OIDC para publicar imagens no ECR."
  assume_role_policy = data.aws_iam_policy_document.trust.json
}

# ------------------------------------------------------------
# Permissoes: O QUE a role pode fazer
# ------------------------------------------------------------
# Menor privilegio (S-06): apenas o necessario para autenticar e enviar
# imagem, e somente nos 5 repositorios do projeto.
# ------------------------------------------------------------

data "aws_iam_policy_document" "ecr_push" {
  # Esta acao nao aceita recurso especifico: a propria API so funciona com
  # "*". O escopo real fica no segundo statement.
  statement {
    sid       = "EcrAuthToken"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid    = "EcrPushPull"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
      "ecr:DescribeImages",
      "ecr:DescribeRepositories",
    ]
    resources = var.ecr_repository_arns
  }
}

resource "aws_iam_policy" "ecr_push" {
  name        = "${var.project_name}-ci-ecr-push"
  description = "Permite ao CI autenticar e publicar imagens nos 5 repositorios ECR do ToggleMaster."
  policy      = data.aws_iam_policy_document.ecr_push.json
}

resource "aws_iam_role_policy_attachment" "ecr_push" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.ecr_push.arn
}
