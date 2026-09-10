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

> **QUAL TERMINAL USAR.** Este runbook mistura dois shells, e trocar na
> hora errada gera erro confuso:
>
> - **Git Bash ou WSL** para tudo que usa `<` (redirecionamento de
>   arquivo), `$(...)` ou `|` — ou seja, os comandos `psql` do passo 1.7,
>   o `sed` do passo 1.5 e os comandos `git`. No PowerShell o `<` nem
>   existe como redirecionamento e o comando falha com erro de sintaxe.
> - **PowerShell** para a linha do token logo abaixo (`$env:...`), que e
>   sintaxe exclusiva dele.
>
> Sugestao pratica: deixe **duas janelas abertas** e nao troque no meio
> de uma fase. No PowerShell, lembre que `terraform plan -out=arquivo`
> precisa do token `--%` antes dos parametros, senao ele reclama de
> "Too many command line arguments".

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

**SAO DOIS COMANDOS, NESTA ORDEM. Nao pule o primeiro.**

O cluster nasce sem conhecer o tipo `Application` do ArgoCD — quem o
ensina e a propria instalacao do ArgoCD. Mas o Terraform valida esse
tipo ainda no *plan*, ou seja, antes de instalar. Rodar o apply direto
num cluster novo falha com `no matches for kind "Application"`. O
`-target` abaixo resolve limitando a primeira rodada a instalacao
(F-043; a explicacao completa esta no topo de `terraform/k8s/argocd.tf`).

Etapa A — instala o ArgoCD e, com ele, o tipo que falta:

```bash
terraform -chdir=terraform/k8s apply -target=helm_release.argocd
```

Etapa B — agora o resto, incluindo a Application que aponta para o Git:

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
  contem a palavra literal **`PREENCHER`** (F-047). Comando pronto,
  que le o output e escreve no arquivo sem digitacao manual:

  ```bash
  REDIS=$(terraform -chdir=terraform/cluster output -raw redis_url) && sed -i "s|redis://togglemaster-redis.*:6379|${REDIS}|" gitops/overlays/prod/patches/endpoints.yaml && grep REDIS_URL gitops/overlays/prod/patches/endpoints.yaml
  ```

  A ultima parte imprime a linha resultante: confira que sumiu a palavra
  `PREENCHER` antes de seguir.

- `gitops/overlays/prod/patches/irsa.yaml` - conferir os dois ARNs.
- `gitops/overlays/prod/kustomization.yaml` - **JA ESTA CORRETO,
  nao precisa mexer.** As 5 tags deixaram de ser `v1.0.0-placeholder`
  em 2026-09-10: o pipeline rodou verde na `main` e o proprio job de
  GitOps as atualizou para `v1.0.0-<commit>`. So confira que as 5
  apontam para o mesmo commit; se alguma estiver diferente, e porque um
  pipeline falhou e nao publicou.

**Como levar isso ate a `main`** — o ArgoCD so enxerga o que esta no Git,
e a regra do projeto e nao commitar direto na `main` (D-020):

```bash
git switch dev && git add gitops/overlays/prod && git commit -m "chore(gitops): endpoints reais da sessao" && git push origin dev
```

```bash
gh pr create --base main --head dev --title "chore(gitops): endpoints reais da sessao" --body "Valores gerados pelo apply desta sessao." && gh pr merge --merge
```

Depois do merge, traga a `dev` de volta ao mesmo ponto — o job GitOps do
CI tambem comita na `main`, entao ela anda sozinha:

```bash
git switch dev && git fetch origin && git merge --ff-only origin/main && git push origin dev
```

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

### 1.7 Criar as tabelas nos bancos RDS

**PASSO OBRIGATORIO E FACIL DE ESQUECER.**

O Terraform cria as INSTANCIAS RDS e os bancos vazios - mas nao cria
TABELA nenhuma. Os schemas existem em `services/*/db/init.sql` e sao
montados automaticamente apenas pelo docker-compose, no ambiente local.

No caminho AWS ninguem os executa. Sem este passo, o `auth-service` e o
`flag-service` sobem, respondem `/health` com 200 e falham no primeiro
INSERT, com `relation "api_keys" does not exist`. Health verde nao prova
banco pronto.

