# RUNBOOK DA SESSAO - subir, semear, gravar e derrubar

TL;DR: sequencia exata de comandos para uma sessao de trabalho com o
cluster no ar. Duracao alvo: **3 horas**. Custo aproximado: **US$ 1,10**.
Ler inteiro ANTES de comecar - varios passos tem armadilha conhecida.

Ultima atualizacao: 2026-09-09, Claude. Cobre P-034.

---

## Por que este documento existe

O cluster custa cerca de **US$ 0,37 por hora** com tudo de pe (F-026), e
em 2026-08-27 restavam US$ 70 de credito. Isso da aproximadamente 190
horas de uptime no total, para o projeto inteiro.

Um fim de semana esquecido ligado consome 48 horas - um quarto do
orcamento. Por isso **derrubar ao fim da sessao nao e otimizacao, e
requisito**, e a Fase 4 deste runbook nao pode ser pulada.

---

## FASE 0 - Antes de comecar (5 min)

Rodar tudo isto ANTES de criar qualquer recurso. Cada linha existe
porque a ausencia dela ja custou tempo.

**Identidade na AWS.** Se falhar, nada adiante funciona:

```bash
aws sts get-caller-identity
```

Esperado: conta `891376952395`.

**Ferramentas no PATH:**

```bash
terraform version
```

```bash
kubectl version --client
```

```bash
aws --version
```

**Token do GitHub para o ArgoCD.** O repositorio e privado (F-014), e
sem isto a Application fica em Unknown com "authentication required":

```bash
$env:TF_VAR_github_token = "ghp_SEU_TOKEN_AQUI"
```

O token precisa apenas de `Contents: Read-only`. Ele fica so na sessao
do terminal - nao entra em arquivo nenhum.

**Conferir que a camada base esta aplicada:**

```bash
terraform -chdir=terraform output github_actions_role_arn
```

Se der erro, a base nunca foi aplicada e a Fase 1 vai falhar ao ler o
estado dela.

---

## FASE 1 - Subir (30 a 40 min)

### 1.1 Ligar o NAT Gateway

**ESTE PASSO E O MAIS ESQUECIDO E O QUE MAIS DOI.**

O NAT mora na camada BASE, que nunca e destruida. Sem ele, os nos do
EKS ficam em subnet privada sem saida para a internet: nao conseguem
baixar imagem do ECR nem falar com o control plane, e todo pod fica em
`ImagePullBackOff`.

Edite `terraform/terraform.tfvars` e troque para:

```
enable_nat_gateway = true
```

Depois:

```bash
terraform -chdir=terraform apply
```

Leva cerca de 2 minutos. **Anote o horario** - o NAT comeca a cobrar
US$ 0,045/h a partir daqui, e o passo 4.3 desliga.

### 1.2 Subir o cluster (20 a 30 min)

```bash
terraform -chdir=terraform/cluster apply
```

O que demora: o control plane do EKS leva ~10 min, o node group mais
~5, e as duas instancias RDS ~10 (em paralelo). Va tomar um cafe.

**Confira o resumo antes de confirmar.** Deve ser `35 to add, 0 to
destroy` na primeira vez.

### 1.3 Apontar o kubectl para o cluster

```bash
aws eks update-kubeconfig --region us-east-2 --name togglemaster
```

Testar:

```bash
kubectl get nodes
```

Esperado: 2 nos em `Ready`. Se aparecer `Unauthorized`, quem esta
rodando o comando nao e o mesmo usuario IAM que criou o cluster - so
ele recebe admin por `bootstrap_cluster_creator_admin_permissions`.

### 1.4 Subir Secrets, StorageClass e ArgoCD (5 a 8 min)

```bash
terraform -chdir=terraform/k8s apply
```

Confira que os 5 Secrets nasceram:

```bash
kubectl get secrets -n togglemaster
```

### 1.5 Preencher os placeholders do GitOps

**So e possivel agora**, porque os valores nascem do apply anterior.

```bash
terraform -chdir=terraform/cluster output redis_url
```

```bash
terraform -chdir=terraform/cluster output irsa_role_arns
```

Compare com o que esta no repositorio e corrija se divergir:

- `gitops/overlays/prod/patches/endpoints.yaml` - o `REDIS_URL` ainda
  contem a palavra literal **`PREENCHER`**. Trocar pelo valor do output.
- `gitops/overlays/prod/patches/irsa.yaml` - conferir os dois ARNs.
- `gitops/overlays/prod/kustomization.yaml` - as 5 tags estao em
  `v1.0.0-placeholder`. Elas so ficam corretas depois que o pipeline
  rodar verde na `main` e publicar as imagens.

