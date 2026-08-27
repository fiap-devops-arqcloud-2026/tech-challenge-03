# GitOps - manifestos do ToggleMaster

TL;DR: esta pasta e a fonte da verdade do que roda no cluster. Ninguem faz `kubectl apply` daqui: o ArgoCD observa este diretorio e ajusta o EKS sozinho. Derivada de `infra/k8s/` da Fase 2 (D-014), com Kustomize (D-008) e ambiente unico `prod` (D-011).

Ultima atualizacao: 2026-08-27 18:30 -03:00, Claude.

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
│   ├── auth-service/           # deployment, service, configmap, externalsecret
│   ├── flag-service/
│   ├── targeting-service/
│   ├── evaluation-service/     # + hpa, serviceaccount (IRSA)
│   ├── analytics-service/      # + hpa, serviceaccount (IRSA), sem segredo
│   └── postgres-targeting/     # o 3o banco, em pod (D-015)
└── overlays/prod/              # o que depende da AWS
    ├── kustomization.yaml      # images: <- alterado pelo CI (O-24)
    ├── secretstore.yaml        # acesso ao AWS Secrets Manager
    └── patches/
        ├── irsa.yaml           # ARNs das roles IAM
        └── endpoints.yaml      # REDIS_URL e AWS_SQS_URL
```

Conferir o resultado renderizado, sem aplicar nada:

```bash
kubectl kustomize gitops/overlays/prod
```

## O que mudou em relacao a Fase 2

| Item | Fase 2 | Aqui | Motivo |
|---|---|---|---|
| Tag da imagem | `:latest` fixa no deployment | nome logico + bloco `images:` no overlay | permite `kustomize edit set image` no CI (O-24) |
| `imagePullPolicy` | `Always` | removido | era muleta do `:latest`; tag por commit e imutavel |
| Segredos | `secret.yaml` versionado com placeholder | `ExternalSecret` lendo o Secrets Manager | nenhum valor no Git (D-013) |
| Acesso a AWS | `AWS_ACCESS_KEY_ID` em Secret do K8s | IRSA na ServiceAccount | credencial temporaria, nada a vazar (S-06) |
| `AWS_SQS_URL` | dentro do Secret | ConfigMap | URL de fila nao e segredo |
| Ingress | nginx com 5 rotas | removido | enunciado nao exige (F-018), economiza ~US$ 16-20/mes |
| Namespace | repetido em cada arquivo | uma vez no `kustomization.yaml` | forma idiomatica do Kustomize |

O `analytics-service` ficou **sem nenhum segredo**. Depois do IRSA, tudo que ele precisa e configuracao publica.

## Ordem de aplicacao

Esta pasta **ainda nao pode ser sincronizada**. Faltam pre-requisitos:

1. **Etapa 1 do Terraform** (pronta): ECR, SQS, DynamoDB, rede.
2. **Etapa 2** (a escrever): EKS, 2 RDS, ElastiCache, roles IRSA, segredos no Secrets Manager, addon `aws-ebs-csi-driver` e StorageClass default.
3. **Etapa 3** (a escrever): ArgoCD e External Secrets Operator.
4. Preencher os placeholders em `overlays/prod/patches/` com os `terraform output`.
5. So entao criar a `Application` do ArgoCD apontando para `gitops/overlays/prod`.

Os `ExternalSecret` e o `ClusterSecretStore` sao CRDs do ESO: sem ele instalado, o tipo nem existe na API. Como o ArgoCD tambem so chega na Etapa 3, nao ha janela em que isso quebre.

## Placeholders a preencher

| Arquivo | Chave | De onde vem |
|---|---|---|
| `patches/irsa.yaml` | ARNs das duas roles | `terraform output` da Etapa 2 |
| `patches/endpoints.yaml` | `REDIS_URL` | `terraform output` da Etapa 2 |
| `patches/endpoints.yaml` | `AWS_SQS_URL` | `terraform output sqs_queue_url` (Etapa 1) |
| `overlays/prod/kustomization.yaml` | `newTag` das 5 imagens | preenchido sozinho pelo CI |

## Armadilhas conhecidas

- **PVC Pending.** O `volumeClaimTemplates` do `postgres-targeting` nao declara `storageClassName`, entao depende de haver uma StorageClass default. Na Fase 2 nao havia e o deploy travou (F-025). A Etapa 2 do Terraform resolve isso por codigo (P-035).
- **HPA sem metrica.** Os dois HPAs precisam do Metrics Server instalado, senao ficam com `<unknown>` e nunca escalam.
- **Senha divergente.** O `targeting-service` e o `postgres-targeting` leem o **mesmo** segredo da AWS (`togglemaster/targeting-db`), de proposito. Nao criar dois segredos separados.
