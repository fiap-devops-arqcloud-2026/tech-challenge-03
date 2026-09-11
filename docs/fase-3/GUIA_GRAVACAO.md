# Guia de gravação — o que a FIAP quer ver e como mostrar

Criado em 2026-09-11, Claude. Complementa o [roteiro resumido](ROTEIRO_VIDEO.md)
e o [runbook da sessão](../00_COLAB_IA/RUNBOOK-SESSAO.md).

---

## A descoberta que muda o planejamento

**Metade do vídeo pode ser gravada hoje, de graça.**

Dos quatro itens que a FIAP pede no vídeo, **dois rodam inteiramente no
GitHub Actions** e não encostam na AWS paga. Só o ArgoCD e o resultado
final da infraestrutura exigem o cluster de pé.

| Item pedido | Precisa do cluster? | Custo |
|---|---|---|
| IaC — `plan` e `apply` | Parcial: o `plan` não, o `apply` sim | ~US$ 0,37/h só na parte do apply |
| DevSecOps — pipeline falhando e passando | **Não** | **zero** |
| GitOps — tag sendo atualizada | **Não** | **zero** |
| ArgoCD — detectando e sincronizando | **Sim** | ~US$ 0,37/h |

Grave o BLOCO A antes de ligar qualquer coisa. Isso tira pressão da
sessão paga: se algo der errado com o cluster, você já tem metade do
vídeo no bolso.

---

## O que a FIAP pediu, palavra por palavra

Do PDF do enunciado, página 5, seção **ENTREGÁVEIS DA FASE 3**:

> **Vídeo de Demonstração (até 20 min):**
>
> - **IaC:** Mostre o `terraform plan` e o `terraform apply` rodando (ou o resultado final na AWS: VPCs, RDS, EKS criados via código).
> - **Pipeline DevSecOps:** Faça uma alteração no código de um microsserviço (ex: insira um erro proposital ou uma dependência vulnerável) e mostre o pipeline **falhando** no passo de segurança. Depois corrija e mostre **passando**.
> - **GitOps:** Mostre o pipeline atualizando a tag da imagem no repositório de GitOps.
> - **ArgoCD:** Mostre o ArgoCD detectando a mudança e sincronizando a nova versão no cluster automaticamente.

E, da página 5, dentro dos requisitos de CD:

> Mostre a interface do ArgoCD gerenciando os 5 microsserviços.

Da página 6:

> **Relatório de Entrega (.PDF ou .txt):**
>
> - Nomes dos participantes.
> - Link da documentação e do vídeo.
> - Breve resumo dos desafios encontrados e decisões tomadas.
> - Print da estimativa de custos da AWS.

**São 5 coisas no vídeo e 4 no relatório. Nada além disso vale nota.**
Tudo o mais é contexto para o avaliador entender o que está vendo.

---

## Tradução: o que colocar na tela

| O que eles pedem | O que aparece na tela | Onde está |
|---|---|---|
| `terraform plan` rodando | terminal com `Plan: 35 to add, 0 to change, 0 to destroy` | qualquer hora, sem custo |
| `terraform apply` rodando | terminal criando EKS, RDS, ElastiCache | sessão paga |
| resultado final na AWS | console AWS: VPC, EKS, RDS, ElastiCache, SQS, DynamoDB, ECR | sessão paga |
| pipeline **falhando** na segurança | aba Actions com o job **SCA em vermelho** e os jobs **Imagem e GitOps em cinza (skipped)** | GitHub, sem custo |
| pipeline **passando** | a mesma tela, tudo verde | GitHub, sem custo |
| pipeline atualizando a tag | commit `chore(gitops): ... para v1.0.0-<hash>` feito pelo robô, e o diff do `kustomization.yaml` | GitHub, sem custo |
| ArgoCD detectando e sincronizando | interface do ArgoCD saindo de `OutOfSync` para `Synced` sozinha | sessão paga |
| ArgoCD gerenciando os 5 | o card da Application aberto, com os 5 Deployments dentro | sessão paga |

