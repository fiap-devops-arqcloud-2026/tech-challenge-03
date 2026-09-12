# Exclusao completa dos recursos AWS - 2026-09-11

TL;DR: encerrar a Application ArgoCD; destruir `terraform/k8s`; conferir que o PV/EBS foi removido; destruir `terraform/cluster`; destruir `terraform/`; conferir sobras; so entao esvaziar e excluir o bucket S3 de estado. Este guia foi preparado e revisado, NAO executado.

Ultima atualizacao: 2026-09-11, Codex. Consultas AWS/Kubernetes e planos realizados entre 12:53 e 12:58 (-03:00). Branch dev, HEAD eb0bdf3.

## O que foi confirmado ao vivo

| Camada | Backend no bucket de estado | Resultado de plan -destroy | Conteudo principal |
|---|---|---|---|
| `terraform/k8s` | `prod/k8s.tfstate` | 0 criar / 0 alterar / 14 destruir | ArgoCD, Application, namespaces, Secrets, StorageClass e senhas geradas |
| `terraform/cluster` | `prod/cluster.tfstate` | 0 criar / 0 alterar / 35 destruir | EKS, nodes/addons, 2 RDS, Redis, IAM/IRSA, segredos |
| `terraform` | `prod/base.tfstate` | 0 criar / 0 alterar / 36 destruir | VPC/rede, NAT/EIP, 5 ECR, SQS/DLQ, DynamoDB e identidade do CI |

Os tres planos terminaram com exit code 0. Contagens sao objetos Terraform, incluindo senhas/associacoes; nao sao 85 servicos AWS independentes. Nao foi salvo plano binario nem copiado estado bruto. Todos os workspaces atuais sao `default`; `prod` e o prefixo das chaves S3, nao o workspace.

- Conta confirmada por STS: `891376952395`; regiao `us-east-2`; perfil disponivel nesta maquina: `default`.
- EKS `togglemaster`: ACTIVE, deletionProtection=false; RDS `togglemaster-auth` e `togglemaster-flag`, Redis e NAT ativos.
- Application `togglemaster`: Synced/Healthy e sem finalizers; Services consultados sao ClusterIP, nenhum Ingress.
- PVC `togglemaster/data-postgres-targeting-0`: Bound, 5 GiB, PV `pvc-935c205c-876d-4b5d-90ea-efa46ff30dfe`, politica Delete; disco `vol-04c33715bf3fe71bb` em uso.
- Bucket `togglemaster-tfstate-891376952395-us-east-2-an`: versionamento Enabled, contem os tres estados; bootstrap fora do Terraform.
- Nao foram encontrados snapshots EBS proprios nem snapshots manuais RDS em us-east-2 nas consultas desta sessao.
- A consulta IAM encontrou somente `togglemaster-github-actions` com confianca no OIDC do GitHub. Conferir novamente antes de excluir, pois o provider e global e pode ser compartilhado futuramente.

Fontes: `terraform workspace show`, `terraform state list` e `terraform plan -destroy -input=false -lock-timeout=30s -json` nas tres camadas; STS; APIs EKS/RDS/ElastiCache/EC2/ECR/S3/IAM/Resource Groups Tagging; consultas kubectl de Application/PVC/PV/Services/Ingress. O inventario nao abrange todas as regioes nem todos os servicos da conta.

## Antes de executar

Este e o encerramento definitivo: bancos, mensagens, tabela de analytics e imagens serao perdidos. Se precisar deles, conclua os exports/snapshots antes. Guardar o tfstate nao equivale a fazer backup dos dados da aplicacao.

- RDS: `skip_final_snapshot=true` e `deletion_protection=false` em [modules/rds/main.tf](../../../terraform/modules/rds/main.tf), linhas 147 e 151.
- Secrets Manager: `recovery_window_in_days=0`, no mesmo arquivo, linha 190.
- ECR: `force_delete=true` em [modules/ecr/main.tf](../../../terraform/modules/ecr/main.tf), linha 31: remove tambem as imagens.
- DynamoDB: `deletion_protection_enabled=false` em [modules/messaging/main.tf](../../../terraform/modules/messaging/main.tf), linha 110.

