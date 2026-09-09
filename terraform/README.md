# Terraform - ToggleMaster Fase 3

TL;DR: infraestrutura AWS em `us-east-2`, dividida em **duas camadas com estados separados**. A camada `terraform/` custa ~US$ 0 e fica de pe permanentemente; a camada `terraform/cluster/` custa ~US$ 0,37/h e e destruida ao fim de cada sessao.

Ultima atualizacao: 2026-08-27 20:40 -03:00, Claude.

## Antes de comecar

1. Bucket de estado ja criado - ver [`BOOTSTRAP-BACKEND-S3.md`](BOOTSTRAP-BACKEND-S3.md).
2. Terraform **>= 1.11** (`use_lockfile` nao existe antes disso). Em uso: 1.16.0.
3. Perfil AWS configurado: `aws configure --profile togglemaster`, regiao `us-east-2`.

## As duas camadas (D-017)

| | `terraform/` (base) | `terraform/cluster/` |
|---|---|---|
| **O que tem** | VPC, subnets, IGW, 5 repositorios ECR, SQS + DLQ, DynamoDB, OIDC + role do CI | EKS, node group, 2 RDS, ElastiCache, roles IRSA, segredos |
| **Estado** | `prod/base.tfstate` | `prod/cluster.tfstate` |
| **Custo parado** | ~US$ 0 | ~US$ 0,37/h |
| **Ciclo de vida** | aplicada uma vez, **nunca destruida** | sobe e desce a cada sessao |
| **Situacao** | escrita e validada | fiacao pronta; recursos na Fase B |

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
# ... ensaio ou gravacao ...
terraform -chdir=terraform/cluster destroy   # ~15 min, para de cobrar
```

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
├── cluster/                    # camada efemera
│   ├── backend.tf              #   estado prod/cluster.tfstate
│   ├── data.tf                 #   le o estado da base
│   ├── providers.tf
│   ├── variables.tf
│   ├── main.tf                 #   recursos entram na Fase B
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

| Camada | US$/h |
|---|---|
| Base (VPC, ECR, SQS, DynamoDB, IAM) | ~0,00 |
| Cluster: EKS control plane | 0,100 |
| Cluster: 2x `c7i-flex.large` | 0,170 |
| Cluster: NAT Gateway | 0,045 |
| Cluster: 2x `db.t3.micro` | 0,036 |
| Cluster: ElastiCache `t3.micro` | 0,017 |
| **Total com o cluster de pe** | **~0,37** |

Uma sessao de 3 horas custa cerca de US$ 1,10. Numeros aproximados: o print exigido em O-39 deve sair do AWS Pricing Calculator.

## Nunca versionar

`terraform.tfstate`, `terraform.tfvars`, `.terraform/` e qualquer arquivo com credencial. O `.gitignore` da raiz cobre esses padroes. O `.terraform.lock.hcl`, ao contrario, **deve** ser versionado: e ele que garante que todos do grupo usem a mesma versao de provider.