---

# BLOCO A — Gravar hoje, sem ligar nada

Custo: **zero**. Tempo estimado de gravação: **35 a 45 minutos** para
render 8 a 9 minutos de vídeo final.

## Preparação (10 min, antes de apertar REC)

Deixe estas abas abertas no navegador, nesta ordem, para não procurar
nada ao vivo:

1. O repositório no GitHub
2. A aba **Actions** do repositório
3. A execução histórica do bloqueio (link na Cena 3)
4. O arquivo `.github/workflows/_ci-python.yml` aberto no GitHub
5. O arquivo `gitops/overlays/prod/kustomization.yaml`
6. Um terminal **Git Bash** maximizado, com fonte grande

Aumente a fonte do terminal e do navegador. O avaliador vai assistir
num player pequeno — texto de 12px não se lê.

---

## Cena 1 — Abertura (1:30)

**Na tela:** slide ou o README do repositório.

**Diga, nesta ordem:**

1. Nomes dos 5 integrantes do Grupo 203 (isso também vale para o relatório)
2. O problema, nas palavras do enunciado: *"os desenvolvedores estão rodando `kubectl apply` das máquinas locais"* e *"recriar o ambiente leva dias porque foi feito manualmente no console"*
3. A frase que guia a fase: **"Se não está no código, não existe"**
4. O que mudou da Fase 2 para a Fase 3: era tudo manual no console, agora é Terraform, pipeline com portões de segurança e ArgoCD

---

## Cena 2 — IaC, a parte gratuita (2:00)

**Na tela:** terminal Git Bash na raiz do projeto.

**Comando 1** — mostra que a infraestrutura é código organizado em três
camadas com estado separado:

```bash
tree terraform -L 2
```

Se não tiver `tree`, use:

```bash
find terraform -maxdepth 2 -type d | sort
```

**Diga:** "São três camadas, cada uma com estado próprio no S3. A base é
permanente e custa quase nada. A camada do cluster é a cara — sobe e
desce a cada sessão. E a terceira camada cria os objetos dentro do
Kubernetes."

**Comando 2** — o `plan` que a FIAP pede, sem gastar um centavo:

```bash
terraform -chdir=terraform/cluster plan
```

**Espere aparecer a última linha** e deixe-a na tela por 3 segundos:

```
Plan: 35 to add, 0 to change, 0 to destroy.
```

**Diga:** "Trinta e cinco recursos: o cluster EKS, o node group, dois
RDS, o ElastiCache e as roles de acesso dos pods. Nada disso é criado no
console — está tudo em código."

**Comando 3** — a prova de que o estado não é local, que é requisito
explícito do enunciado:

```bash
aws s3 ls s3://togglemaster-tfstate-891376952395-us-east-2-an/prod/
```

**Diga:** "O enunciado exige que o `terraform.tfstate` não fique local.
Ele está no S3, com criptografia e versionamento, um arquivo por
camada."

> O `apply` de verdade fica para o BLOCO B. O enunciado aceita as duas
> coisas — *"o `terraform plan` e o `terraform apply` rodando **ou** o
> resultado final na AWS"* — mas mostrar os dois é mais forte.

---

## Cena 3 — DevSecOps: o pipeline barrando de verdade (4:00)

**Esta é a cena que mais vale nota. Ela tem duas partes.**

### Parte 1 — a prova histórica, que já aconteceu (1:30)

Abra esta execução real:

**https://github.com/fiap-devops-arqcloud-2026/tech-challenge-03/actions/runs/34360653255**

Na tela aparece exatamente isto:

| Job | Resultado |
|---|---|
| Build e testes | ✅ verde |
| Linter (golangci-lint) | ✅ verde |
| SAST (gosec) | ✅ verde |
| **SCA (Trivy fs)** | ❌ **vermelho** |
| **Imagem Docker e push no ECR** | ⏭️ **cinza — skipped** |
| **Atualizar tag no GitOps** | ⏭️ **cinza — skipped** |

