# ============================================================
# MODULO IAM-CI - identidade do GitHub Actions na AWS via OIDC
# ============================================================
# O enunciado descreve como dor "as credenciais do banco de dados estao
# sendo passadas em arquivos de texto sem seguranca". A resposta mais
# direta a isso no pipeline e nao existir credencial nenhuma.
#
# Como funciona, em uma frase: em vez de guardar AWS_ACCESS_KEY_ID nos
# secrets do GitHub, o workflow apresenta um token assinado pelo proprio
# GitHub e a AWS devolve credenciais temporarias que expiram sozinhas.
#
# Vantagem pratica: nao ha chave para vazar, rotacionar ou revogar.
# ============================================================

# ------------------------------------------------------------
# Provedor de identidade
# ------------------------------------------------------------
# Registra o GitHub como emissor de identidade confiavel para esta conta
# AWS. Recurso global: existe UM por conta, nao um por regiao - e a AWS
# recusa um segundo provedor com o mesmo endereco (EntityAlreadyExists).
#
# Por isso ha dois modos, escolhidos por var.create_oidc_provider:
#
#   true  -> este modulo CRIA o provedor e passa a ser dono dele. Um
#            terraform destroy desta camada o apaga junto. E o modo
#            certo para uma conta onde nenhum outro projeto usa OIDC
#            do GitHub.
#
#   false -> este modulo apenas LE o provedor que ja existe na conta.
#            Nao cria, nao altera e nao apaga. E o modo certo quando
#            outro projeto ja registrou o GitHub - como aconteceu nesta
#            conta em 2026-09-14. Importar o provedor para este estado
#            seria pior: o destroy do ToggleMaster derrubaria junto o CI
#            do outro projeto.
#
# A role do CI, mais abaixo, funciona igual nos dois modos: ela so
# precisa do ARN, que tem o mesmo formato venha de onde vier.
# ------------------------------------------------------------

# Modo "criar". O count 1 ou 0 liga e desliga o recurso sem duplicar codigo.
resource "aws_iam_openid_connect_provider" "github" {
  # Existe somente quando este modulo e o dono do provedor.
  count = var.create_oidc_provider ? 1 : 0

  # Endereco fixo do emissor de tokens do GitHub Actions. Nao muda e nao
  # deve ser parametrizado.
  url = "https://token.actions.githubusercontent.com"

  # Publico ("audience") esperado dentro do token. A action oficial
  # aws-actions/configure-aws-credentials usa exatamente este valor.
  client_id_list = ["sts.amazonaws.com"]

  # Impressoes digitais dos certificados TLS da GitHub. Hoje a AWS valida
  # pela cadeia de CA e ignora este campo na pratica, mas o provider ainda
  # exige que ele esteja presente.
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd",
  ]
}

# Modo "reaproveitar". Data source so CONSULTA a AWS, nunca escreve nada.
# Se o provedor nao existir, o plan falha aqui mesmo, com mensagem clara,
# antes de gastar um centavo - e a correcao e usar o modo "criar".
data "aws_iam_openid_connect_provider" "github" {
  # Existe somente quando o provedor pertence a outro dono.
  count = var.create_oidc_provider ? 0 : 1

  # Busca pelo endereco do emissor, que e unico dentro da conta.
  url = "https://token.actions.githubusercontent.com"
}

locals {
  # ARN do provedor, venha do recurso criado aqui ou da consulta acima.
  # O indice [0] e obrigatorio porque os dois blocos usam count.
  github_oidc_provider_arn = var.create_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : data.aws_iam_openid_connect_provider.github[0].arn
}

# Antes desta mudanca o recurso nao tinha count, entao um estado ja
# aplicado o guarda sem indice. Este bloco avisa ao Terraform que e o
# mesmo objeto, agora na posicao [0] - sem ele, o plan tentaria apagar o
# provedor antigo e criar um novo, derrubando o CI por alguns segundos.
moved {
  # Endereco antigo, de quando o recurso nao tinha count.
  from = aws_iam_openid_connect_provider.github
  # Endereco novo, com o indice que o count exige.
  to = aws_iam_openid_connect_provider.github[0]
}

# ------------------------------------------------------------
# Politica de confianca: QUEM pode assumir a role
# ------------------------------------------------------------
# data source nao cria nada: monta um documento JSON de policy de forma
# validada, em vez de escrever JSON solto e descobrir o erro no apply.
# ------------------------------------------------------------

