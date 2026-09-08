# ============================================================
# MODULO EKS - cluster, nos, IAM e addons (O-03 e O-04)
# ============================================================
# Este modulo nasceu da leitura de terraform/modules/eks/ da branch
# main, mas foi REESCRITO por duas incompatibilidades com a nossa conta:
#
#   1. O modulo da main usa `role_arn = var.lab_role_arn` - foi escrito
#      para a LabRole do AWS Academy. Nosso projeto usa conta pessoal e
#      cria as roles via Terraform (D-002, R-05).
#
#   2. O default de instancia la e `t3.medium`, que ESTA CONTA RECUSA:
#      "The specified instance type is not eligible for Free Tier"
#      (F-023). Aqui o tipo vem de var.node_instance_type, que ja tem
#      c7i-flex.large como padrao (D-016).
#
# Foram acrescentados tres itens que faltavam la e que ja custaram tempo
# na Fase 2 ou custariam no video:
#   - provedor OIDC do cluster, sem o qual nao existe IRSA (S-06);
#   - addon aws-ebs-csi-driver, sem o qual o PVC do banco em pod fica
#     Pending para sempre (F-025);
#   - addon metrics-server, sem o qual os dois HPA ficam <unknown> e
#     nunca escalam (P-039).
# ============================================================

# ------------------------------------------------------------
# BLOCO 1 - IAM DO PLANO DE CONTROLE
# ------------------------------------------------------------
# O EKS e um servico gerenciado: a AWS opera o control plane em nome da
# conta. Para isso ele precisa de uma role que a propria AWS assume.
# ------------------------------------------------------------

