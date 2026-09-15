# Plano da manhã de 15/09 — recriar a AWS e regravar o vídeo

Preparado na noite de 14/09/2026 e reescrito na manhã de 15/09 com todos os comandos. A
gravação de 11/09 saiu **sem áudio** (as amostras de áudio do arquivo são todas zero), e a
conta AWS foi destruída depois daquela sessão.

**Tudo o que você precisa digitar está aqui, na ordem.** Não é preciso abrir outro
documento. Se quiser entender um comando mais a fundo, o guia público
[`docs/OPERACAO.md`](../OPERACAO.md) explica cada um.

---

## Como usar este plano

- **Use só o Git Bash hoje.** Todos os comandos foram escritos para ele. Nada de PowerShell.
- **Cada bloco pode ser colado inteiro.** Quando um bloco tem um comando que demora ou fica
  travado, ele é o último do bloco.
- **Linhas que começam com `#` são explicação.** O Git Bash ignora essas linhas; pode colar
  junto.
- **✅ Esperado** diz o que precisa aparecer antes de seguir. Se aparecer outra coisa, vá
  para as [Contingências](#contingências).
- **🎥** marca o que é gravado.

### As janelas do Git Bash

Abra as janelas conforme o plano pedir. Em **toda janela nova**, rode primeiro:

```bash
# Entra na pasta do projeto. Rode isto em toda janela nova do Git Bash.
cd /c/Users/Gabriel/Documents/GitHub/tech-challenge-03
```

| Janela | Uso | Fica travada? |
|---|---|---|
| **1 — Terraform e cluster** | base, cluster, camada k8s, bancos, dados de teste e destroy | Durante os applies |
| **2 — Git e GitHub** | imagens, commits, pull request e acompanhamento dos pipelines | Durante o `gh run watch` |
| **3, 4 e 5 — Túneis** | auth (8001), flag (8002) e targeting (8003) | Sim, até o fim |
| **6 — Túnel do evaluation** | evaluation (8004) | Sim, até o fim |
| **7 — Túnel do ArgoCD** | interface do ArgoCD (8080) | Sim, até o fim |

---

## As cinco regras do dia

1. **Teste o áudio antes de cada bloco de gravação — e escute o resultado.** Em 11/09, o
   teste das 08:38 já estava mudo e ninguém percebeu.
2. **Base → imagens → cluster → k8s.** As imagens só publicam depois que a base existe, e a
   camada k8s só sobe depois que as imagens estão no ECR.
3. **Tudo no Git Bash, na pasta do projeto. E nunca `git add -A`:** há arquivos do
   relatório alterados que não entram em nenhum commit de hoje.
4. **Nada é destruído antes de:** exportar o vídeo, ouvir o arquivo exportado inteiro com
   fone, terminar o upload e abrir o link numa aba anônima.
5. **Nenhum merge na `main` que mexa em `services/` ou nos workflows fora da Cena 6.** Cada
   merge desses publica imagem e comita tag.

---

## O que já foi verificado

| Item | Situação |
|---|---|
| Provedor OIDC do GitHub | Já existe na conta, criado pelo projeto `rh-portfolio`. O Terraform **reaproveita** o provedor (PR #15), e o `terraform.tfvars` desta máquina está com `create_github_oidc_provider = false` |
| `plan` da base contra a conta real | `Plan: 35 to add, 0 to change, 0 to destroy`, conferido de novo na manhã de 15/09 |
| Variáveis do Terraform | As três camadas têm valor padrão para todas as variáveis: nenhum comando vai parar pedindo valor |
| Re-run das imagens | auth e evaluation publicam `v1.0.0-7ab0602`; targeting e analytics, `v1.0.0-ff441a1` — as mesmas tags do GitOps. O flag-service publica `v1.0.0-e6b144f`, e o robô comita essa tag nova na `main` |
| Cena de DevSecOps | Testada com o Trivy nas regras do CI: `PyYAML==5.3.1` **na primeira linha** do `requirements.txt` falha com `CVE-2020-14343 CRITICAL`, e `PyYAML==6.0.1` passa. **Na última linha, versões novas do Trivy não enxergam o pacote** — por isso o comando insere no topo |
| Scan das imagens | As imagens base `python:3.12-slim` e `alpine:3.20` passam nas regras do CI |
| ArgoCD | Repositório público: **não precisa de token**. Reconcilia a cada 30 s |
| Planos do Terraform | Arquivos `*.tfplan` são ignorados pelo Git: o plano salvo nunca vai parar num commit |

---

## Pré-voo — 30 minutos antes de começar

### Técnico

**Janela 1** — conta, provedor OIDC, configuração e ferramentas:

```bash
# Entra na pasta do projeto.
cd /c/Users/Gabriel/Documents/GitHub/tech-challenge-03
# Desliga a paginação da AWS CLI nesta janela, para nenhum comando parar esperando tecla.
export AWS_PAGER=""
# Conta da AWS em uso. ✅ Esperado: 891376952395
aws sts get-caller-identity --query Account --output text
# Provedor OIDC do GitHub na conta. ✅ Esperado: uma linha terminando em token.actions.githubusercontent.com
aws iam list-open-id-connect-providers --output text
# As duas chaves do tfvars. ✅ Esperado: enable_nat_gateway = true e create_github_oidc_provider = false
grep -E "^(enable_nat_gateway|create_github_oidc_provider)" terraform/terraform.tfvars
# Versão do Terraform. ✅ Esperado: 1.11 ou mais nova
terraform version
# Versão do kubectl (só confirma que está instalado).
kubectl version --client
# Login do GitHub CLI. ✅ Esperado: Logged in to github.com
gh auth status
```

**Janela 2** — deixar a `dev` igual à `main`:

```bash
# Entra na pasta do projeto.
cd /c/Users/Gabriel/Documents/GitHub/tech-challenge-03
# Desliga a paginação da AWS CLI nesta janela.
export AWS_PAGER=""
# Garante que você está na branch dev.
git switch dev
# Baixa as novidades do GitHub.
git fetch origin
# Traz a dev para o mesmo ponto da main. ✅ Esperado: "Already up to date." ou "Fast-forward"
git merge --ff-only origin/main
# Estado da branch. ✅ Esperado: "## dev". Arquivos alterados do relatório podem aparecer: não mexa neles.
git status -sb
# Mantém a dev do GitHub igual à local. ✅ Esperado: "Everything up-to-date" ou o envio dos commits
git push origin dev
```

**Janela 2** — proteger o plano C, a gravação muda de 11/09:

```bash
# Cria uma pasta de backup fora da pasta de gravações.
mkdir -p "/c/Users/Gabriel/Videos/Backup gravacao 11-09"
# Copia o vídeo de 11/09. Leva alguns segundos: o arquivo passa de 1 GB.
cp "/c/Users/Gabriel/Videos/Gravações de Tela/Gravação de Tela 2026-09-11 123247.mp4" "/c/Users/Gabriel/Videos/Backup gravacao 11-09/"
# ✅ Esperado: o arquivo .mp4 listado.
ls -la "/c/Users/Gabriel/Videos/Backup gravacao 11-09/"
```

**Navegador** — deixe abertos:

- a aba **Actions** do repositório: <https://github.com/fiap-devops-arqcloud-2026/tech-challenge-03/actions>;
- o **console da AWS** na região **Ohio (us-east-2)**.

Carregador ligado, internet estável e notificações silenciadas.

### Áudio — obrigatório, 2 minutos, repetir antes de cada bloco

1. **Astro A50 ligado, com a haste do microfone abaixada.** Haste levantada corta o som no
   próprio headset, e o Windows continua mostrando o microfone "em uso".
2. **Configurações → Sistema → Som → Entrada:** selecione *Microfone do Headset (Astro A50
   Voice)* e fale. A barra de volume precisa se mexer.
3. **Feche a Ferramenta de Captura por completo e abra de novo.** Em 11/09 ela ficou com o
   mesmo fluxo de microfone aberto por quase quatro horas — é o principal suspeito.
4. Feche outros apps que usam microfone: Câmera, Teams, Discord.
5. Na barra de gravação, confira que o **ícone do microfone está ligado**.
6. Grave **15 segundos** falando. Abra o arquivo em `Vídeos\Gravações de Tela` e **escute com
   fone**. Sem voz, não comece.
7. Grave em **blocos curtos**, uma ou duas cenas por arquivo, e ouça o começo de cada um.

> **Plano B de áudio:** gravar só a tela e narrar depois pelo **Clipchamp** ou pelo
> **Gravador de Som**, os dois já instalados.

---

## Cronograma

T+0 é o início do Passo 1. Anote a hora real: ______. Cada passo abaixo tem todos os
comandos.

| Quando | Passo | Janela | 🎥 Gravar |
|---|---|---|---|
| T-30 | Pré-voo e teste de áudio | 1 e 2 | — |
| **T+0** | [Passo 1 — Criar a base](#passo-1--criar-a-base-t0) | 1 | **Cena 2** |
| T+8 | [Passo 2 — Republicar as cinco imagens](#passo-2--republicar-as-cinco-imagens-t8) | 2 | — |
| T+9 | [Passo 3 — Criar o cluster](#passo-3--criar-o-cluster-t9) | 1 | Opcional: o começo |
| T+10 | [Enquanto o cluster sobe — Cenas 1 e 3a](#enquanto-o-cluster-sobe--cenas-1-e-3a-t10) | 2 e navegador | **Cenas 1 e 3a** |
| T+14 | [Passo 4 — Conferir as imagens e atualizar a dev](#passo-4--conferir-as-imagens-e-atualizar-a-dev-t14) | 2 | — |
| T+15 | [Passo 5 — Cena 3b: DevSecOps ao vivo](#passo-5--cena-3b-devsecops-ao-vivo-t15) | 2 | **Cena 3b** |
| **T+25** | [Passo 6 — Ligar o kubectl ao cluster](#passo-6--ligar-o-kubectl-ao-cluster-t25) | 1 | — |
| T+28 | [Passo 7 — Camada k8s](#passo-7--camada-k8s-argocd-secrets-e-storageclass-t28) | 1 | — |
| T+33 | [Passo 8 — Conferir o GitOps e esperar os pods](#passo-8--conferir-o-gitops-e-esperar-os-pods-t33) | 1 | — |
| **T+40** | [Passo 9 — Criar as tabelas dos bancos](#passo-9--criar-as-tabelas-dos-bancos-t40) | 1 | — |
| T+45 | [Passo 10 — Semear os dados](#passo-10--semear-os-dados-t45) | 1, 3, 4, 5 e 6 | — |
| T+55 | [Passo 11 — Cenas 4 e 5: AWS e ArgoCD](#passo-11--cenas-4-e-5-aws-e-argocd-t55) | 1 e 7 | **Cenas 4 e 5** |
| **T+60** | [Passo 12 — Cena 6: GitOps e ArgoCD ao vivo](#passo-12--cena-6-gitops-e-argocd-ao-vivo-t60) | 2 e 1 | **Cena 6** |
| T+70 | [Passo 13 — Cenas 7 e 8](#passo-13--cenas-7-e-8-t70) | 1 | Cenas 7 e 8, opcionais |
| T+80 | [Passo 14 — Exportar e publicar](#passo-14--exportar-e-publicar-t80) | — | — |
| Depois | [Passo 15 — Derrubar a AWS](#passo-15--derrubar-a-aws-só-depois-do-link-testado) | 1 | — |
| Fim | [Passo 16 — Entrega](#passo-16--entrega) | — | — |

**Folga:** o plano ocupa cerca de 2h20. Se um passo atrasar mais de 20 minutos, veja as
contingências.

---

## Passo a passo

### Passo 1 — Criar a base (T+0)

**Janela 1.** 🎥 **Cena 2 — grave o `plan` inteiro e o começo do `apply`.**

Na fala: "separamos a infraestrutura em três camadas para derrubar só o que cobra por hora;
hoje estamos subindo tudo do zero, inclusive a base". **Não diga que a base é permanente.**

**1A — planejar:**

```bash
# Prepara a camada base: baixa os providers e conecta o estado guardado no S3.
terraform -chdir=terraform init
# Calcula tudo o que será criado e salva o plano no arquivo base.tfplan.
terraform -chdir=terraform plan -out=base.tfplan
```

✅ Esperado no fim: `Plan: 35 to add, 0 to change, 0 to destroy.`
Se aparecer qualquer número diferente de zero em `to destroy`, **não siga**: veja as
contingências.

**1B — aplicar**, só depois de conferir o 1A:

```bash
# Cria exatamente o que o plano mostrou. Não pergunta "yes": o plano já foi conferido.
terraform -chdir=terraform apply base.tfplan
# Confirma que a role do CI existe, porque o Passo 2 depende dela.
terraform -chdir=terraform output github_actions_role_arn
```

✅ Esperado: `Apply complete! Resources: 35 added, 0 changed, 0 destroyed.` e depois
`"arn:aws:iam::891376952395:role/togglemaster-github-actions"`.

### Passo 2 — Republicar as cinco imagens (T+8)

**Janela 2.** Só depois do `Apply complete!` do Passo 1: antes disso o pipeline falha ao
entrar na AWS.

O ECR nasceu vazio. Este bloco pede ao GitHub para refazer o último pipeline de cada
serviço na `main`, **inteiro**: build, linter, SAST, SCA, imagem, push no ECR e GitOps.

```bash
# Repete os comandos abaixo para cada um dos cinco serviços.
for svc in auth-service evaluation-service flag-service targeting-service analytics-service; do
  # Número do último run disparado por push na main para este serviço.
  id=$(gh run list --workflow "$svc.yml" --branch main --event push --limit 1 --json databaseId --jq '.[0].databaseId')
  # Mostra qual run vai ser refeito.
  echo "$svc -> run $id"
  # Refaz o run completo, com todos os jobs.
  gh run rerun "$id"
done
```

✅ Esperado, nesta ordem, cada linha seguida de `Requested rerun`:
`auth-service -> run 34531915833`, `evaluation-service -> run 34531915493`,
`flag-service -> run 34667081759`, `targeting-service -> run 34586014564` e
`analytics-service -> run 34586014584`.

**Não espere terminar:** vá direto para o Passo 3. A conferência fica para o Passo 4.

### Passo 3 — Criar o cluster (T+9)

**Janela 1.**

**3A — planejar:**

```bash
# Prepara a camada do cluster.
terraform -chdir=terraform/cluster init
# Calcula o que será criado e salva o plano no arquivo cluster.tfplan.
terraform -chdir=terraform/cluster plan -out=cluster.tfplan
```

✅ Esperado no fim: `Plan: ... to add, 0 to change, 0 to destroy.`

**3B — aplicar:**

```bash
# Cria EKS, nós, 2 RDS, Redis e as permissões dos pods. Leva de 15 a 30 minutos: deixe esta janela trabalhando.
terraform -chdir=terraform/cluster apply cluster.tfplan
```

✅ Esperado, entre T+25 e T+35: `Apply complete!`. Enquanto isso, siga nas outras janelas.

### Enquanto o cluster sobe — Cenas 1 e 3a (T+10)

🎥 **Cena 1 — abertura.** Apresente os slides 1 a 6. **Janela 2:**

```bash
# Abre os slides da abertura no PowerPoint.
explorer.exe "$(cygpath -w docs/apresentacao/ToggleMaster_Fase3.pptx)"
```

🎥 **Cena 3a — a prova que já existe.** **Janela 2:**

```bash
# Abre o run de 11/09 em que o SCA barrou a PyYAML 5.3.1, com imagem e GitOps pulados.
gh run view 34610575185 --web
# Abre o run completo e verde na main de 11/09: seis jobs, incluindo imagem e GitOps.
gh run view 34606996327 --web
```

### Passo 4 — Conferir as imagens e atualizar a dev (T+14)

**Janela 2.**

**4A — estado dos cinco pipelines.** Repita este bloco até os cinco mostrarem
`completed success`:

```bash
# Para cada serviço, mostra o estado do run que foi refeito.
for svc in auth-service evaluation-service flag-service targeting-service analytics-service; do
  # Estado e resultado do último run de push na main deste serviço.
  gh run list --workflow "$svc.yml" --branch main --event push --limit 1 --json status,conclusion --jq ".[0] | \"$svc: \(.status) \(.conclusion)\""
done
```

✅ Esperado: as cinco linhas terminando em `completed success`. Enquanto alguma mostrar
`in_progress` ou `queued`, espere 1 minuto e rode de novo.

**4B — imagens no ECR:**

```bash
# Para cada repositório do ECR, lista as tags publicadas.
for r in auth-service evaluation-service flag-service targeting-service analytics-service; do
  # Mostra o nome do repositório e as tags dele.
  echo "$r: $(aws ecr list-images --region us-east-2 --repository-name "$r" --query 'imageIds[].imageTag' --output text)"
done
```

✅ Esperado: `auth-service` e `evaluation-service` com `v1.0.0-7ab0602`;
`targeting-service` e `analytics-service` com `v1.0.0-ff441a1`; `flag-service` com
`v1.0.0-e6b144f`.

**4C — trazer para a `dev` o commit que o robô fez na `main`:**

```bash
# Baixa as novidades do GitHub.
git fetch origin
# Últimos commits da main. ✅ Esperado no topo: chore(gitops): flag-service para v1.0.0-e6b144f [skip ci]
git --no-pager log origin/main --oneline -3
# Traz a dev para o mesmo ponto da main. ✅ Esperado: "Fast-forward"
git merge --ff-only origin/main
# Publica a dev atualizada.
git push origin dev
```

### Passo 5 — Cena 3b: DevSecOps ao vivo (T+15)

**Janela 2.** 🎥 Grave o terminal e a aba do GitHub lado a lado.

**5A — colocar a dependência vulnerável:**

```bash
# Insere a PyYAML 5.3.1, que tem CVE crítica, na PRIMEIRA linha do requirements.txt do flag-service.
sed -i '1i PyYAML==5.3.1' services/flag-service/requirements.txt
# Mostra o começo do arquivo. ✅ Esperado: PyYAML==5.3.1 na primeira linha.
head -3 services/flag-service/requirements.txt
# Prepara só este arquivo para o commit. O aviso "LF will be replaced by CRLF" é normal.
git add services/flag-service/requirements.txt
# Registra a mudança.
git commit -m "feat(flag-service): adiciona PyYAML"
# Envia para a dev. O pipeline do flag-service começa sozinho.
git push origin dev
```

**5B — acompanhar o pipeline falhar:**

```bash
# Guarda o identificador do commit que acabou de subir.
SHA=$(git rev-parse HEAD)
# Começa sem nenhum run encontrado.
RUN=""
# Espera o GitHub criar o run deste commit, olhando a cada 5 segundos.
until [ -n "$RUN" ]; do sleep 5; RUN=$(gh run list --workflow flag-service.yml --commit "$SHA" --json databaseId --jq '.[0].databaseId // empty'); done
# Abre o run no navegador, para a gravação.
gh run view "$RUN" --web
# Acompanha no terminal até o fim, cerca de 3 minutos.
gh run watch "$RUN"
```

✅ Esperado: `SCA (Trivy fs)` **vermelho**, e `Imagem Docker e push no ECR` e
`Atualizar tag no GitOps` **pulados**. Na fala: "vulnerabilidade crítica encontrada: o
pipeline para, e nada chega à produção".

Para mostrar no terminal a linha exata que barrou o pipeline:

```bash
# Filtra do log do job que falhou a linha da vulnerabilidade. ✅ Esperado: PyYAML | CVE-2020-14343 | CRITICAL
gh run view "$RUN" --log-failed | grep -E "PyYAML|CVE-2020-14343"
```

⚠️ **Não faça o próximo push antes de o run terminar.** Um push no meio cancela o run, e a
tela mostra `cancelled` em vez da falha.

**5C — corrigir:**

```bash
# Troca a versão vulnerável pela corrigida.
sed -i 's/PyYAML==5.3.1/PyYAML==6.0.1/' services/flag-service/requirements.txt
# Mostra o começo do arquivo. ✅ Esperado: PyYAML==6.0.1 na primeira linha.
head -3 services/flag-service/requirements.txt
# Prepara só este arquivo.
git add services/flag-service/requirements.txt
# Registra a correção.
git commit -m "fix(flag-service): atualiza PyYAML para 6.0.1 (CVE-2020-14343)"
# Envia para a dev. O pipeline roda de novo.
git push origin dev
```

**5D — acompanhar o pipeline passar:**

```bash
# Guarda o identificador do commit da correção.
SHA=$(git rev-parse HEAD)
# Começa sem nenhum run encontrado.
RUN=""
# Espera o GitHub criar o run deste commit, olhando a cada 5 segundos.
until [ -n "$RUN" ]; do sleep 5; RUN=$(gh run list --workflow flag-service.yml --commit "$SHA" --json databaseId --jq '.[0].databaseId // empty'); done
# Abre o run no navegador, para a gravação.
gh run view "$RUN" --web
# Acompanha no terminal até o fim, cerca de 3 minutos.
gh run watch "$RUN"
```

✅ Esperado: todos os jobs **verdes**, e imagem e GitOps **pulados**. Na fala: "na `dev` o
pipeline só verifica; quem publica é a `main` — é o que vamos ver na Cena 6".

> **Não remova a linha da PyYAML.** A troca de `5.3.1` por `6.0.1` deixa uma mudança real no
> `flag-service`, e é ela que faz a Cena 6 disparar o pipeline na `main`.

### Passo 6 — Ligar o kubectl ao cluster (T+25)

**Janela 1**, depois do `Apply complete!` do Passo 3.

```bash
# Grava o acesso ao cluster no arquivo de configuração do kubectl.
aws eks update-kubeconfig --region us-east-2 --name togglemaster
# Lista os nós do cluster. ✅ Esperado: 2 nós com STATUS Ready.
kubectl get nodes
```

### Passo 7 — Camada k8s: ArgoCD, Secrets e StorageClass (T+28)

**Janela 1.** Só depois do Passo 4B: as cinco imagens precisam estar no ECR.

São **duas etapas, nesta ordem**: a primeira instala o ArgoCD, e só depois dela o Terraform
consegue planejar a Application.

**7A — instalar o ArgoCD:**

```bash
# Prepara a camada k8s.
terraform -chdir=terraform/k8s init
# Planeja só a instalação do ArgoCD e salva em argocd.tfplan.
terraform -chdir=terraform/k8s plan -target=helm_release.argocd -out=argocd.tfplan
# Instala o ArgoCD.
terraform -chdir=terraform/k8s apply argocd.tfplan
```

✅ Esperado: `Apply complete!`. O aviso sobre `-target` é normal.

**7B — o resto da camada:**

```bash
# Planeja os Secrets, a StorageClass e a Application que aponta para o Git.
terraform -chdir=terraform/k8s plan -out=k8s.tfplan
# Aplica o plano.
terraform -chdir=terraform/k8s apply k8s.tfplan
```

✅ Esperado: `Apply complete!`.

### Passo 8 — Conferir o GitOps e esperar os pods (T+33)

**Janela 1.**

**8A — endereços gravados no GitOps:**

```bash
# Endereço do Redis que acabou de ser criado.
terraform -chdir=terraform/cluster output -raw redis_url; echo
# Endereço gravado no GitOps. ✅ Esperado: o MESMO endereço da linha acima.
grep REDIS_URL gitops/overlays/prod/patches/endpoints.yaml
# Roles dos pods que acabaram de ser criadas.
terraform -chdir=terraform/cluster output irsa_role_arns
# Roles gravadas no GitOps. ✅ Esperado: os mesmos dois ARNs.
grep role-arn gitops/overlays/prod/patches/irsa.yaml
```

Se o endereço do Redis for diferente, veja as contingências.

**8B — esperar a sincronização e os pods:**

```bash
# Estado da Application no ArgoCD. ✅ Esperado, em 1 a 2 minutos: Synced / Healthy
kubectl get application togglemaster -n argocd -o jsonpath='{.status.sync.status} / {.status.health.status}'; echo
# Acompanha os pods ao vivo. Aperte Ctrl+C quando TODOS estiverem Running e 1/1.
kubectl get pods -n togglemaster -w
```

✅ Esperado: pelo menos 6 pods — os cinco serviços e o `postgres-targeting-0` — com
`READY 1/1` e `STATUS Running`. Se a primeira linha vier vazia, espere 30 segundos e rode de
novo. Pod em `ImagePullBackOff` por mais de 2 minutos: veja as contingências.

### Passo 9 — Criar as tabelas dos bancos (T+40)

**Janela 1.** O Terraform cria os bancos vazios; as tabelas do auth e do flag nascem aqui. O
banco do targeting cria as próprias tabelas.

**9A — criar:**

```bash
# Lê do Secret a URL de conexão do banco do auth, sem mostrar a senha.
AUTH_DB=$(kubectl get secret auth-service-secret -n togglemaster -o jsonpath='{.data.DATABASE_URL}' | base64 -d)
# Lê do Secret a URL de conexão do banco do flag.
FLAG_DB=$(kubectl get secret flag-service-secret -n togglemaster -o jsonpath='{.data.DATABASE_URL}' | base64 -d)
# Sobe um pod temporário com psql, que executa o init.sql do auth e se apaga.
kubectl run psql-auth --rm -i --restart=Never -n togglemaster --image=postgres:16-alpine -- psql "$AUTH_DB" < services/auth-service/db/init.sql
# Mesmo processo para o banco do flag.
kubectl run psql-flag --rm -i --restart=Never -n togglemaster --image=postgres:16-alpine -- psql "$FLAG_DB" < services/flag-service/db/init.sql
```

✅ Esperado: linhas `CREATE ...`, nenhuma linha `ERROR`, e `pod "psql-auth" deleted` e
`pod "psql-flag" deleted`.

**9B — conferir:**

```bash
# Lista as tabelas do banco do auth. ✅ Esperado: api_keys
kubectl run psql-check-auth --rm -i --restart=Never -n togglemaster --image=postgres:16-alpine -- psql "$AUTH_DB" -c "\dt" < /dev/null
# Lista as tabelas do banco do flag. ✅ Esperado: flags
kubectl run psql-check-flag --rm -i --restart=Never -n togglemaster --image=postgres:16-alpine -- psql "$FLAG_DB" -c "\dt" < /dev/null
```

### Passo 10 — Semear os dados (T+45)

**10A — três túneis.** Abra **três janelas novas** do Git Bash e rode um comando em cada.
Elas ficam travadas: não feche.

**Janela 3:**

```bash
# Túnel da porta 8001 da sua máquina até o auth-service no cluster.
kubectl port-forward svc/auth-service -n togglemaster 8001:8001
```

**Janela 4:**

```bash
# Túnel da porta 8002 até o flag-service.
kubectl port-forward svc/flag-service -n togglemaster 8002:8002
```

**Janela 5:**

```bash
# Túnel da porta 8003 até o targeting-service.
kubectl port-forward svc/targeting-service -n togglemaster 8003:8003
```

✅ Esperado em cada uma: `Forwarding from 127.0.0.1:800X -> 800X`.

⚠️ Rode os blocos **10B, 10C e 10D na Janela 1**: a variável `CHAVE` só existe nela.

**10B — criar a chave de API:**

```bash
# Lê do Secret a chave administrativa do auth-service.
MASTER=$(kubectl get secret auth-service-secret -n togglemaster -o jsonpath='{.data.MASTER_KEY}' | base64 -d)
# Cria uma chave de API e guarda só o valor dela na variável CHAVE.
CHAVE=$(curl -s -X POST http://localhost:8001/admin/keys -H "Content-Type: application/json" -H "Authorization: Bearer $MASTER" -d '{"name":"demo-fase3"}' | sed -E 's/.*"key":"([^"]+)".*/\1/')
# Mostra só o começo da chave. ✅ Esperado: tm_key_ seguido de letras e números.
echo "${CHAVE:0:12}..."
```

**10C — entregar a chave ao evaluation-service:**

```bash
# Troca a chave provisória do evaluation-service pela chave real. ✅ Esperado: secret/evaluation-service-secret configured
kubectl create secret generic evaluation-service-secret -n togglemaster --from-literal=SERVICE_API_KEY="$CHAVE" --dry-run=client -o yaml | kubectl apply -f -
# Reinicia o evaluation-service para ele ler a chave nova.
kubectl rollout restart deployment/evaluation-service -n togglemaster
# Espera o pod novo ficar pronto. ✅ Esperado: deployment "evaluation-service" successfully rolled out
kubectl rollout status deployment/evaluation-service -n togglemaster
```

**10D — criar a flag e a regra:**

```bash
# Cria a flag novo-painel no flag-service. ✅ Esperado: um JSON com "novo-painel", sem erro.
curl -s -X POST http://localhost:8002/flags -H "Content-Type: application/json" -H "Authorization: Bearer $CHAVE" -d '{"name":"novo-painel","description":"Painel novo para demonstracao","is_enabled":true}'; echo
# Cria a regra de 100% no targeting-service. ✅ Esperado: um JSON com "novo-painel", sem erro.
curl -s -X POST http://localhost:8003/rules -H "Content-Type: application/json" -H "Authorization: Bearer $CHAVE" -d '{"flag_name":"novo-painel","rules":{"type":"PERCENTAGE","value":100},"is_enabled":true}'; echo
```

**10E — túnel do evaluation.** Abra a **Janela 6** só agora, depois do reinício do 10C:

```bash
# Túnel da porta 8004 até o evaluation-service.
kubectl port-forward svc/evaluation-service -n togglemaster 8004:8004
```

**10F — teste rápido, na Janela 1:**

```bash
# Avalia a flag. ✅ Esperado: um JSON com "result" igual a true
curl -s "http://localhost:8004/evaluate?flag_name=novo-painel&user_id=user-123"; echo
```

### Passo 11 — Cenas 4 e 5: AWS e ArgoCD (T+55)

🎥 **Cena 4 — o resultado na AWS.** **Janela 1:**

```bash
# Cluster EKS criado por código. ✅ Esperado: status ACTIVE
aws eks describe-cluster --name togglemaster --region us-east-2 --query "cluster.{nome:name,versao:version,status:status}"
# Os dois bancos RDS. ✅ Esperado: 2 instâncias com status available
aws rds describe-db-instances --region us-east-2 --query "DBInstances[].{banco:DBInstanceIdentifier,status:DBInstanceStatus}"
# Estado do Terraform guardado no S3, nada local. ✅ Esperado: base.tfstate, cluster.tfstate e k8s.tfstate
aws s3 ls s3://togglemaster-tfstate-891376952395-us-east-2-an/prod/
```

No console da AWS, na região Ohio, mostre: **VPC**, **EKS** (cluster `togglemaster`),
**RDS** (2 bancos), **ElastiCache**, **SQS**, **DynamoDB** (`ToggleMasterAnalytics`) e
**ECR** (5 repositórios).

🎥 **Cena 5 — o ArgoCD com os 5 serviços.**

**Janela 7:**

```bash
# Túnel da porta 8080 até a interface do ArgoCD. Esta janela fica travada.
kubectl port-forward svc/argocd-server -n argocd 8080:80
```

**Janela 1** — rode **antes de gravar**, para a senha não aparecer no vídeo:

```bash
# Mostra a senha do usuário admin do ArgoCD.
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo
```

Abra <http://localhost:8080> e entre com o usuário `admin` e essa senha. Mostre a Application
`togglemaster` em **Synced** e **Healthy** e a árvore com os cinco Deployments.

### Passo 12 — Cena 6: GitOps e ArgoCD ao vivo (T+60)

🎥 Divida a tela: ArgoCD de um lado, GitHub e terminal do outro. **Nunca corte o intervalo
entre o commit do robô e o `Synced`** — é a prova de que ninguém mandou sincronizar.

**12A — conferência antes de gravar, na Janela 2:**

```bash
# Baixa as novidades do GitHub.
git fetch origin
# Diferença do flag-service entre a main e a dev. ✅ Esperado: services/flag-service/requirements.txt | 1 +
git --no-pager diff --stat origin/main dev -- services/flag-service
```

Se não listar nenhum arquivo, o merge não dispara o pipeline: veja as contingências.

**12B — pull request e merge, na Janela 2:**

```bash
# Abre o pull request da dev para a main.
gh pr create --base main --head dev --title "fix(flag-service): atualiza PyYAML" --body "Correcao de seguranca demonstrada no pipeline DevSecOps."
# Faz o merge. Nunca acrescente --delete-branch: isso apagaria a dev.
gh pr merge --merge
```

✅ Esperado: o link do pull request e depois `Merged pull request`.

**12C — acompanhar o pipeline da `main`, na Janela 2:**

```bash
# Baixa o commit de merge.
git fetch origin
# Guarda o identificador do commit de merge.
MERGE=$(git rev-parse origin/main)
# Mostra a tag que o pipeline vai gerar.
echo "Tag esperada: v1.0.0-${MERGE:0:7}"
# Começa sem nenhum run encontrado.
RUN=""
# Espera o GitHub criar o run do flag-service para o merge, olhando a cada 5 segundos.
until [ -n "$RUN" ]; do sleep 5; RUN=$(gh run list --workflow flag-service.yml --commit "$MERGE" --json databaseId --jq '.[0].databaseId // empty'); done
# Abre o run no navegador.
gh run view "$RUN" --web
# Acompanha até o fim, cerca de 5 minutos.
gh run watch "$RUN"
```

✅ Esperado: os **seis jobs verdes**, agora **incluindo** `Imagem Docker e push no ECR` e
`Atualizar tag no GitOps`.

**12D — o commit do robô, na Janela 2:**

```bash
# Baixa o commit que o robô acabou de fazer.
git fetch origin
# Últimos commits da main. ✅ Esperado no topo: chore(gitops): flag-service para v1.0.0-<hash> [skip ci]
git --no-pager log origin/main --oneline -3
# Mostra a troca da tag no arquivo do GitOps.
git --no-pager show origin/main -- gitops/overlays/prod/kustomization.yaml
```

No ArgoCD, **sem clicar em nada**: em até 30 segundos o card sai de `Synced`, passa por
`OutOfSync` e `Progressing`, e volta a `Synced` e `Healthy`.

**12E — a versão nova no cluster, na Janela 1:**

```bash
# Imagem usada agora pelo flag-service. ✅ Esperado: termina com a tag mostrada no 12C
kubectl get deploy flag-service -n togglemaster -o jsonpath='{.spec.template.spec.containers[0].image}'; echo
# Espera o pod novo ficar pronto. ✅ Esperado: successfully rolled out
kubectl rollout status deployment/flag-service -n togglemaster
# Estado final da Application. ✅ Esperado: Synced / Healthy
kubectl get application togglemaster -n argocd -o jsonpath='{.status.sync.status} / {.status.health.status}'; echo
```

Se a primeira linha ainda mostrar a tag antiga, espere 30 segundos e rode o bloco de novo.

**12F — depois de gravar, atualizar a `dev`, na Janela 2:**

```bash
# Baixa as novidades do GitHub.
git fetch origin
# Traz a dev para o ponto da main. ✅ Esperado: "Fast-forward"
git merge --ff-only origin/main
# Publica a dev.
git push origin dev
```

> ℹ️ O túnel da Janela 4 (flag, 8002) cai quando o pod do flag-service é trocado. Ele não faz
> falta nas próximas cenas.

### Passo 13 — Cenas 7 e 8 (T+70)

Opcionais: são as primeiras a sair se o vídeo passar de 20 minutos.

🎥 **Cena 7 — prova funcional.** **Janela 1:**

```bash
# Avalia a flag passando pelo evaluation-service. ✅ Esperado: "result" igual a true
curl -s "http://localhost:8004/evaluate?flag_name=novo-painel&user_id=user-123"; echo
# Conta os eventos que o analytics gravou no DynamoDB. ✅ Esperado: "Count" maior que 0
aws dynamodb scan --table-name ToggleMasterAnalytics --region us-east-2 --select COUNT
# Autoscalers lendo métricas. ✅ Esperado: 2 HPAs com percentual na coluna TARGETS
kubectl get hpa -n togglemaster
```

🎥 **Cena 8 — fechamento:** os desafios da fase e o custo. Sem comandos.

### Passo 14 — Exportar e publicar (T+80)

- [ ] Parar a gravação.
- [ ] Exportar o vídeo, com as cenas na ordem da tabela do roteiro.
- [ ] **Ouvir o arquivo exportado inteiro, com fone.**
- [ ] Fazer o upload no YouTube como **Não listado**: vídeo privado o avaliador não abre.
- [ ] Abrir o link numa **aba anônima** e dar play.

Só depois disso, o Passo 15.

### Passo 15 — Derrubar a AWS (só depois do link testado)

**Antes:** aperte `Ctrl+C` nas Janelas 3 a 7 para fechar os túneis. Tudo abaixo roda na
**Janela 1**.

**15A — camada k8s, cerca de 1m30s:**

```bash
# Planeja a destruição da camada k8s. ✅ Esperado: 0 to add, 0 to change e um número em to destroy
terraform -chdir=terraform/k8s plan -destroy -out=destroy-k8s.tfplan
# Executa a destruição planejada.
terraform -chdir=terraform/k8s apply destroy-k8s.tfplan
```

**15B — cluster, cerca de 8 minutos:**

```bash
# Planeja a destruição do cluster, dos bancos e do Redis.
terraform -chdir=terraform/cluster plan -destroy -out=destroy-cluster.tfplan
# Executa a destruição planejada.
terraform -chdir=terraform/cluster apply destroy-cluster.tfplan
```

**15C — planejar a destruição da base e conferir o provedor OIDC:**

```bash
# Planeja a destruição da base.
terraform -chdir=terraform plan -destroy -out=destroy-base.tfplan
# Procura o provedor OIDC do outro projeto na lista de destruição. ✅ Esperado: NENHUMA linha
terraform -chdir=terraform show -no-color destroy-base.tfplan | grep "openid_connect_provider.*will be destroyed"
```

Se aparecer alguma linha, **pare**: o `terraform.tfvars` está com
`create_github_oidc_provider = true`, e a destruição apagaria o provedor do `rh-portfolio`.

**15D — destruir a base, cerca de 2 minutos:**

```bash
# Executa a destruição planejada da base: VPC, NAT, ECR com as imagens, SQS, DynamoDB e IAM.
terraform -chdir=terraform apply destroy-base.tfplan
```

**15E — conferir que não sobrou nada caro:**

```bash
# Clusters EKS. ✅ Esperado: "clusters": []
aws eks list-clusters --region us-east-2
# Bancos RDS. ✅ Esperado: []
aws rds describe-db-instances --region us-east-2 --query "DBInstances[].DBInstanceIdentifier"
# Redis. ✅ Esperado: []
aws elasticache describe-replication-groups --region us-east-2 --query "ReplicationGroups[].ReplicationGroupId"
# NAT Gateways ligados. ✅ Esperado: []
aws ec2 describe-nat-gateways --region us-east-2 --query "NatGateways[?State=='available'].NatGatewayId"
# Endereços IPv4 públicos. ✅ Esperado: []
aws ec2 describe-addresses --region us-east-2 --query "Addresses[].PublicIp"
# Repositórios de imagem. ✅ Esperado: "repositories": []
aws ecr describe-repositories --region us-east-2
# O provedor OIDC do outro projeto continua lá. ✅ Esperado: a linha com token.actions.githubusercontent.com
aws iam list-open-id-connect-providers --output text
```

Com a base destruída, vale a regra 5 com mais força: um merge que mexa em `services/` ou nos
workflows fica vermelho no job de imagem, porque a role do CI não existe mais.

### Passo 16 — Entrega

- [ ] Link do vídeo na capa do `README.md` e na seção 2 do `docs/RELATORIO_DE_ENTREGA.md`.
- [ ] PDF do relatório regerado e conferido.
- [ ] Todas as conferências do 15E vazias.
- [ ] Envio na plataforma da FIAP.

> ⚠️ **Pendência que antecede o PDF:** outro agente deixou alterações **não commitadas** no
> `README.md`, no relatório e nos geradores de PDF. Hoje o README aponta para um PDF dentro de
> `output/`, pasta que o Git ignora, então o link fica quebrado no GitHub. O gerador escolhido
> por ele depende do pacote `reportlab`, que não está instalado nesta máquina. Resolva isso
> antes de regerar o PDF.

---

## Roteiro de cenas — até 20 minutos

O enunciado exige no vídeo: **IaC** (`plan` e `apply`, ou o resultado na AWS),
**DevSecOps** (pipeline falhando no passo de segurança e depois passando), **GitOps** (o
pipeline atualizando a tag), **ArgoCD** (detectando e sincronizando a nova versão sozinho) e
a **interface do ArgoCD com os 5 microsserviços**. Nomes, links e custo vão no relatório,
não no vídeo.

As cenas são gravadas fora de ordem, conforme o ambiente fica pronto. **Na edição, monte na
ordem desta tabela.**

| # | Cena | Duração | Cobre | Gravada em | Pode cortar? |
|---|---|---|---|---|---|
| 1 | Abertura com os slides: o grupo, o problema, "se não está no código, não existe" | 1:00 | contexto | Enquanto o cluster sobe | Encurtar |
| 2 | IaC: `plan` e `apply` da base | 3:00 | **IaC** | Passo 1 | Não |
| 3 | DevSecOps: a prova de 11/09 (3a) e a falha e a correção ao vivo (3b) | 4:00 | **DevSecOps** | Enquanto o cluster sobe e Passo 5 | Não |
| 4 | Resultado na AWS: VPC, EKS e RDS | 1:30 | IaC — resultado | Passo 11 | Encurtar |
| 5 | ArgoCD com a Application e os 5 serviços | 1:30 | **Interface do ArgoCD** | Passo 11 | Não |
| 6 | Merge → pipeline → commit do robô → `Synced` → versão nova | 4:00 | **GitOps + ArgoCD** | Passo 12 | **Nunca** |
| 7 | Prova funcional: avaliação e evento no DynamoDB | 2:00 | não exigida | Passo 13 | Cortar primeiro |
| 8 | Fechamento: desafios e custo | 1:30 | não exigida | Passo 13 | Cortar |

Total: cerca de 18:30.

---

## Contingências

#### Teste de áudio mudo

Não grave. Abaixe a haste do A50, confira o dispositivo de entrada *Astro A50 Voice*, feche e
reabra a Ferramenta de Captura, grave 15 segundos e escute. Se continuar mudo, grave só a
tela e narre depois no Clipchamp.

#### O `plan` da base mostra algo em `to destroy`

Não aplique. Confira a conta com
`aws sts get-caller-identity --query Account --output text` (precisa ser `891376952395`) e o
`terraform.tfvars`. Se estiver tudo certo e o `destroy` continuar aparecendo, não siga: use o
plano C.

#### O apply da base para com `EntityAlreadyExists` no provedor OIDC

```bash
# Muda o tfvars para reaproveitar o provedor que já existe na conta.
sed -i 's/^create_github_oidc_provider = true/create_github_oidc_provider = false/' terraform/terraform.tfvars
# Confere a troca. ✅ Esperado: create_github_oidc_provider = false
grep "^create_github_oidc_provider" terraform/terraform.tfvars
```

Depois repita o Passo 1, blocos 1A e 1B.

#### O `plan` da base falha no `data.aws_iam_openid_connect_provider`

O provedor do outro projeto não existe mais, então a base precisa criar o próprio:

```bash
# Muda o tfvars para a base criar o provedor OIDC.
sed -i 's/^create_github_oidc_provider = false/create_github_oidc_provider = true/' terraform/terraform.tfvars
# Confere a troca. ✅ Esperado: create_github_oidc_provider = true
grep "^create_github_oidc_provider" terraform/terraform.tfvars
```

Depois repita o Passo 1. O `plan` passa a mostrar `36 to add`. Nesse caso o provedor é do
ToggleMaster, e a linha que o 15C procura **vai** aparecer — é o esperado.

#### Algum run do Passo 2 falhou em `Could not assume role with OIDC`

A base ainda não tinha terminado. Refaça só os que falharam, na Janela 2:

```bash
# Repete para cada um dos cinco serviços.
for svc in auth-service evaluation-service flag-service targeting-service analytics-service; do
  # Lê o número e o resultado do último run de push na main deste serviço.
  read -r id conclusao <<< "$(gh run list --workflow "$svc.yml" --branch main --event push --limit 1 --json databaseId,conclusion --jq '.[0] | "\(.databaseId) \(.conclusion)"')"
  # Refaz apenas os runs que terminaram com falha.
  if [ "$conclusao" = "failure" ]; then echo "$svc -> refazendo run $id"; gh run rerun "$id"; fi
done
```

Depois volte ao Passo 4A.

#### Um scan barrou por CVE crítica nova, sem ninguém ter mexido no código

O re-run não resolve, porque ele usa o `.trivyignore` do commit antigo. É preciso registrar a
exceção e publicar por um merge. **Faça isso antes da Cena 3b**: se ela já estiver na `dev`,
este merge leva a PyYAML junto, e a Cena 6 perde o gatilho.

Na Janela 2, troque `CVE-AAAA-NNNNN` pelo código que aparece no log do job vermelho:

```bash
# Código da CVE que apareceu no log.
CVE="CVE-AAAA-NNNNN"
# Registra a exceção no .trivyignore, com data e motivo numa linha de comentário acima.
printf '\n# 2026-09-15: CRITICAL sem correcao publicada; excecao temporaria. Revisar em 2026-10-15.\n%s\n' "$CVE" >> .trivyignore
# Acrescenta um comentário no fim do workflow Go, só para disparar os pipelines do auth e do evaluation.
echo "# republicacao das imagens em 2026-09-15" >> .github/workflows/_ci-go.yml
# Acrescenta um comentário no fim do workflow Python, para disparar flag, targeting e analytics.
echo "# republicacao das imagens em 2026-09-15" >> .github/workflows/_ci-python.yml
# Prepara só os três arquivos.
git add .trivyignore .github/workflows/_ci-go.yml .github/workflows/_ci-python.yml
# Registra a mudança.
git commit -m "ci: excecao temporaria para $CVE e republicacao das imagens"
# Envia para a dev.
git push origin dev
```

```bash
# Abre o pull request da dev para a main.
gh pr create --base main --head dev --title "ci: excecao temporaria para $CVE" --body "CVE critica sem correcao publicada; republicacao das imagens no ECR recriado."
# Faz o merge: a main publica as cinco imagens com tags novas.
gh pr merge --merge
```

Depois volte ao Passo 4. As tags do 4B passam a ser `v1.0.0-` seguidas do hash do merge, e o
robô faz cinco commits na `main`.

#### A fila do Actions está parada, com runs em `queued` por mais de 5 minutos

```bash
# Cancela os runs da dev que ainda não terminaram. Eles não publicam nada.
gh run list --branch dev --json databaseId,status --jq '.[] | select(.status != "completed") | .databaseId' | xargs -r -n1 gh run cancel
```

Atenção: isso também cancela um run da Cena 3b que esteja em andamento.

#### O cluster não chegou ao `Apply complete!`

Leia o erro na Janela 1. Se foi uma falha passageira, planeje e aplique de novo — o Terraform
continua de onde parou:

```bash
# Recalcula o plano a partir do que já foi criado.
terraform -chdir=terraform/cluster plan -out=cluster.tfplan
# Aplica o que falta.
terraform -chdir=terraform/cluster apply cluster.tfplan
```

Se até T+45 não houver correção clara, use o plano C.

#### Pod em `ImagePullBackOff` ou `ErrImagePull` com as imagens já no ECR

```bash
# Apaga os pods travados. O Kubernetes recria na hora e baixa a imagem de novo.
kubectl get pods -n togglemaster --no-headers | grep -E "ImagePullBackOff|ErrImagePull" | awk '{print $1}' | xargs -r kubectl delete pod -n togglemaster
# Acompanha os pods. Aperte Ctrl+C quando todos estiverem 1/1.
kubectl get pods -n togglemaster -w
```

#### O `REDIS_URL` do Passo 8A é diferente

A correção sai de uma branch temporária a partir da `main`, para não levar a PyYAML da `dev`
antes da Cena 6. Na Janela 2:

```bash
# Cria a branch temporária a partir da main.
git switch -c hotfix-redis origin/main
# Lê o endereço novo do Redis.
REDIS=$(terraform -chdir=terraform/cluster output -raw redis_url)
# Troca o endereço antigo pelo novo no GitOps.
sed -i "s|redis://togglemaster-redis.*:6379|${REDIS}|" gitops/overlays/prod/patches/endpoints.yaml
# Confere a troca. ✅ Esperado: o endereço novo
grep REDIS_URL gitops/overlays/prod/patches/endpoints.yaml
# Prepara só este arquivo.
git add gitops/overlays/prod/patches/endpoints.yaml
# Registra a mudança.
git commit -m "chore(gitops): endpoint do Redis da sessao"
# Envia a branch temporária.
git push origin hotfix-redis
```

```bash
# Abre o pull request da branch temporária para a main.
gh pr create --base main --head hotfix-redis --title "chore(gitops): endpoint do Redis da sessao" --body "Valor gerado pelo apply desta sessao."
# Faz o merge. O ArgoCD aplica sozinho em até 30 segundos.
gh pr merge hotfix-redis --merge
# Volta para a dev.
git switch dev
```

#### O `/evaluate` responde erro 502

A chave do evaluation-service não confere com a do banco. Repita os blocos 10B e 10C na Janela
1 e depois reabra o túnel da Janela 6 (10E).

#### Um túnel caiu, com `lost connection to pod` ou `error forwarding port`

Na mesma janela, aperte a seta para cima e Enter: o `kubectl port-forward` roda de novo.

#### O run da Cena 3b aparece como `cancelled`

Houve um push no meio. Na Janela 2, onde a variável `RUN` existe:

```bash
# Refaz o run cancelado.
gh run rerun "$RUN"
# Acompanha até o fim.
gh run watch "$RUN"
```

#### O `git merge --ff-only` responde `Not possible to fast-forward`

A `dev` tem um commit que a `main` não tem, e o robô comitou na `main` nesse meio-tempo:

```bash
# Junta a main na dev com um commit de merge, sem abrir editor.
git pull --no-rebase --no-edit origin main
# Publica a dev.
git push origin dev
```

#### O 12A não lista nenhum arquivo

A mudança da PyYAML não está na `dev`, ou já foi para a `main`. Crie uma mudança real no
flag-service:

```bash
# Acrescenta um comentário na primeira linha do requirements.txt do flag-service.
sed -i '1i # dependencias do flag-service' services/flag-service/requirements.txt
# Prepara só este arquivo.
git add services/flag-service/requirements.txt
# Registra a mudança.
git commit -m "chore(flag-service): documenta as dependencias"
# Envia para a dev.
git push origin dev
```

Depois repita o 12A.

#### Plano C — o ambiente não subiu até cerca de T+90

Use a gravação muda de 11/09, com 17min58s e o cluster ativo. Narre por cima no Clipchamp e
diga no vídeo que as cenas do cluster são de 11/09.

```bash
# Abre a pasta do backup no Explorer.
explorer.exe "C:\\Users\\Gabriel\\Videos\\Backup gravacao 11-09"
```
