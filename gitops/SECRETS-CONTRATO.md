# Contrato de Secrets entre Terraform e GitOps

TL;DR: nenhum Secret e versionado neste repositorio. O Terraform da camada
`terraform/cluster/` cria os Secrets do Kubernetes; os Deployments daqui os
consomem por nome. Esta pagina e o contrato entre os dois lados. Se um nome
ou uma chave divergir, o pod nao sobe.

## Por que existe este arquivo

O External Secrets Operator foi cortado em 2026-09-01 (P-037). Antes, cada
servico tinha um `externalsecret.yaml` versionado que declarava de onde o
segredo vinha, e o operador criava o Secret em tempo de execucao.

Sem o ESO, essa declaracao sumiu do Git. O acoplamento continua existindo -
o Deployment ainda faz `secretKeyRef` para um Secret que precisa existir -
mas ficou INVISIVEL. Este arquivo torna o contrato explicito.

## Como funciona agora

1. O Terraform da camada cluster gera as senhas com `random_password`.
2. Grava cada uma no AWS Secrets Manager (evidencia para o relatorio, O-38).
3. Aplica o Secret no cluster pelo provider `kubernetes`.
4. Os Deployments deste repositorio leem via `secretKeyRef`.

Nenhuma senha passa por `terraform.tfvars`, por manifesto YAML ou pelo Git.

## O contrato

Namespace de todos: `togglemaster`.

| Secret do Kubernetes | Chave | Conteudo esperado |
|---|---|---|
| `auth-service-secret` | `DATABASE_URL` | `postgres://toggle:<senha>@<endpoint-rds-auth>:5432/auth_db` |
| `auth-service-secret` | `MASTER_KEY` | string aleatoria, usada em `POST /admin/keys` |
| `flag-service-secret` | `DATABASE_URL` | `postgres://toggle:<senha>@<endpoint-rds-flags>:5432/flags_db` |
| `targeting-service-secret` | `DATABASE_URL` | `postgres://toggle:<senha>@postgres-targeting:5432/targeting_db` |
| `evaluation-service-secret` | `SERVICE_API_KEY` | chave de API criada no seed, consumida no hot path |
| `postgres-targeting-secret` | `POSTGRES_USER` | `toggle` |
| `postgres-targeting-secret` | `POSTGRES_PASSWORD` | mesma senha usada no `DATABASE_URL` do targeting |

## Pontos de atencao

- O `targeting-service` e o `postgres-targeting` compartilham a MESMA senha.
  O banco roda em pod (D-015), entao os dois lados precisam combinar: o
  StatefulSet usa `POSTGRES_PASSWORD` para criar o usuario, e o servico usa a
  mesma senha dentro do `DATABASE_URL`. Gerar duas senhas diferentes faz o
  servico subir e falhar na conexao com `password authentication failed`.

- O host do targeting NAO e um endpoint da AWS: e `postgres-targeting`, o nome
  do Service interno do cluster.

- O `analytics-service` nao aparece na tabela porque nao tem segredo nenhum.
  Ele fala com SQS e DynamoDB por IRSA (S-06), sem credencial.

- O `evaluation-service` tambem usa IRSA para a SQS. O unico segredo dele e a
  `SERVICE_API_KEY`, que e da aplicacao, nao da AWS.

## Sintomas de contrato quebrado

| Sintoma | Causa provavel |
|---|---|
| Pod em `CreateContainerConfigError` | o Secret nao existe, ou o nome divergiu |
| Pod em `CrashLoopBackOff` com erro de conexao | a chave existe mas o valor esta errado |
| `password authentication failed` so no targeting | senhas diferentes entre o pod do banco e o servico |

Para conferir o que existe no cluster:

    kubectl get secrets -n togglemaster
    kubectl describe secret auth-service-secret -n togglemaster
