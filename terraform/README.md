# Terraform - ToggleMaster Fase 3

TL;DR: infraestrutura AWS em `us-east-2`, dividida em **tres camadas com estados separados**. Esse desenho permite aplicar e destruir o ambiente de forma controlada. A pilha completa funcionou em 2026-09-11 e foi destruida no mesmo dia; em 2026-09-14, os tres estados estavam vazios e nenhum recurso da pilha permanecia ativo.

## Antes de comecar

1. Bucket de estado ja criado - ver [`BOOTSTRAP-BACKEND-S3.md`](BOOTSTRAP-BACKEND-S3.md).
2. Terraform **>= 1.11** (`use_lockfile` nao existe antes disso). Em uso: 1.16.0.
3. Perfil AWS configurado: `aws configure --profile togglemaster`, regiao `us-east-2`.

## As tres camadas (D-017)

| | `terraform/` (base) | `terraform/cluster/` | `terraform/k8s/` |
|---|---|---|---|
| **O que tem** | VPC, subnets, IGW, 5 repositorios ECR, SQS + DLQ, DynamoDB, OIDC + role do CI | EKS, node group, 2 RDS, ElastiCache, roles IRSA | 5 Secrets, StorageClass `gp3`, ArgoCD e a Application |
| **Onde age** | na conta AWS | na conta AWS | dentro do cluster, pela API do Kubernetes |
| **Estado** | `prod/base.tfstate` | `prod/cluster.tfstate` | `prod/k8s.tfstate` |
| **Providers** | aws | aws, random, tls | kubernetes, helm |
| **Custo parado** | ~US$ 0 | ~US$ 0,385/h | ~US$ 0 (vive dentro do cluster) |
| **Ciclo normal** | pode ser preservada entre sessoes | sobe e desce a cada sessao | sobe e desce antes do cluster |
| **Situacao em 2026-09-14** | destruida; estado vazio | destruida; estado vazio | destruida; estado vazio |

Historico comprovado: em 2026-09-11, as tres camadas foram aplicadas. A consulta registrou EKS `ACTIVE`, dois RDS, Redis, NAT, ArgoCD `Synced/Healthy` e o PVC do targeting ligado a um EBS. Depois do ensaio, houve encerramento completo da AWS. Esse historico comprova que o codigo foi executado, mas nao significa que a infraestrutura esteja ativa hoje.

Por que a terceira camada existe separada da segunda: os providers
`kubernetes` e `helm` precisam de um endereco de cluster que **so passa
a existir depois** do apply da camada `cluster/`. No mesmo estado, o
Terraform teria de configurar um provider com um valor que ele proprio
ainda vai criar - o classico erro de "provider configuration depends on
resource attributes". Separar resolve sem giria: primeiro cria-se o
cluster, depois fala-se com ele.

### Por que separar

Se as duas dividissem o mesmo estado, o `terraform destroy` feito para parar de gastar credito levaria junto os repositorios ECR. Como eles usam `force_delete = true`, **as imagens iriam junto** - e o CI teria de reconstruir e reenviar as 5 imagens antes de cada sessao de trabalho.

Com estados separados, o ciclo fica:

```bash
export AWS_PROFILE=togglemaster

# uma vez so, e pronto
terraform -chdir=terraform init
terraform -chdir=terraform apply

# a cada sessao de trabalho
terraform -chdir=terraform/cluster init
terraform -chdir=terraform/cluster apply     # ~25 min, comeca a cobrar

aws eks update-kubeconfig --name togglemaster --region us-east-2

terraform -chdir=terraform/k8s init
terraform -chdir=terraform/k8s apply -target=helm_release.argocd   # etapa A
terraform -chdir=terraform/k8s apply                               # etapa B

# ... ensaio ou gravacao ...

terraform -chdir=terraform/k8s destroy       # opcional: o destroy abaixo leva junto
terraform -chdir=terraform/cluster destroy   # ~15 min, para de cobrar
```

O apply da camada `k8s/` e **em duas etapas** de proposito. O recurso
`kubernetes_manifest` da Application do ArgoCD confere o tipo dela
contra o cluster ainda no `plan` - e o tipo so passa a existir depois
que o proprio ArgoCD e instalado. O `-target` da etapa A instala o
ArgoCD primeiro; a etapa B, ja com o tipo disponivel, cria o resto
(F-043; detalhe completo no topo de `k8s/argocd.tf`).

O ECR, as imagens, a fila e a tabela continuam intactos entre uma sessao e outra.

### Como as camadas conversam

A camada `cluster/` **le** o estado da base por `terraform_remote_state` (ver `cluster/data.tf`) para descobrir VPC, subnets e os ARNs da fila e da tabela. E somente leitura: ela nunca altera o estado da base.

Consequencia pratica: **`cluster/` nao roda antes de a base ter sido aplicada.** O `plan` falha dizendo que nao encontrou o estado - e o comportamento correto.

## Estrutura