# Documento de confianca: QUEM pode assumir a role.
data "aws_iam_policy_document" "cluster_assume" {
  statement {
    # Permite a acao de assumir a role.
    actions = ["sts:AssumeRole"]

    principals {
      # "Service" = quem assume e um servico da AWS, nao um usuario.
      type = "Service"
      # Especificamente o servico EKS. Nenhum outro servico consegue.
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

# A role em si. Ela nao tem permissao nenhuma ate receber uma policy.
resource "aws_iam_role" "cluster" {
  name               = "${var.name}-eks-cluster"
  description        = "Role assumida pelo servico EKS para operar o control plane."
  assume_role_policy = data.aws_iam_policy_document.cluster_assume.json
}

# Policy gerenciada pela AWS com exatamente o que o control plane precisa.
# Usar a gerenciada, e nao uma escrita a mao, evita erro sutil de
# permissao e acompanha mudancas futuras do servico.
resource "aws_iam_role_policy_attachment" "cluster_policy" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# ------------------------------------------------------------
# BLOCO 2 - O CLUSTER (O-03)
# ------------------------------------------------------------

resource "aws_eks_cluster" "this" {
  # Nome do cluster. Entra no kubeconfig e no ARN de tudo que e filho.
  name = var.name

  # Role do bloco anterior.
  role_arn = aws_iam_role.cluster.arn

  # Versao do Kubernetes. Confirmado em 2026-09-08 que a 1.31 esta
  # disponivel nesta regiao (as opcoes iam de 1.31 a 1.36).
  version = var.kubernetes_version

  vpc_config {
    # Subnets onde o EKS coloca as interfaces de rede do control plane.
    # Sao as privadas, vindas da camada base.
    subnet_ids = var.subnet_ids

    # Endpoint privado: acesso de dentro da VPC.
    endpoint_private_access = true

    # Endpoint publico: acesso pela internet, protegido por IAM.
    # Fica LIGADO de proposito - sem ele, rodar kubectl do notebook
    # exigiria VPN ou bastion, e a gravacao do video ficaria inviavel.
    # Nao expoe a aplicacao: e so a API do Kubernetes, e ela exige
    # credencial AWS valida (D-012 continua valendo, nao ha Ingress).
    endpoint_public_access = true
  }

  access_config {
    # API_AND_CONFIG_MAP aceita os dois mecanismos de autorizacao: as
    # access entries novas (via API) e o aws-auth ConfigMap antigo.
    # Escolhido por ser o mais compativel com ferramentas de terceiros.
    authentication_mode = "API_AND_CONFIG_MAP"

    # Da permissao de administrador do cluster a quem rodar o apply.
    # SEM ISTO ninguem consegue rodar kubectl depois de criar o cluster -
    # nem quem o criou. E a pegadinha classica do EKS.
    bootstrap_cluster_creator_admin_permissions = true
  }

  # Garante que a policy esteja anexada ANTES de criar o cluster. Sem o
  # depends_on, o Terraform pode criar os dois em paralelo e o cluster
  # falha por falta de permissao.
  depends_on = [aws_iam_role_policy_attachment.cluster_policy]
}

# ------------------------------------------------------------
# BLOCO 3 - PROVEDOR OIDC DO CLUSTER (base do IRSA, S-06)
# ------------------------------------------------------------
# Este bloco e o que permite trocar chave de acesso estatica por
# identidade. Sem ele, os pods de analytics e evaluation precisariam de
# AWS_ACCESS_KEY_ID num Secret - exatamente o que a Fase 2 fazia (F-017)
# e o que o enunciado critica.
#
# Nao confundir com o provedor OIDC do GitHub, criado na camada base:
# aquele autentica o CI; este autentica os pods.
# ------------------------------------------------------------

# Le o certificado TLS do emissor OIDC do cluster, para extrair a
# impressao digital exigida pela AWS.
data "tls_certificate" "cluster" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "cluster" {
  # Publico do token: valor fixo exigido pela AWS para IRSA.
  client_id_list = ["sts.amazonaws.com"]

  # Impressao digital do certificado do emissor. Garante que a AWS so
  # aceite tokens assinados por este cluster.
  thumbprint_list = [data.tls_certificate.cluster.certificates[0].sha1_fingerprint]

  # URL do emissor OIDC, publicada pelo proprio cluster.
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

# ------------------------------------------------------------
# BLOCO 4 - IAM DOS NOS
# ------------------------------------------------------------
# Os nos sao instancias EC2. Elas precisam de permissao para entrar no
# cluster, configurar rede e baixar imagens do ECR.
# ------------------------------------------------------------

data "aws_iam_policy_document" "node_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      # Aqui e ec2, e nao eks: quem assume a role e a instancia.
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "node" {
  name               = "${var.name}-eks-node"
  description        = "Role das instancias EC2 que formam o node group do EKS."
  assume_role_policy = data.aws_iam_policy_document.node_assume.json
}

# Tres policies gerenciadas, cada uma com um papel distinto. for_each
# evita repetir o mesmo bloco tres vezes.
resource "aws_iam_role_policy_attachment" "node" {
  for_each = toset([
    # Permite ao no se registrar no cluster e receber trabalho.
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    # Permite ao agente de rede (VPC CNI) atribuir IPs aos pods.
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    # Permite BAIXAR imagens do ECR. Sem isto todo pod fica em
    # ImagePullBackOff, porque nossas 5 imagens vivem no ECR privado.
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
  ])

  role       = aws_iam_role.node.name
  policy_arn = each.value
}

# ------------------------------------------------------------
# BLOCO 5 - NODE GROUP (O-04)
# ------------------------------------------------------------

resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.name}-nodes"
  node_role_arn   = aws_iam_role.node.arn

  # Mesmas subnets privadas do cluster.
  subnet_ids = var.subnet_ids

  # Tipo da instancia. c7i-flex.large por bloqueio da conta (F-023).
  instance_types = [var.node_instance_type]

  # ON_DEMAND e nao SPOT: instancia spot pode ser retomada pela AWS a
  # qualquer momento, e perder um no no meio da gravacao do video seria
  # um risco caro por uma economia pequena numa sessao de 3 horas.
  capacity_type = "ON_DEMAND"

  scaling_config {
    # Minimo. 1 permite reduzir o custo entre sessoes sem destruir.
    min_size = var.node_group_min_size
    # Desejado. 2 para o HPA ter onde colocar o pod extra (F-020).
    desired_size = var.node_group_desired_size
    # Maximo, teto do auto scaling.
    max_size = var.node_group_max_size
  }

  update_config {
    # Durante uma atualizacao, no maximo 1 no fica indisponivel por vez.
    max_unavailable = 1
  }

  # As policies precisam existir antes: um no sem permissao sobe, tenta
  # se registrar, falha, e o node group fica em CREATE_FAILED.
  depends_on = [aws_iam_role_policy_attachment.node]
}

# ------------------------------------------------------------
# BLOCO 6 - IAM DO DRIVER DE DISCO (EBS CSI)
# ------------------------------------------------------------
# O banco do targeting roda como StatefulSet e pede um disco (PVC).
# Quem cria o volume EBS de verdade e o driver aws-ebs-csi-driver, e ele
# precisa de permissao propria - concedida por IRSA, nao por chave.
#
# F-025: a Fase 2 perdeu tempo com o PVC preso em Pending exatamente por
# falta desta peca. Aqui ela nasce do Terraform.
# ------------------------------------------------------------

data "aws_iam_policy_document" "ebs_csi_assume" {
  statement {
    # Acao especifica do IRSA: assumir role usando um token OIDC.
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      # O principal e o provedor OIDC do cluster, criado no bloco 3.
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.cluster.arn]
    }

    condition {
      test = "StringEquals"
      # Amarra a role a UMA ServiceAccount especifica. Sem esta condicao,
      # qualquer pod do cluster poderia assumir a role.
      variable = "${replace(aws_iam_openid_connect_provider.cluster.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.cluster.url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ebs_csi" {
  name               = "${var.name}-ebs-csi"
  description        = "Role IRSA do driver EBS CSI, que provisiona os volumes dos PVC."
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_assume.json
}

resource "aws_iam_role_policy_attachment" "ebs_csi" {
  role = aws_iam_role.ebs_csi.name
  # Policy gerenciada pela AWS especifica para este driver.
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

# ------------------------------------------------------------
# BLOCO 7 - ADDONS GERENCIADOS
# ------------------------------------------------------------
# Addon gerenciado e um componente que a AWS instala e atualiza no
# cluster. Confirmado em 2026-09-08 que os cinco existem nesta regiao.
#
# Instalar por addon, e nao por Helm, evita adicionar o provider helm ao
# projeto - uma peca a menos para falhar na sessao de gravacao.
# ------------------------------------------------------------

# Rede dos pods. Sem ele nenhum pod recebe IP.
resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.this.name
  addon_name   = "vpc-cni"
  # Se o addon ja existir no cluster, sobrescreve em vez de falhar.
  resolve_conflicts_on_create = "OVERWRITE"
}

# DNS interno. E o que faz "http://auth-service:8001" resolver.
resource "aws_eks_addon" "coredns" {
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "coredns"
  resolve_conflicts_on_create = "OVERWRITE"
  # CoreDNS roda como pod: precisa de no disponivel para agendar.
  depends_on = [aws_eks_node_group.this]
}

# Roteamento de Service para pod dentro de cada no.
resource "aws_eks_addon" "kube_proxy" {
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "kube-proxy"
  resolve_conflicts_on_create = "OVERWRITE"
}

# Driver de disco. Recebe a role IRSA do bloco 6.
resource "aws_eks_addon" "ebs_csi" {
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "aws-ebs-csi-driver"
  resolve_conflicts_on_create = "OVERWRITE"
  # E aqui que a role e amarrada a ServiceAccount do driver.
  service_account_role_arn = aws_iam_role.ebs_csi.arn
  depends_on               = [aws_eks_node_group.this]
}

# Coletor de metricas de CPU e memoria. Sem ele os dois HPA do projeto
# ficam com "targets: <unknown>" e nunca escalam (P-039).
resource "aws_eks_addon" "metrics_server" {
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "metrics-server"
  resolve_conflicts_on_create = "OVERWRITE"
  depends_on                  = [aws_eks_node_group.this]
}
