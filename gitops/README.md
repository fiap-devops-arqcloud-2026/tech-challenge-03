# GitOps - manifestos do ToggleMaster

TL;DR: esta pasta e a fonte da verdade do que roda no cluster. Ninguem faz `kubectl apply` daqui: o ArgoCD observa este diretorio e ajusta o EKS sozinho. Derivada de `infra/k8s/` da Fase 2 (D-014), com Kustomize (D-008) e ambiente unico `prod` (D-011).

## Por que esta pasta existe

A primeira queixa do enunciado e literal:

> "Os desenvolvedores estao rodando kubectl apply de suas maquinas locais, gerando conflitos de versao."

Com GitOps isso acaba. O estado desejado vive no Git; o ArgoCD reconcilia o cluster com ele. Se alguem mexer no cluster na mao, o ArgoCD desfaz.

## Estrutura

```text
gitops/
├── base/                       # o que NAO muda entre ambientes
│   ├── kustomization.yaml      # indice de todos os manifestos
│   ├── namespace.yaml
│   ├── auth-service/           # deployment, service, configmap
│   ├── flag-service/
│   ├── targeting-service/
│   ├── evaluation-service/     # + hpa, serviceaccount (IRSA)
│   ├── analytics-service/      # + hpa, serviceaccount (IRSA), sem segredo
│   └── postgres-targeting/     # o 3o banco, em pod (D-015)
└── overlays/prod/              # o que depende da AWS
    ├── kustomization.yaml      # images: <- alterado pelo CI (O-24)
    └── patches/
        ├── irsa.yaml           # ARNs das roles IAM
        └── endpoints.yaml      # REDIS_URL e AWS_SQS_URL
```

**Nao ha nenhum arquivo de Secret aqui, e isso e intencional.** Os 5
Secrets sao criados por `terraform/k8s/secrets.tf` (D-018). O acoplamento
entre os dois lados - nome do Secret, nome da chave, e quais valores
precisam coincidir - esta escrito em
[`SECRETS-CONTRATO.md`](SECRETS-CONTRATO.md). Leia antes de renomear
qualquer coisa: o erro tipico e o pod parar em
`CreateContainerConfigError` sem o ArgoCD acusar nada, porque do ponto
de vista dele o manifesto foi aplicado com sucesso.

Conferir o resultado renderizado, sem aplicar nada:

```bash
kubectl kustomize gitops/overlays/prod
```

## O que mudou em relacao a Fase 2

| Item | Fase 2 | Aqui | Motivo |
|---|---|---|---|
| Tag da imagem | `:latest` fixa no deployment | nome logico + bloco `images:` no overlay | permite `kustomize edit set image` no CI (O-24) |
| `imagePullPolicy` | `Always` | removido | era muleta do `:latest`; tag por commit e imutavel |
| Segredos | `secret.yaml` versionado com placeholder | criados por `terraform/k8s/secrets.tf` | nenhum valor no Git (D-018) |
| Acesso a AWS | `AWS_ACCESS_KEY_ID` em Secret do K8s | IRSA na ServiceAccount | credencial temporaria, nada a vazar (S-06) |
| `AWS_SQS_URL` | dentro do Secret | ConfigMap | URL de fila nao e segredo |
| Ingress | nginx com 5 rotas | removido | enunciado nao exige (F-018), economiza ~US$ 16-20/mes |
| Namespace | repetido em cada arquivo | uma vez no `kustomization.yaml` | forma idiomatica do Kustomize |

O `analytics-service` ficou **sem nenhum segredo**. Depois do IRSA, tudo que ele precisa e configuracao publica.

## Ordem de aplicacao

Esta pasta so pode ser sincronizada depois que o cluster existir. A
ordem, e o motivo de cada passo:

1. **Camada base** (`terraform/`) - **aplicada** em 2026-09-07: ECR, SQS, DynamoDB, rede, OIDC.
2. **Camada cluster** (`terraform/cluster/`): EKS, node group, 2 RDS, ElastiCache e as roles de IRSA. Sem ela nao ha para onde sincronizar.
3. **Camada k8s** (`terraform/k8s/`), em duas etapas: instala o ArgoCD, cria os 5 Secrets e a StorageClass `gp3`, e por fim a `Application` apontando para `gitops/overlays/prod`.
4. Preencher os placeholders em `overlays/prod/patches/` com os `terraform output` da sessao e levar isso ate a `main` por PR - o ArgoCD le do Git, nao do disco.

A partir dai o ArgoCD assume: qualquer commit em `gitops/` na `main`
vira mudanca no cluster, sem `kubectl apply` de ninguem (O-26).

> **Nota historica:** ate 2026-09-08 o plano era usar o External Secrets
> Operator lendo o AWS Secrets Manager (D-013). O ESO foi cortado em
> D-018 para tirar uma peca de runtime do caminho critico a uma semana
> da entrega. Se voce encontrar mencao a `ExternalSecret` ou
> `ClusterSecretStore` em algum documento antigo, ela esta desatualizada.

## Placeholders a preencher

| Arquivo | Chave | De onde vem |
|---|---|---|
| `patches/irsa.yaml` | ARNs das duas roles | `terraform -chdir=terraform/cluster output irsa_role_arns` |
| `patches/endpoints.yaml` | `REDIS_URL` | `terraform -chdir=terraform/cluster output redis_url` — hoje contem a palavra `PREENCHER`; o passo 1.5 do runbook tem o comando que troca sozinho |
| `patches/endpoints.yaml` | `AWS_SQS_URL` | `terraform -chdir=terraform output sqs_queue_url` (camada base, ja aplicada) |
| `overlays/prod/kustomization.yaml` | `newTag` das 5 imagens | preenchido sozinho pelo CI |

## Armadilhas conhecidas

- **PVC Pending.** O `volumeClaimTemplates` do `postgres-targeting` nao declara `storageClassName`, entao depende de haver uma StorageClass default. Na Fase 2 nao havia e o deploy travou (F-025). A Etapa 2 do Terraform resolve isso por codigo (P-035).
- **HPA sem metrica.** Os dois HPAs precisam do Metrics Server instalado, senao ficam com `<unknown>` e nunca escalam.
- **Senha divergente.** O `targeting-service` e o `postgres-targeting` leem o **mesmo** segredo da AWS (`togglemaster/targeting-db`), de proposito. Nao criar dois segredos separados.
