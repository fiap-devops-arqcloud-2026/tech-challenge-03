# Terraform do ToggleMaster

Esta pasta cria, por código, toda a infraestrutura AWS do projeto. Tecnicamente, são três raízes Terraform (camadas) em `us-east-2`, cada uma com estado próprio no S3, e cada camada lê as saídas da anterior por `terraform_remote_state`.

## Camadas

| Pasta | O que cria | Chave de estado | Lê de |
|---|---|---|---|
| `terraform/` (base) | VPC com subnets públicas e privadas, IGW e NAT; 5 repositórios ECR; SQS com DLQ; DynamoDB; provedor OIDC do GitHub (criado ou só lido) e role do CI | `prod/base.tfstate` | nada (só precisa do bucket de estado, criado à mão) |
| `terraform/cluster/` | EKS com node group e addons; 2 RDS PostgreSQL com senhas no Secrets Manager; ElastiCache Redis; roles IRSA | `prod/cluster.tfstate` | estado da base |
| `terraform/k8s/` | ArgoCD via Helm e a Application; 5 Secrets; StorageClass `gp3` padrão | `prod/k8s.tfstate` | estados da base e do cluster |

Suba na ordem base → (imagens publicadas no ECR) → cluster → k8s. Destrua na ordem inversa: k8s → cluster → base. O destroy da camada k8s **não é opcional**: é ele que remove o PVC e, com isso, o disco EBS do banco do targeting, que não pertence a nenhum estado.

A base custa quase nada parada e é preservável entre sessões, mas também pode ser destruída. A camada k8s fica separada do cluster porque os providers `kubernetes` e `helm` precisam de um endpoint que só existe depois do apply do cluster. O primeiro apply da k8s é feito em duas etapas, por causa do CRD do ArgoCD.

## Estrutura

```text
terraform/
├── backend.tf               # estado prod/base.tfstate
├── providers.tf             # provider AWS e default_tags
├── variables.tf
├── main.tf                  # composição dos módulos da base
├── outputs.tf               # lidos pelo CI, pelo gitops/ e pelas outras camadas
├── terraform.tfvars.example
├── .terraform.lock.hcl
├── modules/
│   ├── ecr/                 # 5 repositórios e lifecycle
│   ├── messaging/           # SQS, DLQ e DynamoDB
│   ├── iam-ci/              # provedor OIDC do GitHub e role do CI
│   ├── eks/                 # cluster, node group, addons e OIDC do cluster
│   ├── rds/                 # as 2 instâncias PostgreSQL
│   ├── elasticache/         # Redis
│   └── irsa/                # roles assumidas pelos pods
├── cluster/                 # backend, data (lê a base), providers, variables, main, outputs
└── k8s/                     # backend, data (lê base e cluster), providers,
                             # secrets, storageclass, argocd, variables, outputs
```

A VPC usa o módulo da comunidade `terraform-aws-modules/vpc/aws`; os demais módulos são próprios.

## Variáveis que mais importam

| Variável | Camada | Padrão | Quando mudar |
|---|---|---|---|
| `create_github_oidc_provider` | base | `true` | `false` se a conta já tiver o provedor `token.actions.githubusercontent.com` (com `false`, ele só é lido e nunca é destruído) |
| `enable_nat_gateway` | base | `true` | Mantenha `true` para o cluster; o `terraform.tfvars.example` vem com `false` |
| `github_repository` | base | `fiap-devops-arqcloud-2026/tech-challenge-03` | Em outra cópia do repositório (`<owner>/<repo>`) |
| `kubernetes_version` | cluster | `1.34` | Quando a versão sair do suporte padrão da AWS (a 1.34 fica até 2026-12-01) |
| `node_instance_type` | cluster | `c7i-flex.large` | Se a conta recusar o tipo |
| `github_token` | k8s | `""` | Só se a cópia do repositório for privada |

Recomenda-se um `terraform.tfvars` local por camada, ignorado pelo `.gitignore`: assim o apply e o destroy leem os mesmos valores. Veja a [seção 2 do guia](../docs/GUIA_DE_REPRODUCAO.md#2-valores-fixos-a-trocar-em-outra-conta).

## Validação local (os mesmos passos do Terraform Check do CI, sem AWS)

```bash
# Confere a formatação de todos os arquivos .tf, sem alterar nada
terraform fmt -check -recursive terraform
# Baixa os providers da base sem conectar ao backend S3
terraform -chdir=terraform init -backend=false -input=false
# Valida sintaxe e referências da base
terraform -chdir=terraform validate
# Baixa os providers da camada cluster sem conectar ao backend S3
terraform -chdir=terraform/cluster init -backend=false -input=false
# Valida sintaxe e referências da camada cluster
terraform -chdir=terraform/cluster validate
# Baixa os providers da camada k8s sem conectar ao backend S3
terraform -chdir=terraform/k8s init -backend=false -input=false
# Valida sintaxe e referências da camada k8s
terraform -chdir=terraform/k8s validate
```

O `.terraform.lock.hcl` de cada camada **deve** ser versionado; `terraform.tfstate`, `*.tfvars`, `*.tfplan` e `.terraform/` nunca.

## Onde está o resto

- Passo a passo completo de subida e destruição: [docs/GUIA_DE_REPRODUCAO.md](../docs/GUIA_DE_REPRODUCAO.md)
- Criação do bucket de estado: [guia, seção 3](../docs/GUIA_DE_REPRODUCAO.md#3-bucket-de-estado-do-terraform)
- Por que três camadas e as demais escolhas: [README, seção 5](../README.md#5-decisões-e-o-porquê)
- Recursos, variáveis e versões em detalhe: [docs/ARQUITETURA.md](../docs/ARQUITETURA.md)
- Custo: [README, seção 8](../README.md#8-custo)
