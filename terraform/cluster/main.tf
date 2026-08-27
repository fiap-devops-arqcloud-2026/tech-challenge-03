# ============================================================
# CAMADA CLUSTER - recursos que cobram por hora
# ============================================================
# ESTA CAMADA AINDA NAO TEM RECURSOS. O que existe aqui hoje e a
# fiacao: backend proprio (backend.tf), leitura do estado da base
# (data.tf), provider (providers.tf) e as variaveis (variables.tf).
#
# Os recursos entram na Fase B do plano, conforme
# docs/00_COLAB_IA/PENDENCIAS_E_PROXIMOS_PASSOS.md:
#
#   P-028  Cluster EKS (O-03) e node group (O-04) com c7i-flex.large,
#          usando terraform-aws-modules/eks/aws (D-010), nas subnets
#          privadas lidas de local.private_subnet_ids.
#
#   P-028  2 instancias RDS PostgreSQL (O-05 parcial) - auth_db e
#          flags_db. A terceira nao existe por bloqueio da conta
#          (F-023); targeting_db roda em pod (D-015).
#
#   P-028  1 cluster ElastiCache Redis (O-06).
#
#   P-028  Senhas geradas com random_password e gravadas no AWS
#          Secrets Manager, para nunca aparecerem em tfvars nem no Git.
#
#   P-028  Duas roles IRSA (S-06), com menor privilegio:
#            evaluation -> sqs:SendMessage em local.sqs_queue_arn
#            analytics  -> sqs:ReceiveMessage e sqs:DeleteMessage na
#                          mesma fila, mais dynamodb:PutItem em
#                          local.dynamodb_table_arn
#
#   P-035  Addon aws-ebs-csi-driver e uma StorageClass marcada como
#          default. Sem isso o PVC do banco em pod fica Pending, como
#          travou a Fase 2 (F-025).
#
#   P-039  Metrics Server. Sem ele os dois HPA ficam com <unknown> e
#          nunca escalam, e a demonstracao de escalabilidade falha.
#
# ------------------------------------------------------------
# LEMBRETE DE CUSTO
# ------------------------------------------------------------
# Com tudo isto de pe, a conta corre a cerca de US$ 0,37 por hora
# (F-026). Rodar `terraform destroy` NESTA PASTA ao fim de cada sessao
# nao e otimizacao: e requisito. A camada base nao e afetada.
# ============================================================

# Sem recursos declarados ainda. O arquivo existe para que a estrutura
# do root module fique visivel e o `terraform validate` passe.