Clique no job vermelho e mostre o achado:

```
Total: 1 (CRITICAL: 1)
golang.org/x/crypto │ CVE-2026-56854 │ CRITICAL │ v0.20.0 → 0.55.0
```

**Diga — e enfatize, porque é aqui que está o requisito:**

> "Repare em duas coisas. Primeira: o único job vermelho é o de
> segurança — build, linter e SAST passaram. Segunda, e mais importante:
> os dois jobs seguintes não estão vermelhos, estão **cinza**. Eles
> foram **pulados**. O enunciado pede que uma vulnerabilidade crítica
> faça o pipeline falhar **e não prosseguir** — e é literalmente isso: a
> imagem nem chegou a ser construída. Nada vulnerável saiu daqui."

Mostre então a linha do workflow que causa esse comportamento. Abra
`.github/workflows/_ci-python.yml` e aponte:

```yaml
needs: [build, lint, sast, sca]
```

**Diga:** "É esta linha. O job da imagem declara que depende dos quatro
anteriores. Se qualquer um falhar, ele não roda — não é uma checagem
depois do fato, é um portão antes."

> **Bônus que vale citar:** esse CVE estava no projeto e o pipeline
> anterior **passava verde**, porque os scans usavam `continue-on-error`.
> A vulnerabilidade era real e invisível. Foi ao ligar o portão de
> bloqueio que ela apareceu.

### Parte 2 — a falha ao vivo, que o enunciado pede (2:30)

O enunciado pede que **você faça** uma alteração e mostre o efeito. A
dependência abaixo já foi testada e está confirmada: derruba o pipeline
e tem correção disponível.

**Passo 1 — inserir a dependência vulnerável.** Abra
`services/flag-service/requirements.txt` e acrescente no fim:

```
PyYAML==5.3.1
```

**Diga:** "Essa versão do PyYAML tem o CVE-2020-14343, classificado como
crítico. É uma vulnerabilidade real e conhecida."

**Passo 2 — enviar para a branch de trabalho:**

```bash
git switch dev && git add services/flag-service/requirements.txt && git commit -m "demo: dependencia vulneravel proposital" && git push origin dev
```

Este comando faz quatro coisas em sequência: garante que você está na
`dev`, marca o arquivo alterado, cria o commit e envia para o GitHub.

**Passo 3 — abrir a aba Actions e esperar.** Leva cerca de 1 minuto.
Você vai ver o job **SCA (Trivy fs)** ficar vermelho, e os dois últimos
ficarem cinza. Clique no vermelho e mostre:

```
PyYAML │ CVE-2020-14343 │ CRITICAL │ 5.3.1 → 5.4
```

**Passo 4 — corrigir.** Troque a linha para:

```
PyYAML==6.0.1
```

E envie:

```bash
git add services/flag-service/requirements.txt && git commit -m "fix: corrige a dependencia vulneravel" && git push origin dev
```

**Passo 5 — mostrar tudo verde.** Volte à aba Actions. Todos os jobs
verdes.

**Diga:** "Mesma pipeline, mesma regra. Mudou só a versão da
dependência. O portão não foi afrouxado — o problema é que foi
resolvido."

> **Corte na edição.** A espera do pipeline é de 1 a 2 minutos por
> execução. Grave contínuo e corte na edição, ou pause a gravação. Não
> deixe 2 minutos de tela parada no vídeo final.

---

## Cena 4 — GitOps: o robô atualizando a tag (2:00)

**Na tela:** o histórico de commits da `main` no GitHub.

Mostre os commits feitos pelo **próprio pipeline**:

```
chore(gitops): auth-service para v1.0.0-7ab0602 [skip ci]
chore(gitops): flag-service para v1.0.0-7ab0602 [skip ci]
chore(gitops): targeting-service para v1.0.0-7ab0602 [skip ci]
chore(gitops): analytics-service para v1.0.0-7ab0602 [skip ci]
chore(gitops): evaluation-service para v1.0.0-7ab0602 [skip ci]
```

