# 🛠️ Guia de operação

Este é o **único** guia operacional do projeto. Ele cobre os dois caminhos possíveis:
rodar os cinco microsserviços na sua máquina, sem AWS e sem custo, e provisionar o
ambiente completo na AWS, usar, verificar e derrubar.

Leia o bloco da fase inteira **antes** de executá-la. Vários passos têm armadilha
conhecida, e algumas delas custam a sessão inteira.

---

## 📑 Índice

- [O mínimo para não errar](#o-mínimo-para-não-errar)
- [Qual terminal usar](#qual-terminal-usar)
- [1. Rodar localmente com Docker Compose](#1-rodar-localmente-com-docker-compose)
- [2. Provisionar na AWS](#2-provisionar-na-aws)
- [3. Criar os schemas dos bancos](#3-criar-os-schemas-dos-bancos)
- [4. Acessar o ArgoCD](#4-acessar-o-argocd)
- [5. Verificar que funciona ponta a ponta](#5-verificar-que-funciona-ponta-a-ponta)
- [6. Encerrar a sessão](#6-encerrar-a-sessão)
- [7. Armadilhas conhecidas](#7-armadilhas-conhecidas)
- [8. Custo por sessão](#8-custo-por-sessão)

---

## O mínimo para não errar

Quatro pontos que valem estar no topo, porque são os que mais custam caro quando
esquecidos:

1. **Nenhuma chave estática da AWS circula neste projeto.** Os workflows do CI
   autenticam assumindo a role `togglemaster-github-actions` pelo provedor OIDC do
   GitHub — a role só aceita token emitido para este repositório, e qualquer outro
   recebe `AccessDenied`. Dentro do cluster é a mesma ideia: os pods acessam SQS e
   DynamoDB por IRSA, e nenhum Secret guarda `AWS_ACCESS_KEY_ID`. Se algum guia
   mandar cadastrar chave estática, ele está desatualizado.

2. **A ordem das camadas do Terraform não é negociável:** `terraform/` primeiro,
   depois `terraform/cluster/`, depois `terraform/k8s/` — esta última em **dois
   comandos**, por causa do tipo `Application` do ArgoCD ([explicação no passo
   2.7](#27-passo-5--secrets-storageclass-e-argocd-dois-comandos)). Cada camada lê o
   estado da anterior; fora de ordem, o `plan` falha.

3. **Base recriada significa ECR vazio.** Se a camada base foi destruída e criada de
   novo, os cinco repositórios de imagem nascem sem nenhuma imagem, e as tags gravadas
   em `gitops/overlays/prod/kustomization.yaml` apontam para o nada. Sem republicar as
   imagens ([passo 2.4](#24-passo-2--publicar-as-cinco-imagens-no-ecr)), todo pod fica
   em `ImagePullBackOff`.

4. **O que custa dinheiro é a camada do meio, mais o NAT Gateway.** Ao terminar,
   destrua `terraform/k8s/` e `terraform/cluster/` e decida o destino da base
   ([seção 6](#6-encerrar-a-sessão)): desligar só o NAT ou destruir a base também.
   Esquecido ligado, o NAT cobra US$ 0,045/h de hora parada — cerca de US$ 33 por
   mês —, e perto de **US$ 36 por mês** somando o endereço IPv4 público preso a ele.
   Tudo isso com nada rodando.

---

## Qual terminal usar

Este guia mistura dois shells, e trocar na hora errada gera erro confuso. Cada bloco
de comando abaixo vem rotulado. A regra geral:

| Use | Para |
|---|---|
| **Git Bash ou WSL** | Tudo que usa `<` (redirecionamento de arquivo), `$(...)`, `\|`, `&&` ou `\` no fim da linha — os comandos `psql` da seção 3, a republicação das imagens do passo 2.4 e o `sed` do passo 2.9 |
| **PowerShell** | Sintaxe `$env:...`, `Invoke-RestMethod`, `Copy-Item`, `Get-Content` |
| **Qualquer um** | `terraform`, `kubectl`, `aws`, `docker compose`, `git`, `gh` — idênticos nos dois |

> 💡 **Sugestão prática:** deixe **duas janelas abertas** e não troque no meio de uma
> fase.

> ⚠️ **Três detalhes do PowerShell que economizam tempo:**
> - `terraform plan -out=arquivo` precisa do token `--%` antes dos parâmetros, senão
>   o PowerShell reclama de *"Too many command line arguments"*.
> - `curl` no PowerShell é um alias de `Invoke-WebRequest`, que tem outra sintaxe.
>   Use `curl.exe` quando quiser o curl de verdade.
> - O PowerShell 5.1 **não aceita `&&`** (erro de parser) e continua linha com crase,
>   não com `\`. Blocos com esses caracteres são para o Git Bash; onde a diferença
>   importa, este guia traz a versão PowerShell ao lado.

---

# 1. Rodar localmente com Docker Compose

Este é o caminho **sem AWS, sem conta, sem custo e sem credencial**. Sobe os cinco
microsserviços, dois PostgreSQL, um Redis e um DynamoDB Local na sua máquina. É o
caminho que qualquer pessoa consegue executar para ver o sistema funcionando.

### Pré-requisitos

| Ferramenta | Versão mínima | Para quê |
|---|---|---|
| **Docker Desktop** (ou Docker Engine) | 24+ com Compose v2 | Constrói e roda os nove containers |
| **Git** | qualquer | Clonar o repositório |

> ℹ️ **Não é necessário** instalar Go, Python, PostgreSQL ou Redis separadamente. O
> Docker cuida de tudo. (O teste automatizado do passo 1.8 é a única exceção: ele
> precisa de Python 3 na sua máquina.)

As portas **8000–8005, 5433, 5434 e 6379** precisam estar livres.

### 1.1 Clonar e preparar o `.env`

**Git Bash / WSL / Linux / macOS:**

```bash
# Baixa o repositório e entra na pasta.
git clone https://github.com/fiap-devops-arqcloud-2026/tech-challenge-03.git
cd tech-challenge-03

# O Compose lê o arquivo .env; o .env.example é o modelo versionado.
cp .env.example .env
```

**PowerShell:**

```powershell
git clone https://github.com/fiap-devops-arqcloud-2026/tech-challenge-03.git
cd tech-challenge-03

Copy-Item .env.example .env
```

O `.env.example` contém **apenas valores locais e públicos** — nenhuma credencial
real. Três variáveis merecem atenção:

- `MASTER_KEY=local-master-key-change-me` — a chave administrativa do laboratório
  local. Em qualquer ambiente compartilhado, gere outro valor.
- `SERVICE_API_KEY=` — começa **vazia de propósito**. Essa chave precisa ser criada
  no banco novo do `auth-service` depois da primeira inicialização (passo 1.4).
- `AWS_ACCESS_KEY_ID=test` e `AWS_SECRET_ACCESS_KEY=test` — **não são credenciais.**
  São valores fictícios que o SDK da AWS exige para inicializar mesmo quando aponta
  para o DynamoDB Local, que roda dentro do seu Docker e não valida nada.

### 1.2 Subir os containers

**Git Bash ou PowerShell (idêntico nos dois):**

```bash
# --build constrói as 5 imagens; -d devolve o terminal depois de subir.
docker compose up --build -d
```

Esse comando constrói as imagens dos cinco serviços, sobe os quatro containers de
armazenamento (dois PostgreSQL, um Redis e um DynamoDB Local), inicia os
microsserviços e cria os bancos com os schemas já carregados.

### 1.3 Conferir que tudo subiu

**Git Bash ou PowerShell:**

```bash
docker compose ps
```

Aguarde até todos aparecerem como `healthy`. Na primeira vez leva cerca de 30 a 60
segundos.

**Resultado esperado — algo parecido com isto.** O formato exato da coluna STATUS
varia com a versão do Compose; o que importa é o `(healthy)` no fim da linha:

```
NAME                                    STATUS
tech-challenge-03-postgres-auth-1       running (healthy)
tech-challenge-03-postgres-app-1        running (healthy)
tech-challenge-03-redis-1               running (healthy)
tech-challenge-03-dynamodb-local-1      running
tech-challenge-03-auth-service-1        running (healthy)
tech-challenge-03-flag-service-1        running (healthy)
tech-challenge-03-targeting-service-1   running (healthy)
tech-challenge-03-evaluation-service-1  running (healthy)
tech-challenge-03-analytics-service-1   running (healthy)
```

> ℹ️ O prefixo dos nomes é o nome da pasta onde você clonou. O `dynamodb-local`
> aparece sem `(healthy)` porque a imagem oficial não traz healthcheck configurado —
> é esperado.

Confirme que os cinco serviços respondem:

**Git Bash / Linux / macOS:**

```bash
curl http://localhost:8001/health
curl http://localhost:8002/health
curl http://localhost:8003/health
curl http://localhost:8004/health
curl http://localhost:8005/health
```

**PowerShell:**

```powershell
curl.exe http://localhost:8001/health
curl.exe http://localhost:8002/health
curl.exe http://localhost:8003/health
curl.exe http://localhost:8004/health
curl.exe http://localhost:8005/health
```

Todos devem responder `{"status":"ok"}`.

### 1.4 Criar a chave de API usada entre os serviços

O `evaluation-service` precisa de uma chave cadastrada no `auth-service` para
consultar as flags e as regras. **Uma chave copiada de outra máquina não funciona em
um banco local recém-criado** — a chave vive no banco, e o banco é novo.

**PowerShell:**

```powershell
# Cria uma chave no banco local usando a MASTER_KEY que está no .env.example.
$resposta = Invoke-RestMethod `
  -Method Post `
  -Uri "http://localhost:8001/admin/keys" `
  -Headers @{ Authorization = "Bearer local-master-key-change-me" } `
  -ContentType "application/json" `
  -Body (@{ name = "evaluation-local" } | ConvertTo-Json -Compress)

# Mostra a chave criada. Copie o valor inteiro, que começa com tm_key_.
$resposta.key
```

**Git Bash / Linux / macOS:**

```bash
# A resposta JSON traz a chave no campo "key".
curl -s -X POST http://localhost:8001/admin/keys \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer local-master-key-change-me" \
  -d '{"name":"evaluation-local"}'
```

Abra o `.env` e preencha a variável com o valor retornado:

```dotenv
SERVICE_API_KEY=tm_key_COLE_A_CHAVE_GERADA_AQUI
```

> ⚠️ O texto acima é **exemplo de formato**. Não copie essa linha literalmente.

### 1.5 Recriar o evaluation-service

O Docker lê as variáveis do `.env` no momento em que cria o container. Depois de
salvar a chave, recrie apenas o serviço de avaliação:

**Git Bash ou PowerShell:**

```bash
docker compose up -d --force-recreate evaluation-service
docker compose ps evaluation-service
```

### 1.6 Exercitar o sistema

**PowerShell:**

```powershell
# Guarda a chave criada no passo 1.4 numa variável da sessão.
$CHAVE = "tm_key_COLE_A_CHAVE_GERADA_AQUI"

# Cadastra uma feature flag ligada.
Invoke-RestMethod `
  -Method Post -Uri "http://localhost:8002/flags" `
  -Headers @{ Authorization = "Bearer $CHAVE" } `
  -ContentType "application/json" `
  -Body (@{ name = "novo-painel"; description = "Painel novo"; is_enabled = $true } | ConvertTo-Json -Compress)

# Libera a flag para 50% dos usuários.
Invoke-RestMethod `
  -Method Post -Uri "http://localhost:8003/rules" `
  -Headers @{ Authorization = "Bearer $CHAVE" } `
  -ContentType "application/json" `
  -Body (@{ flag_name = "novo-painel"; is_enabled = $true; rules = @{ type = "PERCENTAGE"; value = 50 } } | ConvertTo-Json -Depth 4 -Compress)

# Avalia para três usuários diferentes. As aspas são obrigatórias por causa do &.
curl.exe "http://localhost:8004/evaluate?flag_name=novo-painel&user_id=usuario-1"
curl.exe "http://localhost:8004/evaluate?flag_name=novo-painel&user_id=usuario-2"
curl.exe "http://localhost:8004/evaluate?flag_name=novo-painel&user_id=usuario-3"
```

**Git Bash / Linux / macOS:**

```bash
CHAVE="tm_key_COLE_A_CHAVE_GERADA_AQUI"

curl -X POST http://localhost:8002/flags \
  -H "Content-Type: application/json" -H "Authorization: Bearer $CHAVE" \
  -d '{"name":"novo-painel","description":"Painel novo","is_enabled":true}'

curl -X POST http://localhost:8003/rules \
  -H "Content-Type: application/json" -H "Authorization: Bearer $CHAVE" \
  -d '{"flag_name":"novo-painel","is_enabled":true,"rules":{"type":"PERCENTAGE","value":50}}'

curl "http://localhost:8004/evaluate?flag_name=novo-painel&user_id=usuario-1"
curl "http://localhost:8004/evaluate?flag_name=novo-painel&user_id=usuario-2"
curl "http://localhost:8004/evaluate?flag_name=novo-painel&user_id=usuario-3"
```

**Resposta esperada (exemplo):**

```json
{"flag_name":"novo-painel","user_id":"usuario-1","result":true}
{"flag_name":"novo-painel","user_id":"usuario-2","result":false}
{"flag_name":"novo-painel","user_id":"usuario-3","result":true}
```

> ℹ️ **Repare que `/evaluate` não leva cabeçalho de autorização.** É de propósito: o
> endpoint de avaliação é aberto, e quem autentica é o próprio `evaluation-service`
> quando consulta o flag e o targeting, usando a `SERVICE_API_KEY` do ambiente. Criar
> a flag e a regra, essas sim, exige a chave.

> ⚠️ **Os parâmetros são `flag_name` e `user_id`** — não `flag` e `user`. O handler
> exige exatamente esses dois nomes e devolve HTTP 400 com qualquer outro.

> 💡 **O mesmo usuário sempre recebe a mesma resposta.** O cálculo é determinístico:
> se `usuario-1` recebeu `true`, sempre receberá `true` para essa flag. Com
> `value: 100` todo mundo recebe `true`; com `value: 0`, todo mundo recebe `false`.

Para ver o cache em ação, repita a mesma chamada e olhe o log — na segunda vez
aparece `Cache HIT`, ou seja, o Redis respondeu sem consultar os outros serviços:

```bash
docker compose logs evaluation-service --tail=5
```

### 1.7 O que o ambiente local **não** cobre

O SQS fica **desativado de propósito** no Compose padrão: `AWS_SQS_URL` recebe string
vazia no `evaluation-service` e no `analytics-service`. Consequências:

- o `evaluation-service` calcula a resposta normalmente, mas apenas registra no log
  que o envio ao SQS está desativado;
- o worker do `analytics-service` não é iniciado;
- o DynamoDB Local sobe para compor o ambiente, mas não recebe eventos
  automaticamente.

Essa separação é deliberada: evita que alguém precise de conta ou credencial AWS para
testar flags, regras, avaliação e cache. O caminho completo
`evaluation → SQS → analytics → DynamoDB` é exercitado de duas formas: pelo teste
integrado abaixo, com um simulador local, e no ambiente AWS (seção 5).

### 1.8 Teste integrado automatizado

O mesmo teste que roda no CI, no workflow **Compose Integration** — disparado em todo
pull request, em todo push na `main` e sob demanda pelo botão de execução manual, com
limite de 20 minutos.

Ele acrescenta o arquivo `docker-compose.integration.yaml`, que sobe o **Moto**, um
simulador local de SQS e DynamoDB, e um container inicializador que cria a fila e a
tabela antes das aplicações. Com isso o fluxo assíncrono, desligado no Compose
padrão, passa a ser exercitado de ponta a ponta.

**Pré-requisito extra:** o script chama o interpretador pelo nome exato `python3`.
Confirme antes de rodar:

```bash
python3 --version
```

> ⚠️ **No Windows isso costuma falhar.** O Git Bash normalmente só conhece `python`,
> e `python3` cai no atalho da Microsoft Store, que abre a loja em vez de executar
> nada. Se for o seu caso, rode o teste pelo WSL, ou crie um alias/link de `python3`
> para o seu `python` antes de continuar.

**Git Bash / WSL / Linux** (precisa de Docker Compose v2):

```bash
bash scripts/test-compose.sh
```

O script usa o `.env.example` e um projeto Compose separado, `tc03-integration`, para
não misturar com os containers do seu ambiente de desenvolvimento.

O teste confirma:

- health dos cinco serviços;
- rejeição de credencial inválida e criação/validação de uma chave local;
- persistência de flags e regras nos bancos PostgreSQL;
- avaliação de flags ligadas, desligadas, inexistentes e de regras de 0% e 100%;
- cache Redis com TTL e atualização da decisão depois da expiração;
- publicação dos eventos pelo evaluation, consumo pelo analytics, gravação no
  DynamoDB simulado e remoção das mensagens da fila.

A chave gerada durante o teste é entregue ao container de evaluation apenas por
variável de ambiente — não é impressa nem gravada em arquivo.

Para encerrar e descartar **somente os dados desse projeto de teste**:

**Git Bash / WSL / Linux:**

```bash
docker compose --env-file .env.example -p tc03-integration \
  -f docker-compose.yaml -f docker-compose.integration.yaml down -v
```

> ℹ️ Essa validação cobre a integração entre os serviços. O comportamento na AWS real
> — IAM, EKS, ECR, rede e o SQS de verdade — é o que a seção 5 deste guia verifica.

### 1.9 Comandos úteis do dia a dia

**Git Bash ou PowerShell:**

```bash
docker compose logs auth-service -f      # logs de um serviço, acompanhando
docker compose logs -f                   # logs de todos
docker compose down                      # para tudo, mantém os dados
docker compose down -v                   # para tudo e APAGA os bancos
docker compose restart evaluation-service
```

> ⚠️ Depois de `docker compose down -v` os bancos somem, e com eles a chave de API.
> Refaça o passo 1.4 antes de testar de novo.

---

# 2. Provisionar na AWS

### Pré-requisitos

| Ferramenta | Versão mínima | Por que essa versão |
|---|---|---|
| **Terraform** | **1.11.0** | As três camadas usam `use_lockfile`, o bloqueio de estado nativo do S3, que só existe a partir dessa versão. O CI usa a 1.16.0 |
| **AWS CLI** | v2 | Autenticação, `update-kubeconfig` e as conferências de teardown |
| **kubectl** | compatível com Kubernetes 1.34 | Operar o cluster |
| **Git** | qualquer | Levar as mudanças do GitOps até a `main` |
| **GitHub CLI** (`gh`) | autenticado (`gh auth status`) | Republicar as imagens (passo 2.4) e abrir e mesclar pull requests |

Além das ferramentas:

- **Conta AWS própria**, com permissão para criar VPC, EKS, RDS, ElastiCache e IAM.
- Região **`us-east-2`** (Ohio) em tudo. Exemplos herdados que citam `us-east-1`
  estão errados: a fonte que vale é o Terraform.
- **Bucket de estado** `togglemaster-tfstate-891376952395-us-east-2-an`, criado uma
  única vez fora do Terraform. O passo a passo está em
  `terraform/BOOTSTRAP-BACKEND-S3.md`.

> ⚠️ **Isto custa dinheiro de verdade.** Um `terraform apply` da camada de cluster
> cria EKS, duas instâncias RDS, ElastiCache e liga o NAT Gateway. Com tudo de pé são
> cerca de **US$ 0,39 por hora**; um fim de semana esquecido ligado passa de US$ 18.
> A [seção 6](#6-encerrar-a-sessão) não é opcional, e a [seção 8](#8-custo-por-sessão)
> tem a conta detalhada.

### 2.1 Pré-voo (5 minutos, custo zero)

Rode tudo isto **antes** de criar qualquer recurso. Cada linha existe porque a
ausência dela já custou tempo.

**Git Bash ou PowerShell:**

```bash
# Quem sou eu na AWS. Se isto falhar, nada adiante funciona.
aws sts get-caller-identity
```

Confira que o campo `Account` é a mesma conta dona do bucket de estado — é o número
que aparece nas URLs do ECR em `gitops/overlays/prod/kustomization.yaml`.

```bash
terraform version        # precisa ser >= 1.11.0
kubectl version --client
aws --version
gh auth status           # o passo 2.4 usa o gh para republicar as imagens
```

Se você usa perfis nomeados na AWS CLI, selecione o perfil na janela onde vai rodar
os comandos:

**PowerShell:**

```powershell
$env:AWS_PROFILE = "togglemaster"
```

**Git Bash:**

```bash
export AWS_PROFILE=togglemaster
```

**Descubra se a conta já tem o provedor OIDC do GitHub.** A AWS aceita um único
provedor por endereço em cada conta. Se outro projeto já registrou o GitHub, a camada
base não pode criar outro — precisa reaproveitar o que existe:

```bash
aws iam list-open-id-connect-providers
```

| A saída mostra `token.actions.githubusercontent.com`? | Em `terraform/terraform.tfvars` |
|---|---|
| **Sim** | `create_github_oidc_provider = false` |
| **Não** | `create_github_oidc_provider = true` (é o padrão) |

> ⚠️ Com `true` numa conta que já tem o provedor, o apply da base para no meio com
> `EntityAlreadyExists` — e o `plan` **não** avisa antes, porque só compara com o
> estado. Com `false`, o provedor é apenas lido: o destroy nunca o apaga, e o CI de
> quem o criou continua funcionando.

Por fim, veja **em que situação está a camada base** — as outras duas leem o estado
dela. Como o estado mora no S3, o diretório precisa estar inicializado antes de
qualquer leitura:

**Git Bash ou PowerShell:**

```bash
# Idempotente: rodar de novo não faz mal. Num clone novo, é obrigatório.
terraform -chdir=terraform init

terraform -chdir=terraform output github_actions_role_arn
```

| Saída | Significado | Próximo passo |
|---|---|---|
| Um ARN terminado em `role/togglemaster-github-actions` | A base está aplicada | O passo 2.3 só liga o NAT |
| `Warning: No outputs found` | A base não existe — foi destruída ou nunca subiu | O passo 2.3 cria a base inteira, e o **passo 2.4 é obrigatório** |

> ℹ️ `No outputs found` não é erro: o comando sai com código 0. Não reinicialize nada
> por causa dele.

### 2.2 As três camadas, e por que são três

| Camada | Pasta | Chave do estado | O que provisiona | Ciclo de vida |
|---|---|---|---|---|
| **Base** | `terraform/` | `prod/base.tfstate` | VPC, 5 repositórios ECR, fila SQS + DLQ, tabela DynamoDB, role do CI e o provedor OIDC, quando a conta ainda não tem | **Preservável entre sessões.** Custo ~US$ 0 com o NAT desligado. Destruí-la apaga as imagens do ECR |
| **Cluster** | `terraform/cluster/` | `prod/cluster.tfstate` | EKS, node group, 2 RDS, ElastiCache, 2 roles de IRSA | **Efêmera.** É o que cobra por hora |
| **K8s** | `terraform/k8s/` | `prod/k8s.tfstate` | 2 namespaces (`togglemaster` e `argocd`), 5 Secrets, StorageClass `gp3`, ArgoCD e a Application | **Efêmera.** Vive dentro do cluster |

A divisão existe por um motivo prático: o ambiente é destruído ao fim de cada sessão.
Com estado único, o `destroy` levaria junto os cinco repositórios ECR e, com
`force_delete` ligado, as imagens já publicadas — o CI teria de reconstruir e
reenviar tudo antes de cada sessão. Separando, **só a camada que cobra por hora
precisa subir e descer**.

Isso não impede destruir a base também — é o que se faz no encerramento do projeto,
para zerar o custo. A consequência é a do item 3 do topo: na próxima subida, o ECR
volta vazio e as imagens precisam ser republicadas.

```
 terraform/                  terraform/cluster/            terraform/k8s/
 ┌──────────────────┐        ┌──────────────────┐          ┌──────────────────┐
 │ VPC · ECR · SQS  │ ──lê──▶│ EKS · RDS ·      │ ──lê──▶  │ Secrets ·        │
 │ DynamoDB · OIDC  │  saída │ ElastiCache·IRSA │   saída  │ StorageClass ·   │
 │                  │        │                  │          │ ArgoCD           │
 │ preservável      │        │ efêmera          │          │ efêmera          │
 └──────────────────┘        └──────────────────┘          └──────────────────┘
        ~US$ 0/h                   paga por hora              dentro do cluster
```

### 2.3 Passo 1 — Aplicar a camada base e ligar o NAT

**O NAT Gateway é o item mais esquecido e o que mais dói.** Sem ele, os nós do EKS
ficam em subnet privada sem saída para a internet: não conseguem baixar imagem do ECR
nem falar com o control plane, e **todo pod fica em `ImagePullBackOff`**.

Se você ainda não tem um `terraform.tfvars`, crie a partir do exemplo versionado:

**Git Bash:**

```bash
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
```

**PowerShell:**

```powershell
Copy-Item terraform/terraform.tfvars.example terraform/terraform.tfvars
```

Edite o arquivo e confira as duas linhas que mudam o resultado:

```hcl
enable_nat_gateway          = true
create_github_oidc_provider = false   # ou true, conforme o pré-voo 2.1
```

**Git Bash ou PowerShell:**

```bash
terraform -chdir=terraform init     # só na primeira vez da máquina
terraform -chdir=terraform plan
```

**Leia o resumo do plan antes de aplicar.** Ele diz qual das situações do pré-voo você
está vivendo:

| Resumo do plan | Situação | Tempo do apply |
|---|---|---|
| Poucos recursos a criar: o NAT, o endereço IPv4 e a rota | A base já existia; só o NAT liga | ~2 min (medido: 2m24s) |
| `35 to add` (reaproveitando o provedor OIDC) ou `36 to add` (criando) | Base do zero | não medido — reserve 10 min |
| Qualquer `to destroy` | Você está mirando no estado errado | **Pare** e verifique o backend |

```bash
terraform -chdir=terraform apply
```

Ao terminar, confirme que a role do CI existe — o passo 2.4 depende dela:

```bash
terraform -chdir=terraform output github_actions_role_arn
```

**Esperado:** `arn:aws:iam::<conta>:role/togglemaster-github-actions`.

> 💡 **Atalho sem editar arquivo:** `terraform -chdir=terraform apply -var enable_nat_gateway=true`.
> O valor passado na linha de comando tem precedência sobre o `terraform.tfvars`.

> ℹ️ **Atenção ao padrão:** no `variables.tf` o valor padrão é `true`, para ninguém
> derrubar o cluster por esquecimento; é o `terraform.tfvars.example` que vem com
> `false`, para não pagar por um recurso ocioso. Ou seja: **sem nenhum tfvars, o NAT
> sobe ligado** — e cobrando.

**Anote o horário.** O relógio da sessão começa aqui: o NAT passa a custar
US$ 0,045/h (US$ 0,050/h com o IPv4 público junto), e quem desliga é a
[seção 6](#6-encerrar-a-sessão).

### 2.4 Passo 2 — Publicar as cinco imagens no ECR

**Obrigatório quando a base foi criada do zero no passo 2.3. Pule se a base já existia
e as imagens continuam lá.**

Para saber, liste as tags de cada repositório:

**Git Bash:**

```bash
for r in auth-service evaluation-service flag-service targeting-service analytics-service; do
  echo "== $r"
  aws ecr list-images --region us-east-2 --repository-name "$r" --query 'imageIds[].imageTag' --output text
done
```

Compare com as tags de `gitops/overlays/prod/kustomization.yaml`. Se algum repositório
vier vazio, siga abaixo.

**Por que é preciso.** Quem publica imagem é o pipeline, e só num `push` na `main`: os
jobs `Imagem Docker e push no ECR` e `Atualizar tag no GitOps` têm a condição
`github.event_name == 'push' && github.ref == 'refs/heads/main'`. Disparar o workflow
à mão pela aba Actions (`workflow_dispatch`) roda os testes e **não publica nada**.

**Pré-condição: o apply da base terminado.** O job de imagem assume a role
`togglemaster-github-actions`. Se ela ainda não existir — ou se a policy de push ainda
não estiver anexada —, o passo falha em `Could not assume role with OIDC` depois de
cerca de 1 minuto de tentativas, e nada repete sozinho. Espere o `Apply complete!` do
passo 2.3 antes de disparar.

**Pode rodar em paralelo com o passo 2.5.** O cluster não precisa das imagens para
subir; só os pods precisam. Dispare aqui e comece o apply do cluster logo em seguida.

#### Caminho A — re-executar os últimos runs da `main` (recomendado)

Sem commit e sem pull request. O re-run refaz o pipeline **inteiro** sobre o mesmo
commit — build, linter, SAST, SCA e scan da imagem rodam de novo — e publica a tag do
commit original, que é a que o overlay já referencia.

**Git Bash:**

```bash
# Para cada serviço, pega o run mais recente disparado por push na main e o re-executa.
for svc in auth-service evaluation-service flag-service targeting-service analytics-service; do
  id=$(gh run list --workflow "$svc.yml" --branch main --event push --limit 1 --json databaseId --jq '.[0].databaseId')
  echo "$svc -> run $id"
  gh run rerun "$id"
done
```

| Parte | O que faz |
|---|---|
| `gh run list --workflow <svc>.yml` | lista os runs do workflow daquele serviço |
| `--branch main --event push` | só os que nasceram de push na `main` — os únicos que publicam |
| `--jq '.[0].databaseId'` | pega o identificador do mais recente |
| `gh run rerun <id>` | re-executa o run inteiro, com todos os jobs |

> ⚠️ Use `gh run rerun <id>` **sem** `--failed`. Com `--failed`, só os jobs que
> falharam rodam de novo; sem ele, os portões de segurança também se repetem.

> ℹ️ O GitHub só re-executa runs de até 30 dias. Passado isso, use o caminho B.

Se a tag de algum serviço no overlay for de um commit **anterior** ao do run
re-executado, o job de GitOps comita a tag nova na `main` sozinho — é esperado. Para
os demais, ele termina com `A tag ja esta correta`.

#### Caminho B — um commit que dispare os cinco pipelines

Para quando o re-run não serve: runs com mais de 30 dias, ou quando é preciso mudar
algo antes de publicar, como uma exceção nova no `.trivyignore`.

Os workflows de serviço escutam alterações no workflow reutilizável da própria stack:
`_ci-go.yml` dispara `auth` e `evaluation`; `_ci-python.yml` dispara `flag`,
`targeting` e `analytics`. Alterar um comentário nos dois basta.

**Git Bash:**

```bash
git switch dev
# edite um comentário em .github/workflows/_ci-go.yml e em .github/workflows/_ci-python.yml
git add .github/workflows/_ci-go.yml .github/workflows/_ci-python.yml
git commit -m "ci: republica as imagens no ECR recriado"
git push origin dev
gh pr create --base main --head dev --title "ci: republica as imagens no ECR recriado" --body "Base recriada do zero; ECR vazio."
gh pr merge --merge
```

> ⚠️ No `git add`, liste só os arquivos que você mudou. Um `git add -A` leva junto
> qualquer alteração local que não era para ir.

O merge gera tags novas, com o hash do commit de merge, e o job de GitOps as comita na
`main`.

> ⚠️ **Limite de jobs simultâneos.** No plano gratuito, uma organização roda até 20
> jobs ao mesmo tempo. O caminho B dispara três ondas — push na `dev`, pull request e
> merge na `main` —, e só a última publica. Se a fila travar, cancele os runs que não
> publicam:
>
> ```bash
> gh run list --branch dev --json databaseId,status --jq '.[] | select(.status != "completed") | .databaseId' | xargs -n1 gh run cancel
> ```

#### Conferir antes de seguir

```bash
gh run list --branch main --limit 10
```

Os cinco workflows de serviço em `completed` com `success`. Depois repita a listagem de
tags do início desta seção: cada repositório precisa ter a tag que o overlay espera.

**Não aplique a camada k8s (passo 2.7) antes disso.** No caminho A, a tag publicada é a
mesma que o Deployment usa: se o pod nascer antes da imagem, o Kubernetes só tenta
baixar de novo no próximo ciclo de espera, que chega a 5 minutos. O
[passo 2.9](#29-passo-7--conferir-os-endereços-no-overlay-do-gitops) mostra como
destravar se acontecer.

Se o scan barrar a imagem por uma CVE crítica nova, a correção está na
[seção 7](#7-armadilhas-conhecidas).

### 2.5 Passo 3 — Subir o cluster (15 a 30 minutos)

**Git Bash ou PowerShell:**

```bash
terraform -chdir=terraform/cluster init    # só na primeira vez da máquina
terraform -chdir=terraform/cluster apply
```

O que demora: o control plane do EKS leva cerca de 10 minutos, o node group mais 5, e
as duas instâncias RDS cerca de 10, em paralelo. Na sessão de 11/09, o apply inteiro
levou **15m42s**. Enquanto isso, o passo 2.4 pode estar publicando as imagens.

> ⚠️ **Confira o resumo antes de confirmar.** Numa subida em cluster novo deve ser
> algo como `N to add, 0 to change, 0 to destroy`. Qualquer `destroy` no resumo da
> primeira subida significa que você está mirando num estado que não é o esperado —
> pare e verifique o backend.

### 2.6 Passo 4 — Apontar o kubectl para o cluster

**Git Bash ou PowerShell:**

```bash
# Escreve o contexto do cluster no seu ~/.kube/config.
aws eks update-kubeconfig --region us-east-2 --name togglemaster

kubectl get nodes
```

**Esperado:** 2 nós em `Ready`.

> ⚠️ Se aparecer `Unauthorized`, quem está rodando o comando não é o mesmo usuário
> IAM que criou o cluster. Só o criador recebe acesso de administrador automaticamente
> (`bootstrap_cluster_creator_admin_permissions`). Verifique o perfil ativo com
> `aws sts get-caller-identity`.

### 2.7 Passo 5 — Secrets, StorageClass e ArgoCD (dois comandos)

**Pré-condição:** as cinco tags do overlay já presentes no ECR
([passo 2.4](#24-passo-2--publicar-as-cinco-imagens-no-ecr)). Aplicar antes faz os pods
nascerem em `ImagePullBackOff`.

**SÃO DOIS COMANDOS, NESTA ORDEM. Não pule o primeiro.**

**Por quê:** a Application do ArgoCD é um objeto de um tipo (`Application`) que só
passa a existir no cluster **depois** que o próprio ArgoCD é instalado. Mas o
Terraform valida esse tipo contra o cluster ainda na fase de *plan*, isto é, antes de
instalar qualquer coisa. Em um cluster novo, o apply direto falha com
`no matches for kind "Application"` — e declarar dependência entre os recursos não
resolve, porque o problema é de ordem entre *plan* e *apply*, não entre recursos.

O `-target` abaixo resolve limitando a primeira rodada à instalação. Com o cluster
efêmero, isso acontece **toda sessão** — não é um caso raro.

**Etapa A — instala o ArgoCD e, com ele, o tipo que falta:**

```bash
terraform -chdir=terraform/k8s init    # só na primeira vez da máquina
terraform -chdir=terraform/k8s apply -target=helm_release.argocd
```

**Etapa B — agora o resto, incluindo a Application que aponta para o Git:**

```bash
terraform -chdir=terraform/k8s apply
```

### 2.8 Passo 6 — Conferir o que a camada criou

**Git Bash ou PowerShell:**

```bash
# Devem existir 5 Secrets no namespace da aplicação.
kubectl get secrets -n togglemaster

# A StorageClass gp3 precisa existir, e com esse nome exato.
kubectl get storageclass
```

Os nomes e as chaves esperadas de cada Secret estão em `gitops/SECRETS-CONTRATO.md`.
É a primeira coisa a conferir se algum pod ficar em `CreateContainerConfigError`.

### 2.9 Passo 7 — Conferir os endereços no overlay do GitOps

Alguns valores dos manifestos só nascem com o apply do cluster. Eles **já estão
preenchidos no repositório** e, na prática, se repetem a cada recriação — mas a
conferência leva um minuto e evita um pod quebrado difícil de explicar.

**Git Bash ou PowerShell:**

```bash
terraform -chdir=terraform/cluster output redis_url
terraform -chdir=terraform/cluster output irsa_role_arns
```

Compare com o repositório:

- **`gitops/overlays/prod/patches/endpoints.yaml`** — o `REDIS_URL` e o `AWS_SQS_URL`.
  A URL da fila é estável: depende só do nome da fila e da conta. O endereço do
  ElastiCache carrega um identificador gerado pela AWS; o histórico do projeto mostra o
  mesmo identificador em duas criações diferentes, o que indica que ele pertence à conta
  e à região, e não a cada cluster. Ainda assim, confira.
- **`gitops/overlays/prod/patches/irsa.yaml`** — os dois ARNs de role. São estáveis:
  os nomes das roles são fixos.
- **`gitops/overlays/prod/kustomization.yaml`** — as cinco tags de imagem. **Não
  mexa à mão.** Quem escreve ali é o último job do pipeline.

Se o `REDIS_URL` divergir, o `evaluation-service` encerra logo na partida, sem
conseguir conectar no Redis, e fica em `CrashLoopBackOff`. Este comando lê a saída do
Terraform e reescreve o arquivo sem digitação manual:

**Git Bash / WSL** (usa `$(...)`, `sed` e `&&`):

```bash
REDIS=$(terraform -chdir=terraform/cluster output -raw redis_url) \
  && sed -i "s|redis://togglemaster-redis.*:6379|${REDIS}|" gitops/overlays/prod/patches/endpoints.yaml \
  && grep REDIS_URL gitops/overlays/prod/patches/endpoints.yaml
```

A última parte imprime a linha resultante — confira antes de seguir.

**Como levar isso até a `main`.** O ArgoCD só enxerga o que está no Git, e a regra do
projeto é não commitar direto na `main`: trabalho humano sai da `dev` e chega à `main`
por pull request.

**Git Bash:**

```bash
git switch dev
git add gitops/overlays/prod/patches/endpoints.yaml
git commit -m "chore(gitops): endpoints reais da sessao"
git push origin dev
gh pr create --base main --head dev --title "chore(gitops): endpoints reais da sessao" --body "Valores gerados pelo apply desta sessao." && gh pr merge --merge
```

**PowerShell** (o 5.1 não aceita `&&`):

```powershell
gh pr create --base main --head dev --title "chore(gitops): endpoints reais da sessao" --body "Valores gerados pelo apply desta sessao."; if ($?) { gh pr merge --merge }
```

Depois do merge, traga a `dev` de volta ao mesmo ponto. **A `main` anda sozinha**: o job
de GitOps do CI comita a tag da imagem direto nela, então a `dev` fica para trás sem
ninguém perceber.

**Git Bash:**

```bash
git switch dev && git fetch origin && git merge --ff-only origin/main && git push origin dev
```

**PowerShell:**

```powershell
git switch dev; if ($?) { git fetch origin }; if ($?) { git merge --ff-only origin/main }; if ($?) { git push origin dev }
```

> ⚠️ Se aparecer `fatal: Not possible to fast-forward, aborting.`, nada quebrou: a
> `dev` tem um commit que a `main` ainda não tem, e o robô comitou na `main` nesse
> meio-tempo. Resolva com `git pull --no-rebase origin main` e depois
> `git push origin dev`.

**Antes de seguir para a seção 3: espere os pods ficarem prontos.**

A camada `terraform/k8s/` criou namespaces, Secrets, StorageClass e a Application —
mas **nenhum Deployment e nenhum Service**. Esses vêm de `gitops/base/`, e quem os aplica
é o ArgoCD, lendo o repositório. A reconciliação roda de 30 em 30 segundos, e a primeira
leva 1 ou 2 minutos:

```bash
kubectl get pods -n togglemaster
```

**Critério para avançar:** todos os pods — no mínimo seis, os cinco serviços e o
`postgres-targeting` — em `Running` com `READY 1/1`. Uma lista que apenas não vem vazia
não basta: pods em `ImagePullBackOff` também aparecem nela. É normal que `auth` e
`flag` fiquem prontos antes de os schemas existirem; eles só quebram quando alguém tenta
gravar, e é isso que a seção 3 resolve.

> 💡 **Pod parado em `ImagePullBackOff` com a imagem já no ECR?** Apague o pod. O
> ReplicaSet recria na hora e o download é imediato, sem esperar o próximo ciclo:
>
> ```bash
> kubectl get pods -n togglemaster
> kubectl delete pod -n togglemaster <nome-do-pod>
> ```

### 2.10 Credencial do ArgoCD para clonar o repositório

**Com o repositório público, não há o que autenticar** — o ArgoCD clona
anonimamente e não é preciso configurar nada. O código já prevê isso: o Secret de
credencial só é criado se a variável `github_token` tiver valor
(`count = var.github_token != "" ? 1 : 0`). Basta **não definir** a variável.

<details>
<summary><strong>Se você usar este projeto em um repositório privado</strong> (clique para abrir)</summary>

Repositório privado exige credencial: sem ela o ArgoCD mostra
`authentication required` e a Application nunca sai de `Unknown`.

**Crie e teste o token antes de subir o cluster.** Criar leva 3 minutos e não custa
nada; descobrir que ele não funciona com o cluster no ar custa a sessão.

Se o repositório pertencer a uma **organização**, há um passo que não existe em
repositório pessoal:

1. GitHub → sua foto → **Settings**
2. Barra lateral, até o fim → **Developer settings**
3. **Personal access tokens** → **Fine-grained tokens** → **Generate new token**
4. **Resource owner:** selecione a **organização**, e não sua conta pessoal. **Este é
   o passo que costuma passar batido** — com o dono errado o token é criado
   normalmente e falha só na hora de clonar.
5. **Repository access:** *Only select repositories* → o repositório do projeto
6. **Permissions** → *Repository permissions* → **Contents** → **Read-only**. Nada
   além disso: o ArgoCD só precisa ler.
7. **Generate token** e **copie o valor agora** — o GitHub mostra uma vez só.

Se o token ficar em *pending approval*, um dono da organização libera em
**Organização → Settings → Personal access tokens → Pending requests**. Se a opção
nem aparecer, marque *Allow access via fine-grained personal access tokens* nas
configurações da organização.

Token **clássico** com escopo `repo` também funciona e não depende de política da
organização, mas a permissão é muito mais larga — não existe escopo de somente
leitura nesse modelo. Prefira o fine-grained.

**Informar o token ao Terraform.** Ele lê sozinho qualquer variável de ambiente que
comece com `TF_VAR_`, então `TF_VAR_github_token` vira a variável `github_token`.

**PowerShell:**

```powershell
$env:TF_VAR_github_token = "github_pat_COLE_AQUI"
```

**Git Bash:**

```bash
export TF_VAR_github_token="github_pat_COLE_AQUI"
```

Duas coisas que valem lembrar: a variável **vale só para aquela janela** — defina na
mesma onde vai rodar o apply da camada k8s; e **nunca coloque o token em arquivo** —
a variável de ambiente não deixa rastro em disco.

**Testar o token antes de gastar**, usando exatamente o mesmo mecanismo do ArgoCD
(HTTPS com usuário `git` e o token como senha):

**Git Bash:**

```bash
git ls-remote "https://git:$TF_VAR_github_token@github.com/<org>/<repo>.git" | head -3
```

Listou linhas com hashes e nomes de branch, o token funciona. Veio
`Authentication failed`, revise o *Resource owner* e verifique se o token não está
aguardando aprovação. O histórico do shell guarda a linha com `$TF_VAR_github_token`
sem expandir, então o valor não fica gravado ali.

</details>

---

# 3. Criar os schemas dos bancos

**Passo obrigatório e fácil de esquecer.**

O Terraform cria as **instâncias** RDS e os bancos vazios — mas não cria **tabela
nenhuma**. Os schemas existem em `services/*/db/init.sql` e são carregados
automaticamente **apenas** pelo Docker Compose, no ambiente local. No caminho AWS,
ninguém os executa.

Sem este passo, o `auth-service` e o `flag-service` sobem, respondem `/health` com
200 e falham no primeiro INSERT, com `relation "api_keys" does not exist`.
**Health verde não prova banco pronto.**

> ℹ️ O `targeting_db` é a exceção: como roda em pod, o schema vai num ConfigMap e o
> próprio PostgreSQL o executa na primeira subida.

### Você não precisa descobrir senha nem endereço

Quando o Terraform criou os bancos, ele gerou uma senha aleatória para cada um e
montou uma URL de conexão completa, que ficou dentro do Secret que o próprio serviço
usa. A URL traz as quatro informações de uma vez:

```
postgres://toggle:SENHA@endereco-do-rds.amazonaws.com:5432/auth_db
         └usuário┘ └──┘ └──────────────────────────┘      └banco┘
                  senha            endereço
```

E o `psql` aceita essa URL inteira como primeiro argumento. Ou seja: **basta ler o
Secret e entregar o valor ao `psql`**. Nada para preencher na mão.

### 3.1 Guardar a URL numa variável do terminal

**Git Bash / WSL:**

```bash
AUTH_DB=$(kubectl get secret auth-service-secret -n togglemaster -o jsonpath='{.data.DATABASE_URL}' | base64 -d)
```

```bash
FLAG_DB=$(kubectl get secret flag-service-secret -n togglemaster -o jsonpath='{.data.DATABASE_URL}' | base64 -d)
```

Parte por parte:

| Trecho | O que faz |
|---|---|
| `VARIAVEL=$(...)` | roda o comando entre parênteses e guarda a saída na variável, sem imprimir nada |
| `get secret auth-service-secret` | lê o Secret que o Terraform criou |
| `-o jsonpath='{.data.DATABASE_URL}'` | extrai só o campo da URL |
| `\| base64 -d` | decodifica. O Kubernetes guarda Secrets em base64 — que não é criptografia, é só codificação |

**PowerShell** (equivalente; o `base64 -d` não existe, então a decodificação é feita
pelo próprio .NET):

```powershell
$AUTH_DB = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String(
  (kubectl get secret auth-service-secret -n togglemaster -o jsonpath='{.data.DATABASE_URL}')
))
$FLAG_DB = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String(
  (kubectl get secret flag-service-secret -n togglemaster -o jsonpath='{.data.DATABASE_URL}')
))
```

> 💡 **Por que usar variável em vez de colar o valor:** na tela aparece `$AUTH_DB`,
> nunca a senha. Em qualquer terminal compartilhado ou capturado, senha impressa é
> senha vazada.

Para **conferir** que a variável foi preenchida sem expor a senha:

**Git Bash:**

```bash
# Mostra só o começo e o fim da URL — o protocolo e o endereço do banco.
echo "${AUTH_DB%%:*}// ... ${AUTH_DB##*@}"
```

### 3.2 Aplicar os schemas

O RDS está em subnet privada: nada de fora do cluster o alcança. Por isso o `psql`
roda **de dentro**, num pod descartável.

**Git Bash / WSL** (este é o caminho recomendado — usa `<`):

```bash
kubectl run psql-auth --rm -i --restart=Never -n togglemaster --image=postgres:16-alpine -- psql "$AUTH_DB" < services/auth-service/db/init.sql
```

```bash
kubectl run psql-flag --rm -i --restart=Never -n togglemaster --image=postgres:16-alpine -- psql "$FLAG_DB" < services/flag-service/db/init.sql
```

Parte por parte:

| Trecho | O que faz |
|---|---|
| `kubectl run psql-auth` | cria um pod avulso com esse nome |
| `--rm` | apaga o pod assim que ele terminar — não deixa lixo no cluster |
| `-i` | liga a entrada padrão: é o que permite empurrar o arquivo `.sql` para dentro |
| `--restart=Never` | pod de tarefa única; sem isso o Kubernetes o reiniciaria em loop ao terminar |
| `--image=postgres:16-alpine` | imagem oficial, que já traz o cliente `psql` |
| `--` | fim das opções do `kubectl`; o que vem depois é o comando do container |
| `psql "$AUTH_DB"` | conecta usando a URL inteira. As aspas são obrigatórias: sem elas, caracteres da senha podem ser interpretados pelo shell |
| `< arquivo.sql` | manda o conteúdo do arquivo **da sua máquina** para a entrada do `psql` |

> ⚠️ **O `<` como redirecionamento de arquivo não existe no PowerShell** — lá o
> comando falha com erro de sintaxe. Este é um dos passos que exigem o terminal
> certo.

**PowerShell** (equivalente, canalizando o arquivo em vez de redirecionar):

```powershell
Get-Content services/auth-service/db/init.sql -Raw |
  kubectl run psql-auth --rm -i --restart=Never -n togglemaster --image=postgres:16-alpine -- psql "$AUTH_DB"
```

> ℹ️ Os schemas usam `CREATE TABLE IF NOT EXISTS`, então rodar duas vezes não quebra
> nada. Na dúvida se já rodou, rode de novo.

### 3.3 Conferir antes de seguir

**Git Bash ou PowerShell:**

```bash
kubectl run psql-check --rm -i --restart=Never -n togglemaster --image=postgres:16-alpine -- psql "$AUTH_DB" -c "\dt"
```

O `-c` executa um comando único e sai; `\dt` lista as tabelas.

Tem que aparecer a tabela **`api_keys`**. Repita trocando `$AUTH_DB` por `$FLAG_DB` —
lá deve aparecer **`flags`**.

Se vier `No relations found`, o schema não foi aplicado.

### 3.4 Se precisar mesmo ver as partes separadas

Para diagnóstico — por exemplo, para confirmar que o endereço do RDS bate com o que o
Terraform criou:

**Git Bash ou PowerShell:**

```bash
terraform -chdir=terraform/cluster output rds_endpoints
```

E a URL completa, **com a senha visível na tela** — evite em terminal compartilhado
ou capturado:

**Git Bash:**

```bash
kubectl get secret auth-service-secret -n togglemaster -o jsonpath='{.data.DATABASE_URL}' | base64 -d
```

---

# 4. Acessar o ArgoCD

O projeto **não tem Ingress nem Load Balancer** — foi uma decisão consciente, que
economiza de US$ 16 a US$ 20 por mês. O acesso é por túnel local.

Primeiro, confirme que o ArgoCD está de pé:

**Git Bash ou PowerShell:**

```bash
kubectl get pods -n argocd
```

Abra o túnel. **Este terminal fica travado enquanto o túnel estiver aberto** — use
outra janela para os demais comandos:

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:80
```

O usuário é `admin`. A senha inicial é gerada pelo chart e guardada num Secret:

**Git Bash / WSL:**

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
```

**PowerShell:**

```powershell
[Text.Encoding]::UTF8.GetString([Convert]::FromBase64String(
  (kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}')
))
```

Acesse **http://localhost:8080**.

> ℹ️ A senha não é exposta como saída do Terraform de propósito: um output ficaria
> gravado em texto dentro do arquivo de estado.

> 💡 **Reconciliação a cada 30 segundos.** O intervalo padrão do ArgoCD é de 3
> minutos; aqui ele foi reduzido para 30 segundos, porque sem Ingress não há como
> receber webhook do GitHub. É por isso que a sincronização aparece rápido depois de
> um commit.

---

# 5. Verificar que funciona ponta a ponta

> ℹ️ **Pré-requisito:** todos os pods de `kubectl get pods -n togglemaster` em
> `Running` com `READY 1/1` (fim do passo 2.9), e os schemas do RDS já aplicados
> (seção 3). Sem isso, os port-forwards abaixo falham com `pod is not running`.

> ⚠️ **Rode os passos 5.1 a 5.3 na mesma janela de terminal.** A chave de API criada
> no 5.1 fica numa variável da sessão e é usada nos passos seguintes — e ela só é
> devolvida uma vez.

### 5.1 Semear os dados

O `terraform destroy` apaga os bancos, então **o seed precisa ser refeito a cada
sessão**. Sem ele o sistema sobe vazio e não há o que verificar.

Abra um túnel para cada serviço, **cada um em um terminal próprio**:

**Git Bash ou PowerShell (um por janela):**

```bash
kubectl port-forward svc/auth-service       -n togglemaster 8001:8001
kubectl port-forward svc/flag-service       -n togglemaster 8002:8002
kubectl port-forward svc/targeting-service  -n togglemaster 8003:8003
kubectl port-forward svc/evaluation-service -n togglemaster 8004:8004
```

**Pegue a `MASTER_KEY` do Secret e crie a chave de API já guardando a resposta numa
variável.** A chave tem 71 caracteres e só aparece uma vez; copiá-la da tela à mão é o
ponto onde esta verificação costuma quebrar.

**Git Bash:**

```bash
MASTER=$(kubectl get secret auth-service-secret -n togglemaster -o jsonpath='{.data.MASTER_KEY}' | base64 -d)

CHAVE=$(curl -s -X POST http://localhost:8001/admin/keys \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $MASTER" \
  -d '{"name":"demo-fase3"}' | sed -E 's/.*"key":"([^"]+)".*/\1/')

# Mostra só o começo, para conferir sem expor a chave inteira.
echo "${CHAVE:0:12}..."
```

**PowerShell:**

```powershell
$MASTER = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String(
  (kubectl get secret auth-service-secret -n togglemaster -o jsonpath='{.data.MASTER_KEY}')
))

$CHAVE = (Invoke-RestMethod `
  -Method Post -Uri "http://localhost:8001/admin/keys" `
  -Headers @{ Authorization = "Bearer $MASTER" } `
  -ContentType "application/json" `
  -Body (@{ name = "demo-fase3" } | ConvertTo-Json -Compress)).key

$CHAVE.Substring(0, 12) + "..."
```

**Esperado:** algo como `tm_key_3f9a...`. Se vier vazio ou com `{`, a chamada falhou —
confira o túnel da porta 8001 e a `MASTER_KEY`.

### 5.2 Sincronizar a chave com o evaluation-service

O `SERVICE_API_KEY` do Secret é um valor **provisório** gerado pelo Terraform — ele não
corresponde a nenhuma chave real do banco, porque o banco nasce depois. Substitua pela
chave recém-criada e reinicie o pod, **na mesma janela do 5.1**, onde a variável existe:

**Git Bash:**

```bash
kubectl create secret generic evaluation-service-secret -n togglemaster \
  --from-literal=SERVICE_API_KEY="$CHAVE" \
  --dry-run=client -o yaml | kubectl apply -f -
```

**PowerShell** (numa linha só — o PowerShell não usa `\` para continuar linha):

```powershell
kubectl create secret generic evaluation-service-secret -n togglemaster --from-literal=SERVICE_API_KEY=$CHAVE --dry-run=client -o yaml | kubectl apply -f -
```

**Confira a saída:** ela precisa dizer `secret/evaluation-service-secret configured`. Só
então reinicie:

```bash
kubectl rollout restart deployment/evaluation-service -n togglemaster
```

> ℹ️ Recriar o Secret inteiro é seguro aqui: `evaluation-service-secret` tem uma
> única chave. E o Terraform não vai brigar por esse valor em applies futuros — o
> recurso declara `ignore_changes` no conteúdo justamente para que o seed mande nele
> depois de criado.

> ℹ️ Efeito colateral inofensivo: o `apply` remove o rótulo `app=evaluation-service`
> que o Terraform tinha posto no Secret. Nenhum seletor depende dele; o rótulo volta
> no próximo `terraform apply` que recriar o Secret do zero.

### 5.3 Criar uma flag e uma regra

Ainda na mesma janela, com `CHAVE` definida:

**Git Bash:**

```bash
curl -X POST http://localhost:8002/flags \
  -H "Content-Type: application/json" -H "Authorization: Bearer $CHAVE" \
  -d '{"name":"novo-painel","description":"Painel novo para demonstracao","is_enabled":true}'
```

```bash
curl -X POST http://localhost:8003/rules \
  -H "Content-Type: application/json" -H "Authorization: Bearer $CHAVE" \
  -d '{"flag_name":"novo-painel","rules":{"type":"PERCENTAGE","value":100},"is_enabled":true}'
```

**PowerShell:**

```powershell
Invoke-RestMethod -Method Post -Uri "http://localhost:8002/flags" `
  -Headers @{ Authorization = "Bearer $CHAVE" } -ContentType "application/json" `
  -Body (@{ name = "novo-painel"; description = "Painel novo para demonstracao"; is_enabled = $true } | ConvertTo-Json -Compress)

Invoke-RestMethod -Method Post -Uri "http://localhost:8003/rules" `
  -Headers @{ Authorization = "Bearer $CHAVE" } -ContentType "application/json" `
  -Body (@{ flag_name = "novo-painel"; is_enabled = $true; rules = @{ type = "PERCENTAGE"; value = 100 } } | ConvertTo-Json -Depth 4 -Compress)
```

> ⚠️ O `evaluation-service` implementa **apenas o tipo `PERCENTAGE`**. Uma regra com
> `user_ids` seria aceita pelo targeting, mas ignorada na avaliação. Com `value: 100`
> o resultado é sempre `true` e com `value: 0` sempre `false` — determinístico, que é
> o que se quer numa verificação.

### 5.4 Avaliar a flag

**Git Bash:**

```bash
curl "http://localhost:8004/evaluate?flag_name=novo-painel&user_id=user-123"
```

**PowerShell:**

```powershell
curl.exe "http://localhost:8004/evaluate?flag_name=novo-painel&user_id=user-123"
```

**Esperado:** `"result": true`, porque a regra é de 100%.

> ℹ️ **Sem cabeçalho de autorização, igual ao passo 1.6.** O `/evaluate` é aberto; a
> chave criada no passo 5.1 não é usada por quem chama, e sim pelo próprio
> `evaluation-service` ao consultar o flag e o targeting — é exatamente o valor que o
> passo 5.2 colocou no Secret. Se a chave estiver errada, o sintoma é HTTP 502 aqui e
> 401 no log do pod.

Para ver o caminho oposto, crie uma segunda flag com `{"type":"PERCENTAGE","value":0}`
e avalie: deve vir `false`. Não adianta só trocar o `user_id` na mesma flag — com
100% todo usuário dá `true`.

> 💡 **Lembre do cache.** O `evaluation-service` guarda a decisão no Redis por 30
> segundos. Se você alterar a regra e reavaliar o **mesmo** par flag/usuário logo em
> seguida, a resposta pode vir do cache.

Essa chamada exercita o caminho completo: o evaluation lê do Redis, consulta o flag e
o targeting, e publica o evento na SQS — que o analytics consome e grava no DynamoDB.

### 5.5 As quatro conferências que provam o ambiente

**1. Os cinco serviços e o banco em pod estão de pé:**

```bash
kubectl get pods -n togglemaster
```

Esperado: 5 Deployments com 1 réplica cada, mais o StatefulSet do
`postgres-targeting`, todos `Running` e `READY 1/1`.

**2. O ArgoCD reconciliou o que está no Git:**

```bash
kubectl get application togglemaster -n argocd -o jsonpath='{.status.sync.status} / {.status.health.status}'
```

Esperado: `Synced / Healthy`. Na interface, os cinco microsserviços aparecem verdes.
Depois de um commit de tag na `main`, o card sai de `Synced` para `OutOfSync` e volta
sozinho — a política de sincronização é automática, com `prune` e `selfHeal` ligados.

**3. O caminho assíncrono gravou no DynamoDB:**

```bash
aws dynamodb scan --table-name ToggleMasterAnalytics --region us-east-2 --select COUNT
```

O `Count` precisa ser maior que zero depois das avaliações do passo 5.4. É a prova de
que o evento saiu do evaluation, passou pela SQS, foi consumido pelo analytics e
gravado — tudo sem nenhuma credencial estática, por IRSA. (Este comando exige
permissão de `dynamodb:Scan` para o seu usuário; os pods não precisam dela.)

**4. Os autoscalers estão lendo métrica:**

```bash
kubectl get hpa -n togglemaster
```

Esperado: dois HPAs (`evaluation-service` e `analytics-service`) com um percentual na
coluna de targets. `<unknown>` logo após a subida é normal por cerca de 2 minutos,
enquanto o Metrics Server inicializa.

---

# 6. Encerrar a sessão

**Nenhum passo desta seção é opcional.** Leva de 15 a 25 minutos — em 11/09, as três
camadas foram destruídas em cerca de 13 minutos.

> ⚠️ Os comandos abaixo **destroem infraestrutura**. O `destroy` da camada de cluster
> apaga as duas instâncias RDS e todos os dados nelas, sem snapshot. Cada comando
> pede confirmação; leia o resumo antes de digitar `yes`.

> ⚠️ **Antes de destruir, confirme que terminou tudo o que precisava do ambiente.**
> Recriar do zero depois custa de 40 minutos a 1 hora, mais a republicação das imagens.

### 6.1 Derrubar a camada k8s

**Git Bash ou PowerShell:**

```bash
terraform -chdir=terraform/k8s destroy
```

Medido: cerca de 1m30s.

### 6.2 Derrubar o cluster

```bash
terraform -chdir=terraform/cluster destroy
```

Medido: cerca de 8 minutos.

> ⚠️ **Se travar em VPC ou subnet:** normalmente é um Load Balancer criado pelo
> Kubernetes segurando a subnet. Não deveria acontecer aqui, porque o projeto não tem
> Ingress, mas se acontecer, apague o Load Balancer órfão no console do EC2 e rode o
> destroy de novo.

### 6.3 A camada base: escolha uma das duas opções

| | Opção A — desligar só o NAT | Opção B — destruir a base também |
|---|---|---|
| **Quando usar** | Entre sessões, quando o ambiente vai subir de novo em breve | No encerramento do projeto |
| **Custo parado** | ~US$ 0 | US$ 0 |
| **Próxima subida** | Mais rápida: o ECR mantém as imagens | Refazer a base e republicar as imagens (passo 2.4) |
| **Efeito colateral** | Nenhum | Qualquer merge na `main` que mexa em `services/` ou nos workflows `_ci-*.yml` fica vermelho no job de imagem, porque a role do CI deixa de existir |

#### Opção A — desligar só o NAT

Volte `terraform/terraform.tfvars` para:

```hcl
enable_nat_gateway = false
```

```bash
terraform -chdir=terraform apply
```

Ou, direto pela linha de comando:

```bash
terraform -chdir=terraform apply -var enable_nat_gateway=false
```

> ⚠️ Esquecer este passo custa **US$ 0,045/h só pela hora do NAT** — perto de
> US$ 0,050/h somando o IPv4 público. Uma semana esquecida são cerca de US$ 8, e um mês
> inteiro fica entre US$ 33 e US$ 36, com nada rodando.

#### Opção B — destruir a base

```bash
terraform -chdir=terraform destroy
```

Medido: cerca de 2 minutos. **Leia o resumo antes do `yes`:** os repositórios ECR usam
`force_delete`, então as imagens vão junto.

> ℹ️ Se a conta reaproveita um provedor OIDC de outro projeto
> (`create_github_oidc_provider = false`), o resumo **não pode** listar
> `aws_iam_openid_connect_provider` para destruição — ele é só lido, nunca apagado. Se
> aparecer, pare e confira o `terraform.tfvars`.

### 6.4 Conferir que não sobrou nada caro

**Git Bash ou PowerShell:**

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

```bash
aws ec2 describe-addresses --region us-east-2 --query "Addresses[].PublicIp"
```

**As cinco saídas precisam vir vazias.** Um endereço IPv4 público solto também cobra.

Com a opção A, continuam de pé VPC, subnets, ECR, SQS, DynamoDB e IAM — nenhum deles
cobra parado. Com a opção B, não sobra nada disso; confira com
`aws ecr describe-repositories --region us-east-2`, que deve voltar sem repositórios.

---

# 7. Armadilhas conhecidas

| Onde | Sintoma | Causa | Correção |
|---|---|---|---|
| AWS | Apply da base para com `EntityAlreadyExists` no provedor OIDC | A conta já tem o provedor `token.actions.githubusercontent.com`, criado por outro projeto | `create_github_oidc_provider = false` no `terraform.tfvars` (pré-voo 2.1) |
| AWS | `plan` da base falha no data source do provedor OIDC | `create_github_oidc_provider = false`, mas a conta não tem mais o provedor | Voltar para `true` e aplicar a base |
| AWS | Todos os pods em `ImagePullBackOff` logo depois de recriar a base | O ECR recriado nasce vazio; as tags do overlay não existem | Passo 2.4: republicar as imagens |
| AWS | Pod em `ImagePullBackOff` mesmo com a imagem já no ECR | A imagem chegou com a mesma tag depois de o pod nascer; o Kubernetes espera o próximo ciclo, de até 5 minutos | `kubectl delete pod -n togglemaster <nome>` (fim do passo 2.9) |
| AWS | Pods em `ImagePullBackOff` com as imagens no ECR e a base antiga | NAT Gateway desligado | Passo 2.3: `enable_nat_gateway = true` |
| CI | Job `Imagem Docker e push no ECR` falha em `Could not assume role with OIDC` | A role `togglemaster-github-actions` não existe: base destruída ou apply ainda em andamento | Terminar o apply da base e rodar `gh run rerun <id>` (passo 2.4) |
| CI | SCA ou scan da imagem vermelho por CVE crítica nova, sem mudança no código | Imagem base de tag flutuante (`python:3.12-slim`, `alpine:3.20`) ou dependência ganhou CVE | Na `dev`: registrar a CVE em `.trivyignore`, com data e justificativa, **e** tocar um comentário no `_ci-*.yml` da stack; depois pull request e merge (caminho B do passo 2.4). Re-run não resolve: ele usa o `.trivyignore` do commit antigo |
| CI | Disparar o workflow pela aba Actions não publica imagem | `workflow_dispatch` não satisfaz a condição dos jobs de imagem e GitOps | Re-run de um run de push na `main`, ou commit (passo 2.4) |
| CI | Merge na `main` não dispara o pipeline do serviço | O pull request não deixou mudança líquida em `services/<svc>/` nem no workflow — por exemplo, um commit que insere e outro que remove a mesma linha | Conferir `git diff --stat origin/main dev -- services/<svc>` antes do merge |
| CI | O run aparece como `cancelled` | Novo push na mesma branch antes de o anterior terminar; fora da `main`, o run antigo é cancelado | Esperar o run terminar (`gh run watch <id>`) antes do próximo push |
| AWS | Pod em `CreateContainerConfigError` | Secret faltando ou com nome divergente | `kubectl get secrets -n togglemaster` e conferir `gitops/SECRETS-CONTRATO.md` |
| AWS | `pod is not running` ou `services "auth-service" not found` no port-forward | O ArgoCD ainda não sincronizou, ou os pods não ficaram prontos | Fim do passo 2.9: todos os pods em `READY 1/1` |
| AWS | PVC em `Pending` | StorageClass ausente ou com nome divergente | `kubectl get storageclass`; o nome tem que ser `gp3` nos dois lados |
| AWS | `password authentication failed` só no targeting | Senha do pod do banco divergiu da do serviço | Ambas vêm da mesma senha gerada; recriar os dois Secrets juntos |
| AWS | `no matches for kind "Application"` | Apply da camada k8s feito num comando só, em cluster novo | Passo 2.7: rodar a etapa A com `-target=helm_release.argocd` primeiro |
| AWS | ArgoCD em `Unknown`, com `authentication required` | Repositório privado sem credencial configurada | Seção 2.10 |
| AWS | `kubectl get nodes` responde `Unauthorized` | Usuário IAM diferente do que criou o cluster | `aws sts get-caller-identity` e trocar o perfil ativo |
| AWS | HPA com `targets: <unknown>` | Metrics Server ainda inicializando | Aguardar cerca de 2 minutos; é addon gerenciado e se resolve sozinho |
| AWS | `QueueDeletedRecently` | Fila SQS recriada em menos de 60 segundos | Esperar 1 minuto e repetir |
| AWS | `evaluation-service` em `CrashLoopBackOff` logo na partida, sem conectar no Redis | `REDIS_URL` do overlay diferente do endpoint criado, ou esquema da URL divergente da configuração de TLS | Passo 2.9; `redis://` com TLS desligado, `rediss://` com TLS ligado |
| AWS | Serviço responde `/health` com 200 e falha no primeiro INSERT | Schema nunca aplicado no RDS | Seção 3. Health verde não prova banco pronto |
| AWS | `/evaluate` responde 502 e o log do pod mostra 401 | O `SERVICE_API_KEY` do Secret não foi trocado pela chave real | Passo 5.2: conferir a saída `configured` antes do `rollout restart` |
| AWS | `terraform output` responde `Warning: No outputs found` | O estado da camada está vazio: ela ainda não foi aplicada | Não é erro. No pré-voo, significa base do zero (2.1) |
| AWS | `terraform output` falha logo no pré-voo | Diretório sem `.terraform/`, estado remoto no S3 | Rodar `terraform -chdir=<pasta> init` antes de qualquer `output` |
| Shell | `terraform plan` reclama de "Too many command line arguments" | PowerShell interpretando `-out=arquivo` | Usar o token `--%` antes dos parâmetros, ou rodar em Git Bash |
| Shell | Erro de parser com `&&`, ou `\` tratado como argumento | O PowerShell 5.1 não aceita `&&` e não usa `\` para continuar linha | Rodar o bloco no Git Bash, ou usar a versão PowerShell ao lado |
| Shell | Comando com `<` falha com erro de sintaxe | `<` não é redirecionamento no PowerShell | Rodar em Git Bash/WSL, ou usar `Get-Content ... \|` |
| Local | `/evaluate` retorna 502 e o log mostra 401 | `SERVICE_API_KEY` do `.env` não existe no banco atual | Criar outra chave, atualizar o `.env` e recriar o evaluation-service |
| Local | Nada funciona depois de `docker compose down -v` | Os bancos foram apagados, e com eles a chave | Refazer os passos 1.4 e 1.5 |
| Local | Container não sobe por porta ocupada | Alguma das portas 8000–8005, 5433, 5434 ou 6379 em uso | As portas **8001–8005** são ajustáveis no `.env`; **8000, 5433, 5434 e 6379** estão fixas no `docker-compose.yaml` e só mudam editando o arquivo, ou encerrando o programa que as ocupa |
| Local | `python3: command not found` no teste integrado | No Windows o Git Bash só conhece `python` | Rodar pelo WSL, ou disponibilizar `python3` no PATH (seção 1.8) |
| Local | `/evaluate` devolve HTTP 400 | Parâmetros com nome errado | São `flag_name` e `user_id`, não `flag` e `user` |

---

# 8. Custo por sessão

Valores da estimativa oficial do AWS Pricing Calculator para a região `us-east-2`,
convertidos de mês (730 horas) para hora.

| Item | US$/h | US$/mês |
|---|---:|---:|
| EKS — control plane, Kubernetes 1.34 em suporte padrão | 0,100 | 73,00 |
| EC2 — 2 × `c7i-flex.large`, com 20 GB de disco por nó | 0,174 | 126,99 |
| RDS PostgreSQL — 2 × `db.t3.micro`, Single-AZ, 20 GB gp3 | 0,042 | 30,88 |
| ElastiCache — 1 × Redis `cache.t3.micro` | 0,017 | 12,41 |
| VPC — 1 NAT Gateway, 1 IPv4 público e tráfego processado | 0,050 | 36,54 |
| EBS — 1 volume gp3 de 5 GB, para o banco em pod | 0,001 | 0,40 |
| Secrets Manager — 2 segredos | 0,001 | 0,81 |
| **Total com tudo de pé** | **0,385** | **281,03** |

> ℹ️ **Sobre a linha de VPC, que aparece em vários avisos deste guia.** O NAT Gateway
> em si cobra **US$ 0,045/h** (~US$ 33/mês). A linha da tabela vale US$ 0,050/h
> porque soma o **endereço IPv4 público** que fica preso ao NAT e o tráfego
> processado. Os dois números descrevem a mesma coisa em recortes diferentes: use
> 0,045 para raciocinar sobre o NAT isolado e 0,050 para fechar o total.

> ⚠️ **A versão do Kubernetes mexe nesse número.** Fora do suporte padrão, o control
> plane do EKS sai de US$ 0,10/h para **US$ 0,60/h** — seis vezes mais, sem nenhum
> ganho. A versão 1.34 foi escolhida por isso, e a permanência no suporte padrão vale
> ser reconferida antes de subir o ambiente.

### Quanto custa uma sessão de trabalho

Tempos medidos na sessão de 11/09, com as versões do estado no S3 e o CloudTrail como
fonte:

| Fase | Tempo | Observação |
|---|---|---|
| Pré-voo (seção 2.1) | 5 min | custo zero |
| Base só ligando o NAT (passo 2.3) | 2m24s | o relógio começa ao ligar o NAT |
| Base do zero (passo 2.3) | não medido — reserve 10 min | VPC, 5 ECR, SQS, DynamoDB e IAM |
| Republicar as imagens (passo 2.4) | 2 a 4 min | em paralelo com o cluster |
| Cluster (passo 2.5) | 15m42s | reserve de 20 a 30 min |
| Camada k8s (passo 2.7) | 4m44s | as duas etapas somadas |
| Schemas e seed (seções 3 e 5.1–5.3) | 15 min | **refazer a cada sessão** |
| Uso e verificação (seção 5) | variável | |
| Derrubar as três camadas (seção 6) | ~13 min | k8s ~1m30s, cluster ~8 min, base ~2 min |

Uma sessão de **2 horas** custa cerca de **US$ 0,77**; uma de **3 horas**, cerca de
**US$ 1,15**. Em 11/09, do NAT ligado ao fim do destroy, foram 3h17m.

### O que continua cobrando depois do destroy

Com a opção A da seção 6.3 — base mantida e NAT desligado —, a camada base custa
praticamente zero: VPC, subnets, ECR, SQS, DynamoDB e IAM não cobram parados. O DynamoDB
está em cobrança por requisição, e o ECR só cobra armazenamento de imagens, que é
centavos. Com a opção B — base destruída —, não sobra nada do projeto além do bucket de
estado, que custa frações de centavo.

**Com o NAT esquecido ligado, são US$ 0,045/h — entre US$ 33 e US$ 36 por mês,
somando o IPv4 público, com nada rodando.** É o único item da camada base que cobra
sozinho, e por isso a seção 6.3 existe.

---

## 📖 Documentos relacionados

| Você quer... | Leia |
|---|---|
| Entender o projeto, a esteira e as decisões | [`README.md`](../README.md) |
| Entender a divisão em três camadas do Terraform | [`terraform/README.md`](../terraform/README.md) |
| Saber quais Secrets existem e quais valores precisam coincidir | [`gitops/SECRETS-CONTRATO.md`](../gitops/SECRETS-CONTRATO.md) |
| Ver os diagramas de arquitetura | [`docs/ARQUITETURA.md`](ARQUITETURA.md) |
| Criar o bucket de estado do Terraform do zero | [`terraform/BOOTSTRAP-BACKEND-S3.md`](../terraform/BOOTSTRAP-BACKEND-S3.md) |