```text
terraform/
├── backend.tf                  # estado prod/base.tfstate
├── providers.tf                # provider AWS + default_tags (D-009)
├── variables.tf
├── main.tf                     # composicao dos modulos
├── outputs.tf                  # consumidos pelo CI, pelo gitops/ e por cluster/
├── terraform.tfvars.example
├── modules/
│   ├── ecr/                    # 5 repositorios + lifecycle
│   ├── messaging/              # SQS + DLQ + DynamoDB
│   └── iam-ci/                 # OIDC do GitHub + role do CI
│   ├── eks/                    # cluster, node group e provedor OIDC
│   ├── rds/                    # as 2 instancias PostgreSQL
│   ├── elasticache/            # Redis
│   └── irsa/                   # roles assumidas pelos pods (S-06)
├── cluster/                    # camada efemera
│   ├── backend.tf              #   estado prod/cluster.tfstate
│   ├── data.tf                 #   le o estado da base
│   ├── providers.tf
│   ├── variables.tf
│   ├── main.tf                 #   EKS, RDS, ElastiCache, IRSA
│   └── outputs.tf
├── k8s/                        # camada de objetos dentro do cluster
│   ├── backend.tf              #   estado prod/k8s.tfstate
│   ├── data.tf                 #   le o estado da base E o do cluster
│   ├── providers.tf            #   kubernetes e helm, autenticados por
│   │                           #   `aws eks get-token`
│   ├── secrets.tf              #   namespace + os 5 Secrets (D-018)
│   ├── storageclass.tf         #   gp3 como padrao (F-025)
│   ├── argocd.tf               #   chart do ArgoCD + a Application
│   ├── variables.tf
│   └── outputs.tf
└── BOOTSTRAP-BACKEND-S3.md
```

A VPC usa o modulo oficial `terraform-aws-modules/vpc/aws` (D-010). Os demais sao modulos proprios.

## Decisoes que valem explicacao

**NAT Gateway desligado por padrao no `terraform.tfvars.example`.** Enquanto so a base existir, nada roda em subnet privada e o NAT so geraria custo (~US$ 33/mes). Antes do primeiro apply de `cluster/`, troque para `true` - sem ele os nos do EKS nao baixam imagem.

**`force_delete = true` nos repositorios ECR.** Sem isso, um `terraform destroy` falharia em repositorio com imagem dentro. Na pratica a base nao e destruida, mas a flag garante que o teardown final, depois da entrega, funcione sem intervencao manual.

**Tags mutaveis no ECR.** `IMMUTABLE` e a opcao endurecida e combina com tag por commit hash, mas faz falhar qualquer re-execucao do workflow sobre o mesmo commit - o que acontece com frequencia durante a gravacao. Trocar e uma linha em `variables.tf`.

**Dead-letter queue na SQS.** Nao e exigida. Mas o `analytics-service` so apaga a mensagem depois de gravar no DynamoDB com sucesso, entao uma mensagem malformada voltaria para a fila para sempre.

**Role do CI restrita a um repositorio.** A condicao `repo:<owner>/<repo>:*` na policy de confianca e o que impede qualquer outro repositorio do GitHub de assumir a role. Sem ela, o OIDC vira porta aberta.

**Provider AWS sem teto de versao.** Fixar `~> 6.0` conflitava com a restricao interna do modulo de VPC e travava o `terraform init`. A restricao ficou `>= 5.46` e quem trava a versao exata e o `.terraform.lock.hcl`, versionado no Git. Resolveu para provider 6.62.0 com modulo VPC 5.21.0.

## Custo

Valores derivados da estimativa oficial no AWS Pricing Calculator, consultada em
11/09/2026 para a regiao `us-east-2`: US$ 281,03 por mes com tudo ligado as 730
horas. Dividido por 730, da o custo por hora abaixo.

| Item | US$/h | US$/mes |
|---|---|---|
| Base (VPC, ECR, SQS, DynamoDB, IAM) | ~0,000 | ~0,00 |
| Cluster: EKS control plane | 0,100 | 73,00 |
| Cluster: 2x `c7i-flex.large` | 0,174 | 126,99 |
| Cluster: NAT Gateway e IPv4 publico | 0,050 | 36,54 |
| Cluster: 2x RDS `db.t3.micro` | 0,042 | 30,88 |
| Cluster: ElastiCache `cache.t3.micro` | 0,017 | 12,41 |
| Cluster: volume EBS do banco em pod | 0,001 | 0,40 |
| Cluster: Secrets Manager | 0,001 | 0,81 |
| **Total com o cluster de pe** | **0,385** | **281,03** |

Uma sessao de 3 horas custa cerca de **US$ 1,15**. A diferenca entre manter o
ambiente ligado o mes inteiro e liga-lo so quando precisa - de US$ 281 para
pouco mais de um dolar por sessao - e exatamente o que justifica a divisao em
camadas descrita acima.

## Nunca versionar

`terraform.tfstate`, `terraform.tfvars`, `.terraform/` e qualquer arquivo com credencial. O `.gitignore` da raiz cobre esses padroes. O `.terraform.lock.hcl`, ao contrario, **deve** ser versionado: e ele que garante que todos do grupo usem a mesma versao de provider.
