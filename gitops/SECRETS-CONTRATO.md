# Contrato de Secrets entre Terraform e GitOps

Nenhum Secret é versionado neste repositório. A camada `terraform/k8s` cria os
Secrets do Kubernetes, e os Deployments de `gitops/` os consomem por nome.
Esta página é o contrato entre os dois lados: se um nome ou uma chave
divergir, o pod não sobe.

## Por que existe este arquivo

O External Secrets Operator foi descartado (ver [README, Decisões](../README.md#5-decisões-e-o-porquê)),
e com ele sumiu do Git a declaração de onde cada segredo vinha. O acoplamento
continua: o Deployment faz `secretKeyRef` para um Secret que precisa existir.
Este arquivo torna esse contrato explícito.

## Como funciona agora

1. A camada `terraform/cluster` gera as senhas dos dois RDS com `random_password`
   e as grava também no Secrets Manager (`togglemaster/auth-service` e `togglemaster/flag-service`).
2. A camada `terraform/k8s` (`secrets.tf`) lê essas URLs de conexão do estado
   do cluster e gera ali mesmo a senha do banco do targeting, a `MASTER_KEY` e a
   `SERVICE_API_KEY`. Esses três valores ficam só no Secret e no estado do
   Terraform, não no Secrets Manager.
3. A mesma camada cria os 5 Secrets no cluster pelo provider `kubernetes`.
4. Os Deployments deste repositório leem os valores via `secretKeyRef`.

Nenhuma senha passa por `terraform.tfvars`, por manifesto YAML ou pelo Git.

## O contrato

Namespace de todos: `togglemaster`.

| Secret do Kubernetes | Chave | Conteúdo esperado |
|---|---|---|
| `auth-service-secret` | `DATABASE_URL` | `postgres://toggle:<senha>@<endpoint-rds-auth>:5432/auth_db` |
| `auth-service-secret` | `MASTER_KEY` | string aleatória, usada em `POST /admin/keys` |
| `flag-service-secret` | `DATABASE_URL` | `postgres://toggle:<senha>@<endpoint-rds-flags>:5432/flags_db` |
| `targeting-service-secret` | `DATABASE_URL` | `postgres://toggle:<senha>@postgres-targeting:5432/targeting_db` |
| `evaluation-service-secret` | `SERVICE_API_KEY` | chave de API criada no seed, consumida no hot path |
| `postgres-targeting-secret` | `POSTGRES_USER` | `toggle` |
| `postgres-targeting-secret` | `POSTGRES_PASSWORD` | mesma senha usada no `DATABASE_URL` do targeting |

## Pontos de atenção

- O `targeting-service` e o `postgres-targeting` compartilham a MESMA senha.
  O banco roda em pod: o StatefulSet usa `POSTGRES_PASSWORD` para criar o
  usuário, e o serviço usa a mesma senha dentro do `DATABASE_URL`. Se as duas
  divergirem, o serviço sobe e falha com `password authentication failed`.
- O host do targeting NÃO é um endpoint da AWS: é `postgres-targeting`, o nome
  do Service interno do cluster.
- O `analytics-service` não tem segredo nenhum: fala com SQS e DynamoDB por IRSA.
  O `evaluation-service` também usa IRSA; o único segredo dele é a `SERVICE_API_KEY`.
- A `SERVICE_API_KEY` nasce com um valor provisório. O seed cria a chave real
  no auth-service e sobrescreve o Secret; o `lifecycle { ignore_changes = [data] }`
  impede que um novo `terraform apply` volte ao valor provisório. O passo está
  no [guia, seção 8](../docs/GUIA_DE_REPRODUCAO.md#8-schemas-chave-de-serviço-e-dados-de-exemplo).

## Sintomas de contrato quebrado

| Sintoma | Causa provável |
|---|---|
| Pod em `CreateContainerConfigError` | o Secret não existe, ou o nome divergiu |
| Pod em `CrashLoopBackOff` com erro de conexão | a chave existe, mas o valor está errado |
| `password authentication failed` só no targeting | senhas diferentes entre o pod do banco e o serviço |

Para conferir o que existe no cluster:

```bash
# Lista os Secrets do namespace da aplicação (só nomes, sem valores)
kubectl get secrets -n togglemaster
# Mostra as chaves e o tamanho de cada valor do Secret do auth, sem revelar o conteúdo
kubectl describe secret auth-service-secret -n togglemaster
```