O `targeting_db` e a excecao: como roda em pod, o schema vai num
ConfigMap e o proprio PostgreSQL o executa na primeira subida.

Pegue os endpoints e as senhas:

```bash
terraform -chdir=terraform/cluster output rds_endpoints
```

```bash
kubectl get secret auth-service-secret -n togglemaster -o jsonpath='{.data.DATABASE_URL}' | base64 -d
```

O RDS esta em subnet privada, entao o `psql` precisa rodar DE DENTRO do
cluster. Um pod descartavel resolve - repita trocando o banco:

```bash
kubectl run psql-auth --rm -i --restart=Never -n togglemaster --image=postgres:16-alpine --env="PGPASSWORD=<SENHA_AUTH>" -- psql -h <ENDPOINT_AUTH> -U toggle -d auth_db < services/auth-service/db/init.sql
```

```bash
kubectl run psql-flag --rm -i --restart=Never -n togglemaster --image=postgres:16-alpine --env="PGPASSWORD=<SENHA_FLAG>" -- psql -h <ENDPOINT_FLAG> -U toggle -d flags_db < services/flag-service/db/init.sql
```

Os schemas usam `CREATE TABLE IF NOT EXISTS`, entao rodar duas vezes nao
quebra nada.

Confira antes de seguir:

```bash
kubectl run psql-check --rm -i --restart=Never -n togglemaster --image=postgres:16-alpine --env="PGPASSWORD=<SENHA_AUTH>" -- psql -h <ENDPOINT_AUTH> -U toggle -d auth_db -c "\dt"
```

Tem que listar a tabela `api_keys`. Se vier "No relations found", o
schema nao foi aplicado e o seed da Fase 2 vai falhar.

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
curl -X POST http://localhost:8003/rules -H "Content-Type: application/json" -H "Authorization: Bearer <CHAVE_tm_key>" -d '{"flag_name":"novo-painel","rules":{"type":"PERCENTAGE","value":100},"is_enabled":true}'
```

O `evaluation-service` implementa **apenas o tipo `PERCENTAGE`** (ver
`evaluator.go`, degrau 3). Uma regra com `user_ids` seria aceita pelo
targeting mas ignorada na avaliacao. Com `value: 100` o resultado e
sempre `true`, e com `value: 0` sempre `false` - deterministico, que e o
que se quer numa demonstracao gravada.

### 2.4 Provar que o sistema funciona ponta a ponta

```bash
curl "http://localhost:8004/evaluate?flag_name=novo-painel&user_id=user-123" -H "Authorization: Bearer <CHAVE_tm_key>"
```

ATENCAO AOS NOMES DOS PARAMETROS: sao `flag_name` e `user_id`, nao
`flag` e `user`. O handler exige exatamente esses dois e devolve 400 com
qualquer outro nome (ver `handlers.go`, evaluationHandler).

Esperado: `"result": true`, porque a regra e de 100%.

Para ver o caminho oposto, crie uma segunda flag com
`{"type":"PERCENTAGE","value":0}` e avalie: deve vir `false`. Nao adianta
so trocar o `user_id` na mesma flag - com 100% todo usuario da true.

Lembre do TTL do cache no Redis: se voce alterar a regra e reavaliar o
MESMO par flag/usuario logo em seguida, a resposta pode vir do cache.

Isso exercita o caminho completo - evaluation le do Redis, consulta flag
e targeting, e publica o evento na SQS, que o analytics consome e grava
no DynamoDB.

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
| 1 - Subir | 35-45 min | o relogio comeca no passo 1.1; inclui criar os schemas (1.7) |
| 2 - Seed | 10 min | refazer a cada sessao |
| 3 - Gravar | 40 min | metade pode ser gravada antes |
| 4 - Derrubar | 20-25 min | nenhum passo e opcional |
| **Total** | **~2h** | **~US$ 0,75 a 1,10** |

Cabem cerca de 3 sessoes completas dentro do que resta de credito com
folga. Planeje **uma de ensaio e uma de gravacao**, e guarde a terceira
para imprevisto.