Combine a janela com os outros integrantes e aguarde/cancele pipelines de publicacao em andamento; desabilite temporariamente no GitHub Actions os cinco workflows de servico durante o encerramento. Os workflows atuais publicam no ECR, mas nao fazem terraform apply. Destruir a identidade do CI interrompe futuras publicacoes ate recriar a base.

Execute os blocos abaixo UM POR VEZ no PowerShell. Confira a saida antes do seguinte. Os blocos de plan/destroy incluem checks de exit code; nas consultas, confira tambem se cada comando terminou sem erro. Interrompa se houver falha. Nao use -auto-approve.

```powershell
# Entra no checkout autorizado do projeto.
Set-Location -LiteralPath 'C:\Users\Gabriel\Documents\GitHub\tech-challenge-03'
# Usa o perfil que foi efetivamente validado nesta maquina.
$env:AWS_PROFILE = 'default'
# Define a regiao do projeto para a AWS CLI.
$env:AWS_REGION = 'us-east-2'
# Confere a identidade; interrompe se nao for a conta esperada.
$conta = aws sts get-caller-identity --query Account --output text --no-cli-pager
if ($LASTEXITCODE -ne 0 -or $conta -ne '891376952395') { throw 'Conta AWS divergente ou credencial invalida.' }
# Mantem as operacoes Kubernetes presas ao cluster correto, mesmo se mudar o contexto ativo.
$KubeContext = 'arn:aws:eks:us-east-2:891376952395:cluster/togglemaster'
# Confere o checkout; o trabalho humano deste projeto usa dev.
git branch --show-current
# Mostra alteracoes locais para nao substituir configuracao de outra pessoa.
git status --short
```

Esta maquina ja esta inicializada nas tres camadas. Em outra maquina, rode `terraform -chdir=CAMADA init` para cada camada e confira o bucket/chave declarados nos respectivos backend.tf. Nao use `init -upgrade` durante o encerramento; preserve os lockfiles e os mesmos valores/arquivos de variaveis usados no apply. O arquivo tfvars da base nao e carregado automaticamente pelas subpastas.

```powershell
# Confere o workspace da base; nesta implantacao deve ser default.
terraform -chdir=terraform workspace show
# Lista o que a base conhece, sem mostrar valores de segredos.
terraform -chdir=terraform state list
# Confere o workspace do cluster.
terraform -chdir=terraform/cluster workspace show
# Lista os recursos controlados pelo cluster.
terraform -chdir=terraform/cluster state list
# Confere o workspace Kubernetes.
terraform -chdir=terraform/k8s workspace show
# Lista os recursos controlados pela camada Kubernetes.
terraform -chdir=terraform/k8s state list
```

Se houver erro de acesso/backend, estado vazio inesperado ou workspace diferente, pare e resolva a origem do estado. Nao crie um estado novo nem trate AccessDenied como ausencia de recursos.

## 1. Registrar o disco e encerrar a Application ArgoCD

O Terraform controla o namespace `togglemaster`, mas o disco foi criado pelo CSI do Kubernetes. Registre o vinculo antes de remover o namespace:

