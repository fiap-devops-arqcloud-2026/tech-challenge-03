# ============================================================
# STORAGECLASS PADRAO - o disco do banco em pod
# ============================================================
# POR QUE ESTE ARQUIVO EXISTE
#
# O StatefulSet postgres-targeting pede um disco de 5Gi por
# volumeClaimTemplates. Quem atende esse pedido e uma StorageClass.
#
# O EKS cria uma StorageClass `gp2` sozinho, mas NAO a marca como
# padrao. Sem padrao e sem nome explicito no manifesto, o PVC fica em
# Pending para sempre, o pod do banco nunca inicia e o
# targeting-service entra em CrashLoopBackOff sem conseguir conectar.
#
# Foi exatamente isso que travou a Fase 2 (F-025), e a auditoria de
# 2026-09-09 mostrou que o problema tinha sido reintroduzido: o
# volumeClaimTemplates nao declarava storageClassName nenhum.
#
# A correcao tem DOIS lados, e os dois foram aplicados:
#   1. aqui: criar uma StorageClass e marca-la como padrao;
#   2. no manifesto: declarar storageClassName explicitamente, para nao
#      depender de qual classe esta marcada como padrao no momento.
#
# O segundo lado e o que realmente protege. O primeiro cobre qualquer
# PVC futuro que alguem crie sem pensar nisso.
# ============================================================

resource "kubernetes_storage_class_v1" "gp3" {
  metadata {
    # Nome referenciado pelo storageClassName do StatefulSet. Precisa
    # ser identico ao valor de var.storage_class_name.
    name = var.storage_class_name

    annotations = {
      # E ESTA anotacao que marca a classe como padrao do cluster.
      # Qualquer PVC sem storageClassName passa a usar esta.
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }

  # Driver que provisiona o volume. E o addon aws-ebs-csi-driver
  # instalado pelo modulo eks, com role IRSA propria.
  storage_provisioner = "ebs.csi.aws.com"

  # WaitForFirstConsumer, e nao Immediate: o volume so e criado depois
  # que o Kubernetes decide em qual no o pod vai rodar.
  #
  # Por que importa: um volume EBS vive numa zona de disponibilidade
  # especifica. Com Immediate, o volume poderia nascer em us-east-2a e o
  # pod ser agendado num no de us-east-2b - e o pod ficaria preso, sem
  # conseguir montar o disco. Com WaitForFirstConsumer os dois nascem na
  # mesma zona por construcao.
  volume_binding_mode = "WaitForFirstConsumer"

  # Permite aumentar o disco depois sem recriar o volume.
  allow_volume_expansion = true

  # O que acontece com o volume quando o PVC e apagado.
  # Delete: o volume EBS some junto. E o correto aqui - o cluster inteiro
  # e destruido ao fim de cada sessao, e volume orfao continuaria
  # cobrando sem ninguem perceber (S-09).
  reclaim_policy = "Delete"

  parameters = {
    # gp3 e mais barato e mais rapido que gp2 no mesmo tamanho, e nao
    # amarra o desempenho ao tamanho do disco.
    type = "gp3"

    # Criptografia em repouso no volume (S-05). Sem chave KMS propria:
    # usa a chave gerenciada padrao da conta para EBS.
    encrypted = "true"
  }
}
