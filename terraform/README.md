# Terraform - ToggleMaster Fase 3

TL;DR: infraestrutura AWS do ToggleMaster em `us-east-2`. O apply e dividido em etapas para que o pipeline de CI possa ser construido sem esperar os ~25 minutos do EKS. A Etapa 1 esta pronta; as Etapas 2 e 3 ainda nao foram escritas.

Ultima atualizacao: 2026-08-27 15:20 -03:00, Claude.

## Antes de comecar

1. Bucket de estado ja criado - ver [`BOOTSTRAP-BACKEND-S3.md`](BOOTSTRAP-BACKEND-S3.md).
2. Terraform **>= 1.11** (`use_lockfile` nao existe antes disso).
3. Perfil AWS configurado: `aws configure --profile togglemaster` com regiao `us-east-2`.

```bash
export AWS_PROFILE=togglemaster
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
```

## Etapas

O apply e dividido de proposito. A Etapa 1 e barata e roda em minutos; a Etapa 2 e cara e lenta.

| Etapa | O que cria | Tempo | Custo/mes | Situacao |
|---|---|---|---|---|
| **1** | VPC, subnets, IGW, ECR (5), SQS + DLQ, DynamoDB, OIDC + role do CI | ~5 min | ~US$ 0 sem NAT | **Pronta** |
| **2** | NAT, EKS + node group, 3 RDS, ElastiCache | ~25 min | ~US$ 190 | A escrever |
| **3** | ArgoCD e External Secrets Operator (root separado em `argocd/`) | ~5 min | US$ 0 | A escrever |

A Etapa 1 sozinha ja entrega o que o pipeline de CI precisa: os 5 repositorios ECR e a role OIDC. Isso permite construir os workflows de DevSecOps (O-10 a O-21) em paralelo com a Etapa 2.

## Estrutura

```text
terraform/
├── backend.tf                  # estado remoto no S3 + use_lockfile
├── providers.tf                # provider AWS + default_tags (D-009)
├── variables.tf                # entradas, todas com padrao
├── main.tf                     # composicao dos modulos
├── outputs.tf                  # valores consumidos pelo CI e pelo gitops/
├── terraform.tfvars.example
└── modules/
    ├── ecr/                    # 5 repositorios + lifecycle
    ├── messaging/              # SQS + DLQ + DynamoDB
    └── iam-ci/                 # OIDC do GitHub + role do CI
```

A VPC usa o modulo oficial `terraform-aws-modules/vpc/aws` (D-010). Os demais sao modulos proprios.

## Decisoes que valem explicacao

**NAT Gateway desligado por padrao no `terraform.tfvars.example`.** Na Etapa 1 nao ha nada em subnet privada, entao o NAT so geraria custo. Ao comecar a Etapa 2, troque para `true` - sem ele os nos do EKS nao baixam imagem.

**`force_delete = true` nos repositorios ECR.** Sem isso o `terraform destroy` falha em repositorio com imagem dentro. Como a estrategia de custo depende de destruir e recriar entre sessoes (S-09), o destroy precisa funcionar sem intervencao manual.

**Tags mutaveis no ECR.** `IMMUTABLE` e a opcao endurecida e combina com tag por commit hash, mas faz falhar qualquer re-execucao do workflow sobre o mesmo commit - o que acontece com frequencia durante a gravacao do video. Trocar e uma linha em `variables.tf`.

**Dead-letter queue na SQS.** Nao e exigida. Mas o `analytics-service` so apaga a mensagem depois de gravar no DynamoDB com sucesso, entao uma mensagem malformada voltaria para a fila para sempre.

**Role do CI restrita a um repositorio.** A condicao `repo:<owner>/<repo>:*` na policy de confianca e o que impede qualquer outro repositorio do GitHub de assumir a role. Sem ela, o OIDC vira uma porta aberta.

## Custo

O que pesa esta na Etapa 2: EKS control plane (~US$ 73/mes mesmo com zero nos), 2 nos `t3.medium` (~US$ 60), NAT (~US$ 33), 3 RDS `db.t3.micro` (~US$ 44) e ElastiCache (~US$ 12).

Como o control plane cobra mesmo parado, escalar o node group para zero economiza pouco. A economia real vem de `terraform destroy` completo entre as sessoes de trabalho, ao custo de ~25 minutos para reconstruir.

Estes numeros sao aproximados. O print exigido em O-39 deve sair do AWS Pricing Calculator.

## Nunca versionar

`terraform.tfstate`, `terraform.tfvars`, `.terraform/` e qualquer arquivo com credencial. O `.gitignore` da raiz ja cobre esses padroes. O `.terraform.lock.hcl`, ao contrario, **deve** ser versionado: e ele que garante que todos do grupo usem exatamente a mesma versao de provider.