```powershell
# Descobre o PV usado pelo PostgreSQL targeting.
$TargetingPv = kubectl --context $KubeContext -n togglemaster get pvc data-postgres-targeting-0 -o jsonpath='{.spec.volumeName}'
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($TargetingPv)) { throw 'Nao foi possivel identificar o PV; conferir PVCs antes de continuar.' }
# Descobre o volume AWS correspondente ao PV.
$TargetingVolume = kubectl --context $KubeContext get pv $TargetingPv -o jsonpath='{.spec.csi.volumeHandle}'
if ($LASTEXITCODE -ne 0 -or $TargetingVolume -notmatch '^vol-[0-9a-f]+$') { throw 'Volume EBS nao identificado.' }
# Mostra identificadores nao secretos que serao verificados depois.
Write-Output "PV=$TargetingPv EBS=$TargetingVolume"
# Confere finalizers antes de excluir; nesta analise nao havia nenhum.
kubectl --context $KubeContext -n argocd get application togglemaster -o 'custom-columns=NAME:.metadata.name,FINALIZERS:.metadata.finalizers'
if ($LASTEXITCODE -ne 0) { throw 'Falha ao consultar a Application.' }
# Encerra a reconciliacao para nao disputar a exclusao do namespace com o Terraform.
kubectl --context $KubeContext -n argocd delete application togglemaster --wait=true --timeout=5m
if ($LASTEXITCODE -ne 0) { throw 'A exclusao da Application nao terminou; manter o cluster e investigar.' }
```

A exclusao antecipada da Application evita a possivel corrida entre `selfHeal/CreateNamespace` e o namespace sendo destruido. Sem finalizer, a Application desaparece, mas os workloads ficam para a exclusao do namespace no proximo passo. O refresh do Terraform reconhece sua ausencia; nao precisa `terraform state rm`. Se a Application ja tiver sido removida em uma tentativa anterior, confirme isso e prossiga sem recria-la. Se houver finalizer e a exclusao travar, mantenha ArgoCD/EKS operantes e diagnostique; nao force a retirada do finalizer.