Comitar e empurrar para a `main`. O ArgoCD so enxerga o que esta no Git.

### 1.6 Conferir o ArgoCD

```bash
kubectl get pods -n argocd
```

Abrir a interface (deixe este terminal aberto, ele fica travado):

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:80
```

Usuario `admin`, e a senha sai daqui:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
```

Acesse http://localhost:8080.

---

## FASE 2 - Semear os dados (10 min)

O `terraform destroy` apaga os bancos, entao **o seed precisa ser
refeito a cada sessao**. Sem ele o sistema sobe vazio e a demonstracao
funcional nao mostra nada.

Abra tuneis para os servicos, cada um num terminal proprio:

```bash
kubectl port-forward svc/auth-service -n togglemaster 8001:8001
```

```bash
kubectl port-forward svc/flag-service -n togglemaster 8002:8002
```

```bash
kubectl port-forward svc/targeting-service -n togglemaster 8003:8003
```

```bash
kubectl port-forward svc/evaluation-service -n togglemaster 8004:8004
```

### 2.1 Criar a chave de API

Pegue a MASTER_KEY do Secret:

```bash
kubectl get secret auth-service-secret -n togglemaster -o jsonpath='{.data.MASTER_KEY}' | base64 -d
```

Crie a chave (troque `<MASTER_KEY>`):

```bash
curl -X POST http://localhost:8001/admin/keys -H "Content-Type: application/json" -H "Authorization: Bearer <MASTER_KEY>" -d '{"name":"demo-fase3"}'
```

A resposta traz a chave em `key`, no formato `tm_key_...`. **Guarde: ela
so aparece uma vez.**

### 2.2 Sincronizar a chave com o evaluation-service

O `SERVICE_API_KEY` no Secret e um valor provisorio gerado pelo
Terraform - ele nao corresponde a nenhuma chave real do banco. Substitua
pela chave recem-criada e reinicie o pod:

```bash
kubectl create secret generic evaluation-service-secret -n togglemaster --from-literal=SERVICE_API_KEY='<CHAVE_tm_key>' --dry-run=client -o yaml | kubectl apply -f -
```

```bash
kubectl rollout restart deployment/evaluation-service -n togglemaster
```

### 2.3 Criar uma flag e uma regra

```bash
curl -X POST http://localhost:8002/flags -H "Content-Type: application/json" -H "Authorization: Bearer <CHAVE_tm_key>" -d '{"name":"novo-painel","description":"Painel novo para demonstracao","is_enabled":true}'
```

```bash
curl -X POST http://localhost:8003/rules -H "Content-Type: application/json" -H "Authorization: Bearer <CHAVE_tm_key>" -d '{"flag_name":"novo-painel","rules":{"user_ids":["user-123"]},"is_enabled":true}'
```

### 2.4 Provar que o sistema funciona ponta a ponta

```bash
curl "http://localhost:8004/evaluate?flag=novo-painel&user=user-123" -H "Authorization: Bearer <CHAVE_tm_key>"
```

Esperado: `"result": true`. Repita com `user=user-999` e deve vir
`false`. Isso exercita o caminho completo - evaluation le do Redis,
consulta flag e targeting, e publica o evento na SQS, que o analytics
consome e grava no DynamoDB.

---

## FASE 3 - Gravar (40 min)

Itens do checklist mapeados. **Metade ja pode ter sido gravada antes**,
com a AWS desligada (F-028).

### Ja gravavel sem cluster - grave antes da sessao

| Item | O que mostrar |
|---|---|
| **O-28** | Abrir um PR com dependencia vulneravel ou erro proposital, mostrar o job de SCA/SAST vermelho e o job de imagem aparecendo como *skipped* - e a prova visual do "falhar e nao prosseguir" |
| **O-29** | Corrigir, mostrar os 4 jobs verdes |
| **O-30** | Na `main`, mostrar o job `gitops` rodando e o commit `chore(gitops): ... [skip ci]` alterando UMA linha no `kustomization.yaml` |

### Precisa do cluster no ar

| Item | O que mostrar |
|---|---|
| **O-27** | `terraform plan` e `apply` rodando, ou o console da AWS com VPC, RDS e EKS criados por codigo. Vale mostrar o estado no S3, provando que nao ha `tfstate` local |
| **O-31** | Na interface do ArgoCD, apos o commit de tag: o card sai de `Synced` para `OutOfSync` e volta sozinho para `Synced` |
| **O-32** | A tela do ArgoCD com os 5 microsservicos verdes. Vale abrir a arvore de um deles e mostrar Deployment, Service e ConfigMap |