Clique em um deles e mostre o diff — uma linha só:

```diff
-  newTag: v1.0.0-122174a
+  newTag: v1.0.0-7ab0602
```

**Diga:** "Nenhuma pessoa escreveu esse commit. É o último passo do
pipeline: depois de publicar a imagem no ECR, ele roda `kustomize edit
set image` e grava a tag nova na pasta de GitOps. O `[skip ci]` no fim
evita que esse commit dispare o pipeline de novo, num laço infinito."

Mostre então que a tag corresponde a uma imagem real no ECR:

```bash
aws ecr describe-images --repository-name flag-service --region us-east-2 --query 'sort_by(imageDetails,&imagePushedAt)[-1].imageTags' --output text
```

**Diga:** "A tag no Git e a tag no registro são a mesma. E ela é o hash
do commit — exatamente o padrão `v1.0.0-a1b2c3d` que o enunciado pede."

Feche a cena mostrando que o CI **não** faz deploy:

```bash
grep -rn "kubectl apply" .github/workflows/ || echo "nenhum kubectl apply no CI"
```

**Diga:** "O enunciado diz para abandonar o push direto. Não existe um
único `kubectl apply` nos workflows. O pipeline escreve no Git, e quem
aplica no cluster é o ArgoCD."

---

# BLOCO B — Gravar com o cluster no ar

Custo: **~US$ 0,37/h**. Reserve **3 horas**, grave nas últimas.

> **Antes de começar, leia o [runbook](../00_COLAB_IA/RUNBOOK-SESSAO.md)
> inteiro.** Ele tem as armadilhas: o NAT que precisa ser ligado, o
> apply da camada k8s que são dois comandos, e os schemas dos bancos.
> Nenhuma delas perdoa esquecimento.

## Cena 5 — IaC, o apply e o resultado na AWS (2:30)

**Grave o `apply` acontecendo**, mesmo que corte depois — é o que o
enunciado pede literalmente. Não precisa mostrar os 25 minutos: grave o
começo, o fim, e corte o meio.

O que deixar na tela ao final:

```
Apply complete! Resources: 35 added, 0 changed, 0 destroyed.
```

Depois abra o **console da AWS** e percorra, sem pressa, uma tela por
recurso:

| Console | O que apontar |
|---|---|
| VPC | a VPC, 2 subnets públicas e 2 privadas em zonas diferentes |
| EKS | o cluster `togglemaster` ativo e o node group com 2 nós |
| RDS | as 2 instâncias PostgreSQL, **privadas** |
| ElastiCache | o cluster Redis |
| SQS | a fila e a dead-letter queue |
| DynamoDB | a tabela `ToggleMasterAnalytics` |
| ECR | os 5 repositórios, com as imagens dentro |

**Diga em cada tela:** "Criado por Terraform. Nenhum clique no console."

**Sobre os 2 RDS — não esconda, explique:**

> "O enunciado pede 3 instâncias RDS. Esta conta está no plano gratuito
> novo da AWS, que **recusa** a terceira instância com a mensagem
> `maximum number of instances available with free plan accounts`.
> Criamos duas, e o terceiro banco roda como StatefulSet dentro do
> cluster — o mesmo arranjo da Fase 2, que foi confirmado com o
> professor. Está documentado na decisão D-015."

Mostrar isso de frente é melhor do que torcer para não perguntarem.

---

## Cena 6 — ArgoCD gerenciando os 5 microsserviços (2:00)

Abra a interface:

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:80
```

Este comando cria um túnel do seu computador até o serviço dentro do
cluster. **O terminal fica travado** — é normal, deixe aberto e use
outro.

A senha inicial sai daqui:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
```

Acesse **http://localhost:8080**, usuário `admin`.

**Na tela:** o card da Application `togglemaster`, em `Healthy` e
`Synced`. Clique nele para abrir a árvore.

