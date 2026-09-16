# GitOps do ToggleMaster

O Git descreve o que deve rodar no cluster; o ArgoCD lê esta pasta na `main` e copia o estado para o EKS sozinho. Ninguém faz `kubectl apply` daqui. Tecnicamente, são manifestos Kustomize derivados da Fase 2, com uma base comum e um único overlay `prod`.

## Estrutura

```text
gitops/
├── base/                      # o que não depende da conta AWS
│   ├── kustomization.yaml     # índice dos manifestos e rótulos comuns
│   ├── namespace.yaml
│   ├── auth-service/          # deployment, service, configmap
│   ├── flag-service/
│   ├── targeting-service/
│   ├── evaluation-service/    # + hpa e serviceaccount (IRSA)
│   ├── analytics-service/     # + hpa e serviceaccount (IRSA), sem segredo
│   └── postgres-targeting/    # banco do targeting em StatefulSet
├── overlays/prod/
│   ├── kustomization.yaml     # bloco images: (registro e tag de cada serviço)
│   └── patches/
│       ├── irsa.yaml          # ARN da role IAM de cada ServiceAccount
│       └── endpoints.yaml     # REDIS_URL e AWS_SQS_URL
└── SECRETS-CONTRATO.md        # nomes e chaves dos Secrets esperados
```

## Quem altera o quê

| O quê | Arquivo | Quem altera | Quando |
|---|---|---|---|
| `newTag` das 5 imagens | `overlays/prod/kustomization.yaml` | O robô do CI, com `kustomize edit set image` e commit `[skip ci]` na `main` | A cada push na `main` que publica imagem |
| `newName` (registro ECR) | `overlays/prod/kustomization.yaml` | Uma pessoa | Ao trocar de conta ou região |
| `AWS_SQS_URL` | `patches/endpoints.yaml` | Uma pessoa | Uma vez por conta; o valor é previsível pelo ID da conta |
| `eks.amazonaws.com/role-arn` | `patches/irsa.yaml` | Uma pessoa | Uma vez por conta; o valor é previsível pelo ID da conta |
| `REDIS_URL` | `patches/endpoints.yaml` | Uma pessoa | Depois do apply do cluster, com `terraform -chdir=terraform/cluster output -raw redis_url` |

Os valores de outra conta estão na [seção 2 do guia](../docs/GUIA_DE_REPRODUCAO.md#2-valores-fixos-a-trocar-em-outra-conta), e o `REDIS_URL`, na [seção 6](../docs/GUIA_DE_REPRODUCAO.md#6-camada-cluster-e-endpoints-do-overlay). O ArgoCD lê do Git, não do disco: a alteração só vale depois de chegar à `main`.

## O que NÃO está aqui

- **Secrets.** Nenhum valor secreto é versionado. Os 5 Secrets são criados por `terraform/k8s/secrets.tf`; os nomes e as chaves que precisam coincidir estão em [SECRETS-CONTRATO.md](SECRETS-CONTRATO.md).
- **Ingress.** Não há Ingress nem Load Balancer; os Services são ClusterIP e o acesso é por `kubectl port-forward`.
- **Application do ArgoCD.** Ela é criada pelo Terraform em `terraform/k8s/argocd.tf`, apontando para `gitops/overlays/prod` na `main`.

## Fase 2 x Fase 3 (visão de manifesto)

| Item | Fase 2 | Fase 3 | Motivo |
|---|---|---|---|
| Tag da imagem | `:latest` fixa no deployment | nome lógico na base e bloco `images:` no overlay | o CI troca a tag com `kustomize edit set image` |
| `imagePullPolicy` | `Always` | removido dos 5 serviços | cada commit gera uma tag nova (`v1.0.0-<sha7>`) |
| Segredos | `secret.yaml` versionado com placeholder | criados por `terraform/k8s/secrets.tf` | nenhum valor no Git |
| Acesso à AWS | `AWS_ACCESS_KEY_ID` em Secret | IRSA na ServiceAccount | credencial temporária, nada a vazar |
| `AWS_SQS_URL` | dentro do Secret | ConfigMap | URL de fila não é segredo |
| Ingress | nginx com 5 rotas | removido | o enunciado não pede exposição externa |
| Disco do banco em pod | sem StorageClass definida | `storageClassName: gp3` declarado no StatefulSet | a classe `gp3` nasce na camada `terraform/k8s` |

## Conferir localmente

O `kubectl kustomize` renderiza o overlay sem aplicar nada. O resultado tem 23 objetos.

```bash
# Renderiza o overlay prod na tela, sem tocar em nenhum cluster
kubectl kustomize gitops/overlays/prod
# Conta os objetos renderizados (linhas kind: no primeiro nível)
kubectl kustomize gitops/overlays/prod | grep -c '^kind:'
```

O `kubectl` não tem o subcomando `kustomize edit`. O CI instala o `kustomize` autônomo (5.4.3) só para alterar o bloco `images:`.

## Links

- Guia: [seção 6, cluster e endpoints](../docs/GUIA_DE_REPRODUCAO.md#6-camada-cluster-e-endpoints-do-overlay) e [seção 7, camada k8s e ArgoCD](../docs/GUIA_DE_REPRODUCAO.md#7-camada-k8s-e-argocd)
- Como o GitOps funciona e por quê: [README, seção 4.3](../README.md#4-como-funciona-cada-frente)
- Probes, recursos, HPAs e objetos em detalhe: [docs/ARQUITETURA.md, seção 3](../docs/ARQUITETURA.md)