**Sugestao de ordem na gravacao:** comece pelo O-27 (ja esta na tela),
depois abra o ArgoCD para o O-32, e por ultimo dispare uma alteracao
para capturar o O-31 ao vivo. Assim a espera da sincronizacao acontece
uma vez so.

Limite do video: **20 minutos**. Grave em blocos separados e junte
depois - tentar fazer tudo numa tomada so gasta a janela do cluster.

---

## FASE 4 - Derrubar (20 a 25 min)

**Nenhum passo desta fase e opcional.**

### 4.1 Derrubar a camada k8s

```bash
terraform -chdir=terraform/k8s destroy
```

### 4.2 Derrubar o cluster

```bash
terraform -chdir=terraform/cluster destroy
```

**Se travar em VPC ou subnet:** e o Load Balancer que o Kubernetes cria
sozinho segurando a subnet. Nao deveria acontecer aqui, porque o projeto
nao tem Ingress (D-012), mas se acontecer, apague o Load Balancer orfao
no console EC2 e rode o destroy de novo.

### 4.3 DESLIGAR O NAT GATEWAY

Volte `terraform/terraform.tfvars` para:

```
enable_nat_gateway = false
```

```bash
terraform -chdir=terraform apply
```

Esquecer este passo custa **US$ 0,045/h para sempre**, porque a camada
base nunca e destruida. Em uma semana esquecida sao ~US$ 7,50 - mais de
10% do credito restante, sem nada rodando.

### 4.4 Conferir que nao sobrou nada caro

```bash
aws eks list-clusters --region us-east-2
```

```bash
aws rds describe-db-instances --region us-east-2 --query "DBInstances[].DBInstanceIdentifier"
```

```bash
aws elasticache describe-replication-groups --region us-east-2 --query "ReplicationGroups[].ReplicationGroupId"
```

```bash
aws ec2 describe-nat-gateways --region us-east-2 --query "NatGateways[?State=='available'].NatGatewayId"
```

As quatro saidas precisam vir **vazias**. O que pode continuar de pe sem
problema: VPC, subnets, ECR, SQS, DynamoDB e IAM - nenhum deles cobra
parado.

---

## Armadilhas conhecidas

| Sintoma | Causa | Solucao |
|---|---|---|
| Pod em `ImagePullBackOff` | NAT desligado, ou tag ainda em `v1.0.0-placeholder` | Passo 1.1; conferir se o CI publicou as imagens |
| Pod em `CreateContainerConfigError` | Secret faltando ou com nome divergente | `kubectl get secrets -n togglemaster`; conferir `gitops/SECRETS-CONTRATO.md` |
| PVC em `Pending` | StorageClass ausente ou nome divergente | `kubectl get storageclass`; o nome tem que ser `gp3` nos dois lados |
| `password authentication failed` so no targeting | Senha do pod do banco divergiu da do servico | Ambos vem de `random_password.targeting_db`; recriar os dois Secrets juntos |
| ArgoCD em `Unknown`, "authentication required" | `TF_VAR_github_token` nao foi definido | Passo 0; reaplicar `terraform/k8s` |
| HPA com `targets: <unknown>` | Metrics Server ainda subindo | Aguardar ~2 min; e addon gerenciado e se resolve sozinho |
| `QueueDeletedRecently` | Fila SQS recriada em menos de 60s | Esperar 1 minuto e repetir |
| Erro de conexao no Redis no boot | Esquema da URL divergente do TLS | `redis://` com TLS desligado, `rediss://` com ligado - ver a variavel `redis_transit_encryption` |

---

## Resumo do tempo e do custo

| Fase | Tempo | Observacao |
|---|---|---|
| 0 - Pre-voo | 5 min | custo zero |
| 1 - Subir | 30-40 min | o relogio comeca no passo 1.1 |
| 2 - Seed | 10 min | refazer a cada sessao |
| 3 - Gravar | 40 min | metade pode ser gravada antes |
| 4 - Derrubar | 20-25 min | nenhum passo e opcional |
| **Total** | **~2h** | **~US$ 0,75 a 1,10** |

Cabem cerca de 3 sessoes completas dentro do que resta de credito com
folga. Planeje **uma de ensaio e uma de gravacao**, e guarde a terceira
para imprevisto.