**Diga:** "Uma Application gerenciando os cinco microsserviços. O ArgoCD
lê a pasta `gitops/overlays/prod` na branch `main`, renderiza o Kustomize
sozinho e mantém o cluster igual ao que está no Git."

Percorra a árvore apontando os 5 Deployments: `auth-service`,
`flag-service`, `targeting-service`, `evaluation-service`,
`analytics-service`.

> **Isto atende o pedido explícito da página 5:** *"Mostre a interface do
> ArgoCD gerenciando os 5 microsserviços."*

---

## Cena 7 — ArgoCD detectando e sincronizando sozinho (3:00)

**Esta é a cena mais importante do BLOCO B.** Ela precisa mostrar o
ArgoCD agindo **sem ninguém mandar**.

Divida a tela: ArgoCD de um lado, GitHub do outro.

**Passo 1 — provoque uma mudança.** O caminho mais curto e mais honesto
é alterar o número de réplicas de um serviço no Git:

Em `gitops/base/flag-service/deployment.yaml`, troque `replicas: 1` para
`replicas: 2`. Então:

```bash
git switch dev && git add gitops/ && git commit -m "demo: sobe o flag-service para 2 replicas" && git push origin dev
```

```bash
gh pr create --base main --head dev --title "demo: 2 replicas no flag-service" --body "Demonstracao de sincronizacao automatica." && gh pr merge --merge
```

O segundo comando abre o Pull Request e já faz o merge — o ArgoCD só
enxerga a `main`.

**Passo 2 — filme a interface do ArgoCD sem tocar em nada.**

O que vai acontecer, em ordem:

1. o card muda de `Synced` para **`OutOfSync`** (o ArgoCD consulta o Git a cada 3 minutos; se quiser acelerar, clique em **Refresh** — mas deixe claro que Refresh só antecipa a consulta, não aplica nada)
2. ele entra em **`Progressing`**
3. nasce um segundo pod do `flag-service`
4. volta para **`Synced`** e **`Healthy`**

**Diga enquanto acontece:** "Ninguém rodou `kubectl`. Eu mudei um
arquivo no Git e o ArgoCD reconciliou o cluster sozinho. É isso que o
enunciado chama de GitOps: o Git é a fonte da verdade, e o cluster
persegue o Git."

**Passo 3 — a cereja: mostre o self-heal.** Apague um pod na mão:

```bash
kubectl delete pod -n togglemaster -l app=flag-service --wait=false
```

O ArgoCD recria. **Diga:** "Mexi no cluster por fora. O ArgoCD desfez.
É essa propriedade que acaba com o `kubectl apply` de máquina local que
o enunciado descreve como problema."

> **Se o tempo apertar,** o Passo 3 é o único descartável desta cena.
> Os passos 1 e 2 são o requisito.

---

## Cena 8 — Funciona de verdade, custo e desligamento (2:30)

**Parte 1 — prova funcional (1:30).** Crie uma flag e avalie-a, seguindo
a FASE 2 do runbook. Mostre a resposta do `evaluation-service` e depois
o evento gravado no DynamoDB.

**Diga:** "Não é só infraestrutura de pé: os cinco serviços conversam.
A avaliação passou pelo Redis, consultou flag e targeting, e o evento
foi para a fila SQS e de lá para o DynamoDB."

**Parte 2 — custo (30s).** Mostre o print de custo — o mesmo que vai no
relatório.

**Parte 3 — desligamento (30s).** Grave o começo do destroy:

```bash
terraform -chdir=terraform/cluster destroy
```

**Diga:** "A camada cara é destruída ao fim de cada sessão. Os
repositórios ECR, as imagens, a fila e a tabela ficam, porque estão numa
camada de estado separada. Uma sessão de três horas custa cerca de um
dólar e dez."

**Parte 4 — fecho (30s).** Desafios e decisões, em três frases:

1. a conta recusou a terceira instância RDS e o t3.medium — resolvido com banco em pod e outro tipo de máquina
2. o portão de bloqueio encontrou um CVE crítico real que o pipeline anterior escondia
3. o `terraform.tfstate` guarda senha em texto puro, e por isso o backend remoto no S3 não é detalhe: é segurança

> **NÃO ESQUEÇA, depois de gravar:** desligue o NAT Gateway (passo 4.3 do
> runbook). Ele não morre com o destroy do cluster e custa ~US$ 33/mês
> esquecido ligado.

---

# O relatório (.PDF ou .txt)

São quatro itens. Nem um a menos.

### 1. Nomes dos participantes

Os 5 do Grupo 203, com RM. Já estão na tabela do `README.md`.

### 2. Link da documentação e do vídeo

- documentação: a URL do repositório no GitHub
- vídeo: o link do YouTube (**não listado**, não privado — privado o
  avaliador não abre)

### 3. Breve resumo dos desafios e decisões

Quatro parágrafos curtos bastam. Os desvios que **precisam** estar aqui,
porque são diferenças em relação ao enunciado:

| Desvio | Como explicar |
|---|---|
| **2 RDS em vez de 3** | conta no plano gratuito recusa a terceira instância; o terceiro banco roda como StatefulSet, igual à Fase 2, confirmado com o professor (D-015) |
| **Sem Ingress / Load Balancer** | o enunciado não exige; um ALB custaria ~US$ 16-20/mês. Acesso por `port-forward` (D-012) |
| **`c7i-flex.large` em vez de `t3.medium`** | a conta recusou o t3.medium como não elegível ao Free Tier |
| **EKS 1.34 e não 1.31** | fora do suporte padrão o control plane vai de US$ 0,10/h para US$ 0,60/h — seis vezes mais |
| **Exceções em `.trivyignore`** | 3 CVEs críticos sem correção publicada, em `perl-base` da imagem base do Python. Listados um a um, com justificativa, em vez de desligar a regra inteira |

E o achado que vale contar como aprendizado:

> Ao ligar o portão de bloqueio, apareceu um CVE **crítico** de verdade
> numa dependência — que estava lá antes e passava despercebido, porque
> os scans anteriores usavam `continue-on-error`. Um pipeline verde não
> prova que o código é seguro; prova que ninguém configurou o pipeline
> para reclamar.

### 4. Print da estimativa de custos da AWS

Duas fontes servem, e mostrar as duas é mais forte:

- **AWS Pricing Calculator** — a estimativa de um mês com o ambiente de pé
- **Billing → Cost Explorer** — o gasto real das sessões, filtrando por
  `project = fiap` (todos os recursos têm essa tag)

---

# Checklist final — antes de enviar

**Vídeo**

- [ ] Duração **≤ 20 minutos**
- [ ] `terraform plan` na tela
- [ ] `terraform apply` na tela **ou** os recursos no console AWS (de preferência os dois)
- [ ] Pipeline **vermelho** no passo de segurança, com o CVE visível
- [ ] Os jobs seguintes **cinza (skipped)** — a prova de "não prosseguir"
- [ ] Pipeline **verde** depois da correção
- [ ] Commit do robô atualizando a tag, com o diff aberto
- [ ] ArgoCD saindo de `OutOfSync` para `Synced` **sozinho**
- [ ] Interface do ArgoCD com os **5** microsserviços visíveis
- [ ] Os 5 integrantes citados
- [ ] Vídeo **não listado**, link testado numa aba anônima

**Relatório**

- [ ] Nomes e RMs dos 5
- [ ] Link do repositório
- [ ] Link do vídeo, testado
- [ ] Desafios e decisões, com os desvios explicados
- [ ] Print de custo

**Depois de tudo**

- [ ] `terraform -chdir=terraform/cluster destroy` concluído
- [ ] **NAT Gateway desligado** (`enable_nat_gateway = false` + apply da base)
- [ ] Conferido que não sobrou nada cobrando
