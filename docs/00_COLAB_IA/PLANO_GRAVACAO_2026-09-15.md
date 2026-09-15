# Plano da manhã de 15/09 — recriar a AWS e regravar o vídeo

Preparado na noite de 14/09/2026. A gravação de 11/09 saiu **sem áudio**: as amostras
de áudio do arquivo são todas zero, então não há volume para aumentar. A conta AWS foi
destruída por completo depois daquela sessão.

Os **comandos** estão em [`docs/OPERACAO.md`](../OPERACAO.md), que é a fonte única. Este
plano diz a **ordem**, o **horário**, **o que gravar em cada momento** e **o que fazer se
algo travar**.

---

## As cinco regras do dia

1. **Teste o áudio antes de cada bloco de gravação — e escute o resultado.** Em 11/09,
   o teste das 08:38 já estava mudo e ninguém percebeu.
2. **Base → imagens → cluster → k8s.** As imagens só publicam depois que a base existe,
   e a camada k8s só sobe depois que as imagens estão no ECR.
3. **Blocos com `&&` ou `\` no fim da linha vão no Git Bash.** O PowerShell 5.1 quebra
   nesses dois.
4. **Nada é destruído antes de:** exportar o vídeo, ouvir o arquivo exportado inteiro
   com fone, terminar o upload e abrir o link numa aba anônima.
5. **Nenhum merge na `main` que mexa em `services/` ou nos workflows fora da cena
   combinada.** Cada merge desses publica imagem e comita tag.

---

## O que já foi resolvido na noite de 14/09

| Item | Situação |
|---|---|
| Provedor OIDC do GitHub | Já existe na conta, criado por outro projeto (`rh-portfolio`). O Terraform agora **reaproveita** o provedor em vez de tentar criar outro (PR #15). O `terraform.tfvars` desta máquina está com `create_github_oidc_provider = false` |
| `plan` da base contra a conta real | `Plan: 35 to add, 0 to change, 0 to destroy`, lendo o provedor existente |
| Scan de segurança de amanhã | Com as mesmas regras do CI, as imagens base `python:3.12-slim` e `alpine:3.20` e as dependências dos 5 serviços **passam** |
| Colisões de nome e cotas na AWS | Nenhuma encontrada. As roles e a VPC antigas são da Fase 2 e têm nomes diferentes; há 3 de 5 VPCs e nenhum IPv4 público em uso |
| ArgoCD | Repositório público: **não precisa de token**. Reconcilia a cada 30 s |
| Guia de operação | Reescrito para subida do zero, com o passo novo de republicar imagens (2.4) |

---

## Pré-voo — 30 minutos antes de começar

### Técnico

- [ ] Carregador ligado, internet estável, notificações silenciadas.
- [ ] `aws sts get-caller-identity` mostra a conta `891376952395`.
- [ ] `aws iam list-open-id-connect-providers` lista `token.actions.githubusercontent.com`.
      **Se não listar**, troque para `create_github_oidc_provider = true` no
      `terraform/terraform.tfvars`.
- [ ] `terraform/terraform.tfvars` com `enable_nat_gateway = true` e
      `create_github_oidc_provider = false`.
- [ ] `gh auth status` logado.
- [ ] Na raiz do repositório, no Git Bash: `git switch dev && git fetch origin && git merge --ff-only origin/main`.
- [ ] Janelas abertas: **um Git Bash principal**, um PowerShell, espaço para quatro
      janelas de port-forward. No navegador: aba **Actions** do repositório, console da
      AWS em `us-east-2`.

### Áudio — obrigatório, 2 minutos, repetir antes de cada bloco

1. **Astro A50 ligado, com a haste do microfone abaixada.** Haste levantada corta o som
   no próprio headset, e o Windows continua mostrando o microfone "em uso".
2. **Configurações → Sistema → Som → Entrada:** selecione *Microfone do Headset (Astro A50
   Voice)* e fale. A barra de volume precisa se mexer.
3. **Feche a Ferramenta de Captura por completo e abra de novo.** Em 11/09 ela ficou com
   o mesmo fluxo de microfone aberto por quase quatro horas — é o principal suspeito.
4. Feche outros apps que usam microfone: Câmera, Teams, Discord.
5. Na barra de gravação, confira que o **ícone do microfone está ligado**.
6. Grave **15 segundos** falando. Abra o arquivo em `Vídeos\Gravações de Tela` e **escute
   com fone**. Sem voz, não comece.
7. Grave em **blocos curtos**, uma ou duas cenas por arquivo, e ouça o começo de cada um.

> **Plano B de áudio:** gravar só a tela e narrar depois pelo **Clipchamp** ou pelo
> **Gravador de Som**, os dois já instalados.

---

## Cronograma

T+0 é o início do `plan` da base. A coluna "Exemplo" supõe começar às 08:00.

| Quando | Exemplo | O que fazer | Onde está | Gravar? |
|---|---|---|---|---|
| T-30 | 07:30 | Pré-voo técnico e teste de áudio | Esta página | — |
| **T+0** | 08:00 | `terraform -chdir=terraform plan` → conferir `35 to add` → `apply` | OPERACAO 2.3 | **Cena 2** — o `plan` inteiro e o começo do `apply` |
| T+8 | 08:08 | **Checkpoint:** `terraform -chdir=terraform output github_actions_role_arn` devolve o ARN | OPERACAO 2.3 | Final do `apply` |
| T+8 | 08:08 | **Republicar as imagens** — caminho A, re-run dos cinco runs | OPERACAO 2.4 | — |
| T+9 | 08:09 | `terraform -chdir=terraform/cluster apply` | OPERACAO 2.5 | Opcional: o começo |
| T+10 | 08:10 | **Durante o cluster:** gravar a Cena 1 (abertura) e a parte histórica da Cena 3 | Roteiro abaixo | **Cenas 1 e 3a** |
| T+14 | 08:14 | **Checkpoint:** 5 runs `success` e tags no ECR | OPERACAO 2.4 | — |
| T+15 | 08:15 | **Cena 3b ao vivo:** falha e correção de segurança na `dev` | Roteiro abaixo | **Cena 3b** |
| **T+25** | 08:25 | **Checkpoint:** cluster com `Apply complete!` | OPERACAO 2.5 | — |
| T+26 | 08:26 | `aws eks update-kubeconfig` e `kubectl get nodes` com 2 nós `Ready` | OPERACAO 2.6 | — |
| T+28 | 08:28 | Camada k8s: etapa A e etapa B | OPERACAO 2.7 | — |
| T+33 | 08:33 | Conferir `REDIS_URL` e IRSA; pull request só se divergir | OPERACAO 2.9 | — |
| **T+40** | 08:40 | **Checkpoint:** todos os pods `Running` com `READY 1/1`; Application `Synced/Healthy` | OPERACAO 2.9 e 5.5 | — |
| T+40 | 08:40 | Schemas dos bancos | OPERACAO 3 | — |
| T+45 | 08:45 | Seed: chave, flag e regra | OPERACAO 5.1 a 5.3 | — |
| T+55 | 08:55 | Console da AWS e interface do ArgoCD com os 5 serviços | OPERACAO 4 | **Cenas 4 e 5** |
| **T+60** | 09:00 | **Cena principal:** merge → pipeline na `main` → commit do robô → ArgoCD sincroniza a versão nova | Roteiro abaixo | **Cena 6** |
| T+70 | 09:10 | Prova funcional e fechamento | OPERACAO 5.4 e 5.5 | Cenas 7 e 8, que são opcionais |
| T+80 | 09:20 | Parar de gravar → exportar → **ouvir inteiro com fone** → iniciar upload não listado | — | — |
| Depois | ~09:50 | Link abrindo numa aba anônima → **só então** derrubar k8s, cluster e base (opção B) | OPERACAO 6 | — |
| Fim | ~10:10 | Conferências do passo 6.4 → link no README e no relatório → regerar o PDF → enviar | — | — |

**Folga:** o plano ocupa cerca de 2h20. Se um checkpoint atrasar mais de 20 minutos,
veja a tabela de contingências.

---

## Roteiro de cenas — até 20 minutos

O enunciado exige no vídeo: **IaC** (`plan` e `apply`, ou o resultado na AWS),
**DevSecOps** (pipeline falhando no passo de segurança e depois passando), **GitOps** (o
pipeline atualizando a tag), **ArgoCD** (detectando e sincronizando a nova versão sozinho)
e a **interface do ArgoCD com os 5 microsserviços**. Nomes, links e custo vão no
relatório, não no vídeo.

| # | Cena | Duração | Cobre | Pode cortar? |
|---|---|---|---|---|
| 1 | Abertura: o grupo, o problema, "se não está no código, não existe" | 1:00 | contexto | Encurtar |
| 2 | IaC: `plan` e `apply` da base; início do cluster | 3:00 | **IaC** | Não |
| 3 | DevSecOps: falha e correção | 4:00 | **DevSecOps** | Não |
| 4 | Resultado na AWS: VPC, EKS e os RDS no console | 1:30 | IaC — resultado | Encurtar |
| 5 | ArgoCD com a Application e os 5 serviços | 1:30 | **Interface do ArgoCD** | Não |
| 6 | Merge → pipeline → commit do robô → `Synced` → versão nova | 4:00 | **GitOps + ArgoCD** | **Nunca** |
| 7 | Prova funcional: flag, avaliação e evento no DynamoDB | 2:00 | não exigida | Cortar primeiro |
| 8 | Fechamento: desafios e custo | 1:30 | não exigida | Cortar |

Total: cerca de 18:30.

### Cena 2 — IaC

- Mostre o `plan` terminando com `35 to add` e o `apply` começando.
- **Não rode o `plan` do cluster antes de a base existir:** ele lê o estado da base e
  falha. Com a base pronta, mostrar o `apply` do cluster começando basta.
- **Não diga "a base é permanente".** Diga: "separamos em três camadas para derrubar só o
  que cobra por hora; hoje estamos subindo do zero, inclusive a base".

### Cena 3 — DevSecOps

**3a, a prova que já existe**, gravável a qualquer momento. Abra os links diretos, não a
lista do Actions:

- Falha: <https://github.com/fiap-devops-arqcloud-2026/tech-challenge-03/actions/runs/34610575185>
  — SCA vermelho com `PyYAML CVE-2020-14343 CRITICAL`; Imagem e GitOps **pulados**.
- Pipeline completo verde na `main`: <https://github.com/fiap-devops-arqcloud-2026/tech-challenge-03/actions/runs/34606996327>
  — os seis jobs verdes, incluindo imagem e GitOps.

**3b, ao vivo na `dev`**, depois do checkpoint T+14:

1. Em `services/flag-service/requirements.txt`, acrescente `PyYAML==5.3.1` no fim. Commit
   e push na `dev`.
2. **Espere o run terminar vermelho** (`gh run watch <id>`) **antes do próximo push.**
   Um push no meio cancela o run, e a tela mostra `cancelled` em vez da falha.
3. Troque a linha para `PyYAML==6.0.1`. Commit e push. O run fica verde.
4. Narre: "na `dev`, os jobs de imagem e GitOps são pulados por desenho — só a `main`
   publica". Isso explica os dois jobs cinza no run verde.

> **Não remova a linha na correção.** A troca de `5.3.1` por `6.0.1` deixa uma mudança
> líquida no `flag-service`, e é ela que faz a Cena 6 disparar o pipeline na `main`.
> Inserir e depois remover a mesma linha deixa o PR sem diferença no serviço, e o
> pipeline não roda.

### Cena 5 — ArgoCD com os 5

- `kubectl port-forward svc/argocd-server -n argocd 8080:80`, depois
  <http://localhost:8080> com o usuário `admin` (OPERACAO 4).
- Mostre a Application `togglemaster` `Synced/Healthy` e a árvore com os cinco
  Deployments.

### Cena 6 — GitOps e ArgoCD ao vivo

Divida a tela: ArgoCD de um lado, GitHub do outro.

1. Antes de gravar, no Git Bash: `git fetch origin && git diff --stat origin/main dev -- services/flag-service`
   precisa listar pelo menos um arquivo.
2. `gh pr create --base main --head dev --title "fix(flag-service): atualiza PyYAML" --body "Correcao de seguranca da demonstracao."`
   e depois `gh pr merge --merge`.
3. Mostre o run do `flag-service` na `main`: os seis jobs verdes, **incluindo** imagem e
   GitOps.
4. Mostre o commit do robô na `main`: `chore(gitops): flag-service para v1.0.0-<hash>`.
5. No ArgoCD, **sem clicar em nada**: em até 30 s o card vai de `Synced` para
   `OutOfSync`, depois `Progressing`, e volta a `Synced/Healthy`.
6. Prove a versão nova:
   `kubectl get deploy flag-service -n togglemaster -o jsonpath='{.spec.template.spec.containers[0].image}'`
   mostra a tag nova.
7. Depois do merge, sincronize a `dev` no Git Bash:
   `git switch dev && git fetch origin && git merge --ff-only origin/main && git push origin dev`.

> **Nunca corte o intervalo entre o commit do robô e o `Synced`.** É a prova de que
> ninguém mandou sincronizar.

---

## Contingências

| Situação | Até quando | O que fazer |
|---|---|---|
| Teste de áudio mudo | Antes de qualquer cena | Não grave. Confira a haste do A50, o dispositivo de entrada e reabra a Ferramenta de Captura. Se continuar mudo, grave só a tela e narre depois |
| `apply` da base para com `EntityAlreadyExists` | T+10 | `create_github_oidc_provider` está `true`; troque para `false` e aplique de novo |
| `plan` da base falha no data source do provedor OIDC | T+5 | O provedor do outro projeto sumiu; troque para `true` |
| Re-run falha em `Could not assume role with OIDC` | T+15 | A base não tinha terminado. `gh run rerun <id>` depois do `Apply complete!` |
| Scan barra imagem por CVE crítica nova | T+20 | Caminho B do passo 2.4, com a CVE registrada no `.trivyignore` |
| Fila do Actions parada | T+20 | Cancelar os runs da `dev` (comando no passo 2.4) |
| Cluster sem `Apply complete!` | **T+45** | Ler o erro. Se não houver correção clara em 15 minutos, acionar o plano C |
| Pods em `ImagePullBackOff` com as imagens no ECR | T+45 | `kubectl delete pod -n togglemaster <nome>` |
| `/evaluate` responde 502 | Cena 7 | Refazer o passo 5.2 conferindo `configured`. A cena 7 é opcional: pode ser cortada |
| **Plano C** — ambiente não sobe até ~T+90 | — | Usar a gravação muda de 11/09, com 17min58s e o cluster ativo, e narrar por cima no Clipchamp, declarando que as cenas do cluster são de 11/09 |

> **Proteja o plano C agora:** copie `Vídeos\Gravações de Tela\Gravação de Tela 2026-09-11 123247.mp4`
> para outra pasta antes de começar.

---

## Entrega

- [ ] Vídeo exportado e **ouvido inteiro com fone**.
- [ ] Upload no YouTube como **Não listado** — privado o avaliador não abre.
- [ ] Link aberto numa **aba anônima**.
- [ ] Link colado na capa do `README.md` e na seção 2 do `docs/RELATORIO_DE_ENTREGA.md`.
- [ ] PDF do relatório regerado e conferido.
- [ ] AWS derrubada (OPERACAO 6, opção B) e as cinco conferências do passo 6.4 vazias.

> ⚠️ **Pendência que antecede o PDF:** outro agente deixou alterações **não commitadas**
> no `README.md`, no relatório e nos geradores de PDF. Hoje o README aponta para um PDF
> dentro de `output/`, pasta que o Git ignora, então o link fica quebrado no GitHub. O
> gerador escolhido por ele depende do pacote `reportlab`, que não está instalado nesta
> máquina. Resolva isso antes de regerar o PDF.