Fonte: [k8s/argocd.tf](../../../terraform/k8s/argocd.tf), linhas 267-349, e [k8s/secrets.tf](../../../terraform/k8s/secrets.tf), linha 38. A Application depende do Helm, mas usa apenas a variavel do namespace de destino. [ArgoCD: exclusao e finalizers](https://argo-cd.readthedocs.io/en/stable/user-guide/app_deletion/), consultado em 2026-09-11.

## 2. Destruir Kubernetes, mantendo EKS/NAT/CSI vivos

```powershell
# Mostra a proposta de exclusao sem executar; a Application ja removida reduz a contagem.
terraform -chdir=terraform/k8s plan -destroy
if ($LASTEXITCODE -ne 0) { throw 'Plan k8s falhou; nao continuar.' }
```

Revise a proposta. Depois execute e digite `yes` somente se os alvos estiverem corretos:

```powershell
# Remove ArgoCD, namespaces, Secrets, StorageClass e demais objetos deste estado.
terraform -chdir=terraform/k8s destroy
if ($LASTEXITCODE -ne 0) { throw 'Destroy k8s incompleto; nao destruir o cluster.' }
```

## 3. Verificar que o EBS foi realmente excluido

```powershell
# Aguarda a remocao do PV com o driver EBS CSI ainda funcionando.
kubectl --context $KubeContext wait --for=delete "pv/$TargetingPv" --timeout=300s
if ($LASTEXITCODE -ne 0) { throw 'Conferir se o PV ja esta ausente ou se a exclusao falhou; nao derrubar o EKS ainda.' }
# Confere o disco pelo ID; uma lista vazia significa que ele nao existe mais.
aws ec2 describe-volumes --region us-east-2 --filters "Name=volume-id,Values=$TargetingVolume" --query 'Volumes[].{Id:VolumeId,State:State}' --output json --no-cli-pager
if ($LASTEXITCODE -ne 0) { throw 'Falha ao consultar EBS; ausencia nao confirmada.' }
```

A ultima saida deve ser `[]`. Se o PV ja nao existir, confirme pelo `kubectl get pv` e pela consulta EC2, pois a espera pode retornar NotFound dependendo da versao. Se houver outros PVs do projeto, confira tambem esses discos. Nao avance com um volume ainda `in-use`, `available` ou `deleting`.

A politica do PV foi confirmada como `Delete`, mas depende do CSI para remover o disco. Apagar apenas o StatefulSet nao garante apagar o PVC. Fonte: [k8s/storageclass.tf](../../../terraform/k8s/storageclass.tf), linha 61, [StatefulSet](../../../gitops/base/postgres-targeting/statefulset.yaml), linha 141, e [Kubernetes: Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/), consultado em 2026-09-11.

## 4. Destruir o cluster

```powershell
# Preve a exclusao de EKS, nodes, bancos, Redis, IAM/IRSA e segredos.
terraform -chdir=terraform/cluster plan -destroy
if ($LASTEXITCODE -ne 0) { throw 'Plan cluster falhou; nao continuar.' }
```

Revise a proposta e depois confirme a destruicao:

```powershell
# Executa a exclusao dos recursos da camada cluster.
terraform -chdir=terraform/cluster destroy
if ($LASTEXITCODE -ne 0) { throw 'Destroy cluster incompleto; preservar a base e o bucket.' }
```

## 5. Destruir a base

```powershell
# Preve a exclusao da VPC/rede, NAT/EIP, ECR/imagens, SQS, DynamoDB e identidade CI.
terraform -chdir=terraform plan -destroy
if ($LASTEXITCODE -ne 0) { throw 'Plan base falhou; nao continuar.' }
```

Revise a proposta e depois confirme a destruicao:

```powershell
# Encerra a base; nesta modalidade nao e necessario desligar NAT com apply separado.
terraform -chdir=terraform destroy
if ($LASTEXITCODE -ne 0) { throw 'Destroy base incompleto; manter o bucket e diagnosticar.' }
```

Se houver DependencyViolation na VPC/subnet, identifique ENIs, interfaces de servicos ou balanceadores remanescentes e sua propriedade antes de excluir. Retome o destroy da camada que falhou apos resolver a dependencia; nao apague state/lock para esconder recursos.

## 6. Conferencia final, antes de apagar o backend

- Confira que os tres `terraform state list` nao mostram recursos gerenciados restantes; data sources eventualmente retidos nao sao recursos cobrados.
- Confira EKS, EC2/node groups, RDS, ElastiCache, NAT e Elastic IPs do projeto. NAT pode aparecer temporariamente como `deleted`, o que e diferente de `available` ou `deleting`.
- Confira EBS, snapshots/backups manuais ou retidos, Load Balancers, interfaces de rede e grupos de logs. Eles podem existir fora do Terraform.
- Confira os cinco ECR, as duas filas SQS, `ToggleMasterAnalytics`, os segredos `togglemaster/*` e IAM/OIDC. APIs regionais nao verificam IAM nem outras regioes.

```powershell
# Lista os recursos que ainda respondem com as tags do projeto nesta regiao.
aws resourcegroupstaggingapi get-resources --region us-east-2 --tag-filters Key=project,Values=fiap Key=phase,Values=3 --query 'ResourceTagMappingList[].ResourceARN' --no-cli-pager
# Procura discos criados pelo CSI para este cluster, que podem nao ter project/phase.
aws ec2 describe-volumes --region us-east-2 --filters Name=tag:ebs.csi.aws.com/cluster-name,Values=togglemaster --query 'Volumes[].{Id:VolumeId,State:State}' --no-cli-pager
# Confere o EKS pelo inventario regional.
aws eks list-clusters --region us-east-2 --no-cli-pager
# Confere bancos e seus estados.
aws rds describe-db-instances --region us-east-2 --query 'DBInstances[].{Id:DBInstanceIdentifier,State:DBInstanceStatus}' --no-cli-pager
# Confere o Redis.
aws elasticache describe-replication-groups --region us-east-2 --query 'ReplicationGroups[].{Id:ReplicationGroupId,State:Status}' --no-cli-pager
# Lista NATs para distinguir os removidos dos ainda ativos.
aws ec2 describe-nat-gateways --region us-east-2 --query 'NatGateways[].{Id:NatGatewayId,State:State}' --no-cli-pager
# Confere IPs elastico ainda alocados.
aws ec2 describe-addresses --region us-east-2 --query 'Addresses[].{Id:AllocationId,Tags:Tags}' --no-cli-pager
```

Essa lista auxilia a conferencia; tags e estados Terraform vazios nao provam que toda a conta esta vazia. Nao excluir recursos de outros projetos. [AWS: cuidados antes de excluir EKS](https://docs.aws.amazon.com/eks/latest/userguide/delete-cluster.html), consultado em 2026-09-11.

A tag `ebs.csi.aws.com/cluster-name=togglemaster` foi observada no disco desta implantacao em 2026-09-11; nao e uma garantia para qualquer versao do CSI ou disco criado manualmente. Complemente com `aws ec2 describe-volumes --region us-east-2 --query 'Volumes[].{Id:VolumeId,State:State,Tags:Tags}' --output json --no-cli-pager` e identifique a propriedade dos volumes remanescentes.

## 7. Apagar o bucket de estado por ultimo

O bucket foi criado manualmente e nao aparece em nenhum dos tres states. Portanto, os tres destroys nao o apagam. Fonte: [BOOTSTRAP-BACKEND-S3.md](../../../terraform/BOOTSTRAP-BACKEND-S3.md), registro da criacao em 2026-08-27 e consulta viva do versionamento em 2026-09-11.

Somente depois de concluir a conferencia final e encerrar qualquer processo Terraform:

1. Se precisar preservar historico para auditoria, defina antes uma copia protegida, fora do Git; os estados antigos contem segredos. Nesta analise nenhuma copia foi criada.
2. No console AWS, abra S3 e selecione exatamente `togglemaster-tfstate-891376952395-us-east-2-an`.
3. Use **Esvaziar / Empty** e confirme a remocao de todos os objetos, versoes e marcadores de exclusao. Aguarde o sucesso.
4. Volte a lista e use **Excluir / Delete** para o bucket.

`aws s3 rb --force` nao elimina versoes antigas de um bucket versionado. O estado/backups/locks precisam continuar disponiveis ate concluir os destroys; apagar o bucket primeiro quebra o backend. [AWS: excluir bucket versionado](https://docs.aws.amazon.com/AmazonS3/latest/userguide/delete-bucket.html), consultado em 2026-09-11.

Usuarios IAM de acesso manual, como a identidade local utilizada nesta sessao, tambem nao sao removidos por esses states. So desative credenciais/identidades exclusivas do projeto depois de encerrar a limpeza e verificar que nao servem a outro trabalho. O procedimento nao fecha a conta AWS nem apaga cobrancas ja incorridas.

## Se a intencao for apenas pausar entre sessoes

D-017 continua valida: execute a limpeza k8s/EBS/cluster acima, preserve a base e o bucket, defina `enable_nat_gateway=false` em `terraform/terraform.tfvars` e rode `terraform -chdir=terraform apply`, revisando que o plano so remove NAT/EIP/rota correspondente. Essa alternativa preserva ECR/imagens, SQS e DynamoDB; nao e exclusao completa e pode manter custos de armazenamento/uso.

CONFLITO DOCUMENTAL F-050: [README Terraform](../../../terraform/README.md), linha 58, chama k8s destroy de opcional, enquanto [RUNBOOK-SESSAO](../../OPERACAO.md), fase 4, exige essa etapa. Os originais foram preservados; este guia explicita a necessidade operacional de remover PVC/EBS com EKS/CSI vivos, sem assumir que o cluster leva todo armazenamento junto.

## Limite da verificacao

Os comandos de consulta e os tres planos foram executados; a destruicao, a espera pela exclusao do disco e o esvaziamento do bucket NAO foram executados. O resultado de plan e uma previsao, nao prova de que as APIs vao concluir o destroy sem dependencias externas. Repita os planos e consultas quando for executar; apos excluir a Application, o plano k8s pode cair de 14 para 13 objetos.

[HashiCorp: terraform destroy e plan -destroy](https://developer.hashicorp.com/terraform/cli/commands/destroy), consultado em 2026-09-11: plan apenas mostra a proposta; destroy solicita confirmacao e executa a exclusao do que e gerenciado pelo estado atual.