data "aws_iam_policy_document" "trust" {

  statement {
    # Identificador do statement. Aparece no console e ajuda na auditoria.
    sid = "GithubOidcAssume"

    # Allow ou Deny.
    effect = "Allow"

    # Acao especifica de troca de token federado por credencial temporaria.
    actions = ["sts:AssumeRoleWithWebIdentity"]

    # Quem e o solicitante.
    principals {
      # "Federated" = identidade externa, nao um usuario IAM da conta.
      type = "Federated"

      # ARN do provedor OIDC - criado por este modulo ou reaproveitado da
      # conta, conforme var.create_oidc_provider (ver o topo do arquivo).
      identifiers = [local.github_oidc_provider_arn]
    }

    # Confere se o campo "aud" do token e o esperado. Protege contra token
    # emitido para outro destino ser reaproveitado aqui.
    condition {
      # Comparacao exata.
      test = "StringEquals"

      # Campo do token a ser verificado.
      variable = "token.actions.githubusercontent.com:aud"

      values = ["sts.amazonaws.com"]
    }

    # ESTA E A CONDICAO MAIS IMPORTANTE DO ARQUIVO.
    # Sem ela, QUALQUER repositorio do GitHub no mundo poderia assumir esta
    # role. E o erro mais comum e mais grave em configuracao de OIDC.
    condition {
      # StringLike aceita o curinga "*" no final.
      test = "StringLike"

      # O campo "sub" traz repo:<owner>/<repo>:<contexto>, onde contexto e
      # algo como "ref:refs/heads/main" ou "pull_request".
      variable = "token.actions.githubusercontent.com:sub"

      # O "*" final libera qualquer branch ou pull request DESTE repositorio.
      # Para restringir so a main, seria "repo:owner/repo:ref:refs/heads/main".
      values = ["repo:${var.github_repository}:*"]
    }
  }
}

# A role em si: um "cracha" que pode ser vestido por quem passa no teste acima.
resource "aws_iam_role" "github_actions" {
  name        = "${var.project_name}-github-actions"
  description = "Role assumida pelo GitHub Actions via OIDC para publicar imagens no ECR."

  # Converte o documento montado acima em JSON e prende a role.
  assume_role_policy = data.aws_iam_policy_document.trust.json
}

# ------------------------------------------------------------
# Permissoes: O QUE a role pode fazer
# ------------------------------------------------------------
# Menor privilegio (S-06): apenas o necessario para autenticar e enviar
# imagem, e somente nos 5 repositorios do projeto.
# ------------------------------------------------------------

data "aws_iam_policy_document" "ecr_push" {

  statement {
    sid    = "EcrAuthToken"
    effect = "Allow"

    # Troca a credencial da role por um token de login do Docker.
    actions = ["ecr:GetAuthorizationToken"]

    # "*" aqui nao e descuido: esta acao da AWS nao aceita recurso
    # especifico, e a propria API recusa qualquer ARN. O escopo real do
    # acesso fica no statement seguinte.
    resources = ["*"]
  }

  statement {
    sid    = "EcrPushPull"
    effect = "Allow"

    actions = [
      # As cinco primeiras compoem o docker push, em ordem de uso:
      "ecr:BatchCheckLayerAvailability", # verifica quais camadas ja existem
      "ecr:InitiateLayerUpload",         # abre o envio de uma camada nova
      "ecr:UploadLayerPart",             # envia os pedacos da camada
      "ecr:CompleteLayerUpload",         # fecha o envio da camada
      "ecr:PutImage",                    # registra o manifesto com a tag

      # As demais permitem ao pipeline ler o que ja existe, necessario para
      # o cache de build e para o Trivy escanear a imagem publicada:
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
      "ecr:DescribeImages",
      "ecr:DescribeRepositories",
    ]

    # Restringe as acoes acima aos 5 ARNs recebidos do modulo de ECR.
    # E isto que impede o CI de mexer em qualquer outro repositorio da conta.
    resources = var.ecr_repository_arns
  }
}

# Transforma o documento em uma policy gerenciada, reutilizavel e auditavel.
resource "aws_iam_policy" "ecr_push" {
  name        = "${var.project_name}-ci-ecr-push"
  description = "Permite ao CI autenticar e publicar imagens nos 5 repositorios ECR do ToggleMaster."
  policy      = data.aws_iam_policy_document.ecr_push.json
}

# Cola a policy na role. Sem este anexo, a role existe mas nao pode nada.
resource "aws_iam_role_policy_attachment" "ecr_push" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.ecr_push.arn
}
