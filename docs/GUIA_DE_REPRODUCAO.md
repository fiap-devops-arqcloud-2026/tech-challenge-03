# Guia de reprodução do ToggleMaster

Este guia recria do zero, **na sua própria conta AWS e na sua própria cópia do repositório**, o ambiente completo da Fase 3: rede, cluster EKS, bancos, fila, pipeline de CI com DevSecOps, GitOps e ArgoCD. No fim, mostra como destruir tudo e conferir que nada ficou cobrando.

- **Para quem é:** quem quer ver o projeto rodando de verdade, sem depender do grupo.
- **O que você obtém:** os 5 microsserviços no EKS, sincronizados pelo ArgoCD a partir do Git, com imagens publicadas pelo seu próprio pipeline.
- **Quanto custa:** cerca de US$ 0,39/h com tudo de pé (estimativa de 2026-09-11, região us-east-2). O detalhe está no [README, seção 8](../README.md#8-custo).
- **Quanto demora:** só algumas etapas foram medidas, e cada tempo aparece datado na seção correspondente. O tempo total da recriação não foi medido [INCERTO].

O porquê de cada decisão está no [README](../README.md) e as tabelas técnicas estão em [ARQUITETURA](ARQUITETURA.md). Aqui ficam os comandos, os tempos, os valores a trocar e as armadilhas.

---

## Caminho rápido

Cada passo leva à seção com os comandos. Os passos marcados como **bloqueante** não podem ser pulados nem trocados de ordem.

1. Crie sua cópia do repositório (fork ou repositório novo): [seção 1](#1-pré-requisitos-e-sua-cópia-do-repositório).
2. Exporte o **mesmo** perfil AWS em todas as janelas: [seção 0](#0-antes-de-começar).
3. Crie o bucket de estado do Terraform: [seção 3](#3-bucket-de-estado-do-terraform).
4. Faça, na `dev`, o commit com as trocas previsíveis de conta e bucket: [seção 2](#2-valores-fixos-a-trocar-em-outra-conta).
5. Crie os `terraform.tfvars` locais da base e da camada k8s: [seção 2](#2-valores-fixos-a-trocar-em-outra-conta).
6. Aplique a camada base: [seção 4](#4-camada-base).
7. **Bloqueante:** só depois do apply da base, leve a `dev` para a `main`. É isso que publica as imagens: [seção 5](#5-publicação-das-imagens-no-ecr).
8. Confira as 5 imagens no ECR: [seção 5](#5-publicação-das-imagens-no-ecr).
9. Aplique a camada cluster, que pode rodar enquanto os pipelines trabalham: [seção 6](#6-camada-cluster-e-endpoints-do-overlay).
10. Faça o commit do `REDIS_URL` e leve para a `main`: [seção 6](#6-camada-cluster-e-endpoints-do-overlay).
11. Rode `aws eks update-kubeconfig`: [seção 6](#6-camada-cluster-e-endpoints-do-overlay).
12. **Bloqueante:** só com as imagens no ECR e o `REDIS_URL` na `origin/main`, aplique a camada k8s em duas etapas: [seção 7](#7-camada-k8s-e-argocd).
13. Crie os schemas e a chave de serviço: [seção 8](#8-schemas-chave-de-serviço-e-dados-de-exemplo).
14. Verifique ponta a ponta: [seção 9](#9-verificação-ponta-a-ponta).
15. Destrua na ordem k8s → cluster → base e confira as sobras: [seção 10](#10-destruição-e-checagem-de-custo).

---

## 0. Antes de começar

Três regras evitam quase todos os erros deste guia: usar o Git Bash, nunca responder "yes" a um apply interativo e usar sempre a mesma identidade na AWS.

**Convenções dos comandos**

- Todos os blocos são para o **Git Bash** (no Windows) ou para um terminal Linux/macOS. O PowerShell 5.1 não aceita `&&` nem a barra invertida de continuação de linha.
- Cada comando ocupa uma linha e tem um comentário logo acima. Nenhum bloco usa `&&` nem continuação de linha, então dá para colar o bloco inteiro.
- O Terraform roda sempre em dois passos: `plan -out=<arquivo>.tfplan` e depois `apply <arquivo>.tfplan`. O apply de um plano salvo não faz pergunta, o que impede que a linha seguinte do bloco colado vire a resposta do "yes". Os arquivos `*.tfplan` já estão no `.gitignore`.
- `<conta>`, `<regiao>`, `<owner>/<repo>` e `<perfil>` são marcadores: troque pelos seus valores.

**Mesma identidade em tudo.** O cluster nasce com `bootstrap_cluster_creator_admin_permissions = true`: só o principal IAM que rodou o apply do cluster recebe acesso de administrador. Use o mesmo perfil nas três camadas e no `kubectl`, senão o `kubectl` responde `Unauthorized`.

**Variáveis da sessão.** Rode este bloco em **toda janela nova** do Git Bash, dentro da pasta da sua cópia:

```bash
# Seleciona o perfil da AWS CLI; o mesmo perfil vale para as três camadas e para o kubectl
export AWS_PROFILE="<perfil>"
# Desliga a paginação da AWS CLI, para nenhum comando parar esperando tecla
export AWS_PAGER=""
# Região usada em todo o guia; o código vem com us-east-2 (outra região exige a Tabela 2 da seção 2)
export REGIAO=us-east-2
# Sua cópia do repositório no GitHub, no formato dono/nome
export REPO="<owner>/<repo>"
# Lê o ID da sua conta AWS; se este comando falhar, nada adiante funciona
export CONTA=$(aws sts get-caller-identity --query Account --output text)
# Nome do bucket de estado, único no mundo por conter o ID da conta e a região
export BUCKET=togglemaster-tfstate-$CONTA-$REGIAO
# Mostra os valores para conferir antes de seguir
echo "perfil=$AWS_PROFILE conta=$CONTA regiao=$REGIAO repo=$REPO bucket=$BUCKET"
```

**Fluxo Git na sua cópia.** Você pode fazer push direto na `main` da sua cópia. Este guia usa `dev` e depois leva a `dev` para a `main`, porque é o fluxo do projeto, mas o essencial é outro: **faça `git pull` antes de cada commit na `main`**, porque o pipeline comita as tags das imagens direto nela.

**Quando começa a cobrança.** O NAT Gateway nasce com a base e custa US$ 0,045/h. O grosso do custo começa no apply do cluster (EKS, nós, RDS e ElastiCache).

---

## 1. Pré-requisitos e sua cópia do repositório

Você precisa de algumas ferramentas, de uma conta AWS com permissão de administrador e de uma cópia do repositório que seja sua, porque o pipeline vai publicar imagens na sua conta.

| Ferramenta | Versão | Para quê |
|---|---|---|
| AWS CLI | v2, no PATH | Autenticação e conferências. A camada k8s chama `aws eks get-token`, então a CLI precisa estar no PATH |
| Terraform | >= 1.11 (o CI usa 1.16.0) | As três camadas usam `use_lockfile`, que exige 1.11 ou mais nova |
| kubectl | compatível com Kubernetes 1.34 | Operar o cluster, port-forward e schemas |
| git | qualquer | Cópia do repositório e commits |
| gh (GitHub CLI) | autenticado | Fork, acompanhamento dos pipelines e pull requests |
| Git Bash | qualquer | Terminal de todos os blocos (no Windows) |
| Docker com Compose v2 | 24+ | Só para o [Apêndice A](#apêndice-a-execução-local-com-docker-compose) |

```bash
# Confere a identidade na AWS; guarde o campo Arn, ele precisa ser o mesmo até o fim
aws sts get-caller-identity
# Confere a versão do Terraform (precisa ser 1.11 ou mais nova)
terraform version
# Confere se o kubectl está instalado
kubectl version --client
# Confere se o GitHub CLI está logado
gh auth status
```

**Validade no tempo.** O código usa EKS 1.34, em suporte padrão até 2026-12-01. Fora do suporte padrão, o control plane passa de US$ 0,10/h para US$ 0,60/h.

```bash
# Mostra a situação e o fim do suporte padrão da versão 1.34 na sua região
aws eks describe-cluster-versions --cluster-versions 1.34 --region "$REGIAO" --query "clusterVersions[].[clusterVersion,versionStatus,endOfStandardSupportDate]" --output table
```

Se a 1.34 já tiver saído do suporte padrão, crie `terraform/cluster/terraform.tfvars` com `kubernetes_version = "<versão>"`. A compatibilidade dos addons com outra versão não foi testada [INCERTO].

**Limites da conta.** A conta usada pelo grupo está no plano gratuito. Nela, a API recusou uma terceira instância RDS e o tipo `t3.medium` (observado em 2026-08-27); por isso o código usa 2 RDS e nós `c7i-flex.large`. Os nós somam 4 vCPU e podem chegar a 8 vCPU com o máximo de 4 nós.

```bash
# Mostra a cota de vCPU das instâncias On-Demand padrão, que inclui a família C; precisa ser 8 ou mais
aws service-quotas get-service-quota --service-code ec2 --quota-code L-1216C47A --region "$REGIAO" --query "Quota.Value"
```

### Sua cópia

**Opção (a): fork.** É o caminho mais simples. O fork é público.

```bash
# Cria o fork na sua conta e já clona para a pasta atual
gh repo fork fiap-devops-arqcloud-2026/tech-challenge-03 --clone
# Entra na pasta clonada
cd tech-challenge-03
```

No GitHub, abra a aba **Actions** do fork e clique no botão que habilita os workflows: em fork eles vêm desligados.

**Opção (b): repositório novo.** Pode ser privado. Se for privado, a camada k8s precisa de um token ([seção 7](#7-camada-k8s-e-argocd)).

```bash
# Cria um repositório vazio e privado na sua conta
gh repo create "$REPO" --private
# Baixa só o histórico do original, com todas as branches e tags
git clone --bare https://github.com/fiap-devops-arqcloud-2026/tech-challenge-03.git
# Entra na cópia sem pasta de trabalho
cd tech-challenge-03.git
# Envia branches e tags para o seu repositório novo
git push --mirror "https://github.com/$REPO.git"
# Volta para a pasta anterior
cd ..
# Clona a sua cópia para trabalhar nela
git clone "https://github.com/$REPO.git"
```

Depois entre na pasta clonada e rode de novo o bloco de variáveis da [seção 0](#0-antes-de-começar).

```bash
# Lista os workflows da sua cópia: 5 serviços, Terraform Check e Compose Integration
gh workflow list --repo "$REPO"
```

**Permissões do pipeline.** Não é preciso mudar *Workflow permissions*: o YAML já pede `contents: write` para o job que comita a tag. Uma política da organização pode restringir isso [INCERTO]. Se a `main` da sua cópia tiver proteção de branch ou ruleset, libere o push do `github-actions[bot]`, senão o job de GitOps falha depois de 5 tentativas.

---

## 2. Valores fixos a trocar em outra conta

Alguns valores não aceitam variável: o nome do bucket no bloco `backend`, os `terraform_remote_state`, o registry e a role nos workflows e os endereços no overlay do GitOps. Eles precisam ser editados nos arquivos. Quase todos são **previsíveis**, porque dependem só do ID da conta, da região e de nomes fixos. Só o endereço do Redis precisa esperar o cluster existir.

```bash
# Lista onde aparece o ID da conta original
git grep -n 891376952395
# Lista onde aparece o nome do repositório original
git grep -n tech-challenge-03
# Lista onde aparece o nome do bucket original
git grep -n togglemaster-tfstate
```

Ignore as ocorrências em documentos (`.md`) e em comentários: elas não mudam o comportamento.

**Tabela 1: valores a trocar** (conta, bucket e repositório)

| Arquivo | Chave | Valor atual | Novo valor | Previsível? | Como aplicar |
|---|---|---|---|---|---|
| `terraform/backend.tf` | `bucket` e `region` do `backend "s3"` | `togglemaster-tfstate-891376952395-us-east-2-an`, `us-east-2` | seu bucket e sua região | Sim | Editar |
| `terraform/cluster/backend.tf` | `bucket` e `region` | idem | idem | Sim | Editar |
| `terraform/cluster/data.tf` | `bucket` e `region` do estado da base | idem | idem | Sim | Editar |
| `terraform/k8s/backend.tf` | `bucket` e `region` | idem | idem | Sim | Editar |
| `terraform/k8s/data.tf` | `bucket` e `region` nos 2 blocos (estados da base e do cluster) | idem | idem | Sim | Editar |
| `terraform/variables.tf` | `github_repository` | `fiap-devops-arqcloud-2026/tech-challenge-03` | `<owner>/<repo>` | Sim | tfvars da base |
| `terraform/variables.tf` | `create_github_oidc_provider` | `true` | `false` se a conta já tiver o provedor OIDC do GitHub | Sim, com o comando desta seção | tfvars da base |
| `terraform/variables.tf` | `enable_nat_gateway` | `true` (o `.example` vem com `false`) | `true` | Sim | tfvars da base |
| `terraform/k8s/variables.tf` | `gitops_repo_url` | `https://github.com/fiap-devops-arqcloud-2026/tech-challenge-03.git` | `https://github.com/<owner>/<repo>.git` | Sim | tfvars da k8s |
| `.github/workflows/_ci-go.yml` e `_ci-python.yml` | `ECR_REGISTRY` | `891376952395.dkr.ecr.us-east-2.amazonaws.com` | `<conta>.dkr.ecr.<regiao>.amazonaws.com` | Sim | Editar |
| `.github/workflows/_ci-go.yml` e `_ci-python.yml` | `AWS_ROLE_ARN` | `arn:aws:iam::891376952395:role/togglemaster-github-actions` | `arn:aws:iam::<conta>:role/togglemaster-github-actions` | Sim | Editar |
| `gitops/overlays/prod/kustomization.yaml` | `newName` nas 5 entradas de `images` | `891376952395.dkr.ecr.us-east-2.amazonaws.com/<serviço>` | `<conta>.dkr.ecr.<regiao>.amazonaws.com/<serviço>` | Sim | Editar (recomendado) |
| `gitops/overlays/prod/patches/endpoints.yaml` | `AWS_SQS_URL` (2 vezes) | `https://sqs.us-east-2.amazonaws.com/891376952395/togglemaster-events` | `https://sqs.<regiao>.amazonaws.com/<conta>/togglemaster-events` | Sim | Editar |
| `gitops/overlays/prod/patches/irsa.yaml` | `eks.amazonaws.com/role-arn` (2 vezes) | `arn:aws:iam::891376952395:role/togglemaster-{evaluation,analytics}-irsa` | `arn:aws:iam::<conta>:role/togglemaster-{evaluation,analytics}-irsa` | Sim | Editar |
| `gitops/overlays/prod/patches/endpoints.yaml` | `REDIS_URL` | `redis://togglemaster-redis.ewbn3x.ng.0001.use2.cache.amazonaws.com:6379` | saída `redis_url` da camada cluster | **Não** | Editar só depois do cluster ([seção 6](#6-camada-cluster-e-endpoints-do-overlay)) |

Sobre o `newName`: quando um serviço publica, o job de GitOps reescreve a entrada inteira com o `ECR_REGISTRY` do workflow. Como a troca dos workflows dispara os 5 pipelines, a troca manual é opcional, mas deixa o overlay certo desde o primeiro commit. Nas duas criações do grupo na mesma conta (2026-09-11 e 2026-09-15) o `REDIS_URL` foi o mesmo; numa conta nova ele muda.

**Fluxo recomendado.** Um commit com todas as trocas previsíveis, preparado **antes** da base e levado à `main` **só depois** do apply da base, porque a role do CI precisa existir. Depois do cluster, um segundo commit só com o `REDIS_URL`.

Os comandos abaixo assumem a região us-east-2. Para outra região, veja a Tabela 2 antes.

```bash
# Vai para a branch dev (se a sua cópia não tiver dev, use: git switch -c dev)
git switch dev
# Troca o nome do bucket nos backend.tf e data.tf; vem antes da troca da conta porque o nome contém o ID antigo
git grep -l togglemaster-tfstate-891376952395-us-east-2-an -- '*.tf' | xargs -r sed -i "s/togglemaster-tfstate-891376952395-us-east-2-an/$BUCKET/g"
# Troca o ID da conta nos 2 workflows e no overlay (registry, role do CI, fila e roles IRSA)
git grep -l 891376952395 -- .github/workflows/_ci-go.yml .github/workflows/_ci-python.yml gitops/overlays/prod | xargs -r sed -i "s/891376952395/$CONTA/g"
# Mostra o resumo do que mudou; confira que são só os arquivos da Tabela 1
git diff --stat
# Confirma que nenhum arquivo funcional ainda cita a conta ou o bucket originais (não deve listar .tf, .yml nem .yaml)
git grep -n -e 891376952395 -e togglemaster-tfstate-891376952395 -- '*.tf' '*.yml' '*.yaml'
# Adiciona só os arquivos alterados, listados um a um (nunca git add de tudo)
git add terraform/backend.tf terraform/cluster/backend.tf terraform/cluster/data.tf terraform/k8s/backend.tf terraform/k8s/data.tf .github/workflows/_ci-go.yml .github/workflows/_ci-python.yml gitops/overlays/prod/kustomization.yaml gitops/overlays/prod/patches/endpoints.yaml gitops/overlays/prod/patches/irsa.yaml
# Registra as trocas previsíveis
git commit -m "chore: valores da nova conta AWS"
# Envia para a dev; aqui os pipelines só verificam, nada é publicado
git push origin dev
```

**Tabela 2: só se trocar de região**

| Onde | O que mudar | Como aplicar |
|---|---|---|
| `region` nos 5 arquivos `backend.tf` e `data.tf` da Tabela 1 | a nova região | Editar |
| variável `aws_region` das 3 camadas | a nova região | `aws_region` no tfvars de cada camada |
| variável `availability_zones` da base | duas AZs da nova região | tfvars da base |
| `AWS_REGION` em `_ci-go.yml` e `_ci-python.yml` | a nova região | Editar |
| `AWS_REGION` em `gitops/base/evaluation-service/configmap.yaml` e `gitops/base/analytics-service/configmap.yaml` | a nova região | Editar |
| região dentro do registry e da URL da fila (Tabela 1) | a nova região | Editar |

A versão 1.34 do EKS e o tipo `c7i-flex.large` precisam existir na região nova.

### Os `terraform.tfvars` locais

Cada camada lê sozinha o `terraform.tfvars` da própria pasta, tanto no plan quanto no plan de destroy, então o destroy usa os mesmos valores do apply. O `.gitignore` já ignora `*.tfvars`.

**Não copie o `terraform.tfvars.example` sem trocar `enable_nat_gateway` para `true`.** Sem NAT, os nós não baixam imagens e todos os pods ficam em `ImagePullBackOff`.

A AWS aceita um único provedor OIDC do GitHub por conta. Criar outro falha com `EntityAlreadyExists`, e o `plan` não avisa, porque só compara com o estado.

```bash
# Conta os provedores OIDC do GitHub na conta: 1 significa que já existe, 0 que não existe
aws iam list-open-id-connect-providers --output text | grep -c token.actions.githubusercontent.com
# Defina false se o número acima for 1 (o provedor será só lido e nunca destruído), ou true se for 0
export OIDC=false
# Cria o tfvars da base com a primeira linha: NAT ligado
printf 'enable_nat_gateway = true\n' > terraform/terraform.tfvars
# Acrescenta a segunda linha: criar ou só ler o provedor OIDC
printf 'create_github_oidc_provider = %s\n' "$OIDC" >> terraform/terraform.tfvars
# Acrescenta a terceira linha: o repositório que a role do CI vai aceitar
printf 'github_repository = "%s"\n' "$REPO" >> terraform/terraform.tfvars
# Cria o tfvars da camada k8s com a URL do repositório que o ArgoCD vai ler
printf 'gitops_repo_url = "https://github.com/%s.git"\n' "$REPO" > terraform/k8s/terraform.tfvars
# Mostra os dois arquivos para conferir
cat terraform/terraform.tfvars terraform/k8s/terraform.tfvars
```

---

## 3. Bucket de estado do Terraform

O bucket é a memória do Terraform: guarda o que cada camada criou. Ele é criado uma vez por conta, fora do Terraform, e é o único passo manual da infraestrutura.

- **Nome:** único no mundo inteiro. A [seção 0](#0-antes-de-começar) monta `togglemaster-tfstate-<conta>-<regiao>`. O bucket original do grupo tem um sufixo `-an` cujo significado não foi confirmado [INCERTO]; ele não é necessário. O nome precisa ser o mesmo gravado nos arquivos da [seção 2](#2-valores-fixos-a-trocar-em-outra-conta).
- **Chaves de estado:** `prod/base.tfstate`, `prod/cluster.tfstate` e `prod/k8s.tfstate`. Com `use_lockfile = true`, a trava de cada camada fica ao lado, em `<chave>.tflock`.
- **Segurança:** o estado contém senhas geradas pelo Terraform. Por isso o bucket é privado, versionado, criptografado e só aceita TLS.

```bash
# Cria o bucket; fora da us-east-1 o LocationConstraint é obrigatório (na us-east-1, remova a opção)
aws s3api create-bucket --bucket "$BUCKET" --region "$REGIAO" --create-bucket-configuration LocationConstraint="$REGIAO"
# Liga o versionamento, que permite recuperar um estado corrompido
aws s3api put-bucket-versioning --bucket "$BUCKET" --versioning-configuration Status=Enabled
# Liga a criptografia padrão SSE-S3 (AES256) com Bucket Key
aws s3api put-bucket-encryption --bucket "$BUCKET" --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"},"BucketKeyEnabled":true}]}'
# Liga os 4 bloqueios de acesso público
aws s3api put-public-access-block --bucket "$BUCKET" --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
# Monta numa variável a policy que nega acesso sem TLS (o Principal "*" está dentro de um Deny, então só restringe)
POLITICA=$(printf '{"Version":"2012-10-17","Statement":[{"Sid":"DenyInsecureTransport","Effect":"Deny","Principal":"*","Action":"s3:*","Resource":["arn:aws:s3:::%s","arn:aws:s3:::%s/*"],"Condition":{"Bool":{"aws:SecureTransport":"false"}}}]}' "$BUCKET" "$BUCKET")
# Aplica a policy ao bucket
aws s3api put-bucket-policy --bucket "$BUCKET" --policy "$POLITICA"
# Confere o versionamento (esperado: "Status": "Enabled")
aws s3api get-bucket-versioning --bucket "$BUCKET"
```

---

## 4. Camada base

A base cria o que não depende do cluster: a VPC com 2 subnets públicas, 2 privadas e 1 NAT Gateway, os 5 repositórios ECR, a fila SQS `togglemaster-events` com DLQ, a tabela DynamoDB `ToggleMasterAnalytics`, a role do CI `togglemaster-github-actions` e o provedor OIDC do GitHub (criado ou só lido, conforme o tfvars). A base é preservável entre sessões, mas também pode ser destruída, e foi destruída em 2026-09-11 e em 2026-09-15.

```bash
# Baixa providers e módulos e conecta ao estado prod/base.tfstate no seu bucket
terraform -chdir=terraform init
# Planeja a base lendo terraform/terraform.tfvars e grava o plano em terraform/base.tfplan
terraform -chdir=terraform plan -out=base.tfplan
# Aplica exatamente o plano gravado, sem pergunta interativa
terraform -chdir=terraform apply base.tfplan
# Mostra a role do CI; precisa bater com o AWS_ROLE_ARN gravado nos workflows
terraform -chdir=terraform output -raw github_actions_role_arn
# Mostra a URL da fila; precisa bater com o AWS_SQS_URL do endpoints.yaml
terraform -chdir=terraform output -raw sqs_queue_url
# Mostra as URLs dos 5 repositórios; o prefixo precisa bater com o ECR_REGISTRY dos workflows
terraform -chdir=terraform output ecr_repository_urls
```

- **Número de recursos:** 35 com `create_github_oidc_provider=false` (2026-09-15); 36 com `true`. Qualquer item em `to destroy` no primeiro plan significa estado errado: pare e confira o bucket.
- **Tempo:** o apply da base do zero não foi medido [INCERTO].
- **Armadilha:** recursos de fases anteriores com o mesmo nome na conta fazem o apply parar com `RepositoryAlreadyExists`, `QueueAlreadyExists` ou `ResourceInUseException`. Apague os antigos ou use outra conta e rode plan e apply de novo; um apply parcial não corrompe o estado.

---

## 5. Publicação das imagens no ECR

O cluster só consegue rodar imagens que existem no ECR, e o ECR nasce vazio. Quem publica é o pipeline de cada serviço.

**Regra do pipeline.** Os jobs `image` e `gitops` só rodam com `github.event_name == 'push'` e `github.ref == 'refs/heads/main'`. Push na `dev`, pull request e disparo manual (`workflow_dispatch`) rodam só as verificações e **não publicam nada**.

**Caminho padrão: levar o commit da [seção 2](#2-valores-fixos-a-trocar-em-outra-conta) para a `main`.** Ele altera `_ci-go.yml` e `_ci-python.yml`, e pelos filtros de caminho isso dispara os 5 pipelines. Cada um compila, analisa, faz o scan da imagem, publica `v1.0.0-<sha7>` e comita a tag no overlay. Faça isso **só depois do apply da base**.

```bash
# Vai para a main local
git switch main
# Traz a main do GitHub (o robô pode ter comitado nela)
git pull --ff-only origin main
# Junta a dev na main sem abrir editor
git merge --no-edit dev
# Envia; este push dispara os 5 pipelines que publicam
git push origin main
# Lista os últimos runs da main; espere os 5 serviços em completed/success
gh run list --repo "$REPO" --branch main --limit 10
```

Para acompanhar um run específico, use `gh run watch <id> --repo "$REPO"`. Em 2026-09-15, o pipeline do flag-service levou cerca de 2 minutos entre o merge e o commit do robô. Você pode começar a [seção 6](#6-camada-cluster-e-endpoints-do-overlay) enquanto os pipelines rodam: o cluster não precisa das imagens, só os pods. Se não houver mudança nos workflows, qualquer commit na `main` que toque os `_ci-*.yml` ou `services/<serviço>/**` também publica.

**Caminho B, com restrições: re-executar runs antigos.** Serve só na mesma conta e com os mesmos workflows, e foi o usado pelo grupo em 2026-09-15 ([commit 3a193c4](https://github.com/fiap-devops-arqcloud-2026/tech-challenge-03/commit/3a193c4)). Avisos: o GitHub só re-executa runs recentes, cerca de 30 dias [INCERTO]; o re-run usa o workflow e o `.trivyignore` do commit antigo; e o job de GitOps grava a tag daquele commit, podendo rebaixar uma tag mais nova.

```bash
# Para cada serviço, re-executa o último run de push na main (sem --failed, para repetir também os portões de segurança)
for svc in auth-service evaluation-service flag-service targeting-service analytics-service; do id=$(gh run list --repo "$REPO" --workflow "$svc.yml" --branch main --event push --limit 1 --json databaseId --jq '.[0].databaseId'); echo "$svc -> run $id"; gh run rerun "$id" --repo "$REPO"; done
```

**Conferência antes de seguir.**

```bash
# Traz para a main local os commits de tag feitos pelo robô
git pull --ff-only origin main
# Mostra as tags que o overlay espera
grep newTag gitops/overlays/prod/kustomization.yaml
# Lista as tags publicadas em cada repositório; cada uma precisa conter a tag do overlay
for r in auth-service evaluation-service flag-service targeting-service analytics-service; do echo "$r: $(aws ecr describe-images --region "$REGIAO" --repository-name "$r" --query 'imageDetails[].imageTags[]' --output text)"; done
```

**Aplicar a camada k8s antes disso deixa os pods em `ImagePullBackOff`.**

---

## 6. Camada cluster e endpoints do overlay

A camada cluster cria o que cobra por hora: EKS com 2 nós, 2 RDS PostgreSQL, ElastiCache Redis e as roles IRSA dos pods. Depois do apply, o endereço do Redis vai para o overlay.

```bash
# Conecta ao estado prod/cluster.tfstate (lê a base por remote state)
terraform -chdir=terraform/cluster init
# Planeja EKS, nós, RDS, ElastiCache e IRSA e grava o plano
terraform -chdir=terraform/cluster plan -out=cluster.tfplan
# Aplica o plano gravado; a partir daqui o custo por hora é o da estimativa
terraform -chdir=terraform/cluster apply cluster.tfplan
```

- **Tempo:** 15m42s (2026-09-11).
- **Número de recursos:** 35 (contados no destroy de 2026-09-15).

**Endpoints do overlay.**

```bash
# Lê o endereço do Redis criado agora
REDIS=$(terraform -chdir=terraform/cluster output -raw redis_url)
# Mostra o endereço para conferir
echo "$REDIS"
# Mostra os ARNs das roles IRSA; precisam bater com os de irsa.yaml
terraform -chdir=terraform/cluster output irsa_role_arns
# Mostra os ARNs gravados no overlay
grep role-arn gitops/overlays/prod/patches/irsa.yaml
# Volta para a dev
git switch dev
# Traz para a dev o que já está na main (tags do robô e o merge da seção 5)
git merge --no-edit main
# Troca o REDIS_URL antigo pelo endereço novo
sed -i "s|redis://togglemaster-redis.*:6379|$REDIS|" gitops/overlays/prod/patches/endpoints.yaml
# Confere a linha resultante
grep REDIS_URL gitops/overlays/prod/patches/endpoints.yaml
# Adiciona só este arquivo
git add gitops/overlays/prod/patches/endpoints.yaml
# Registra o endereço do Redis
git commit -m "chore(gitops): endpoint do Redis da nova conta"
# Envia para a dev (gitops/** não está em nenhum filtro de pipeline de serviço)
git push origin dev
# Vai para a main
git switch main
# Traz a main do GitHub antes de juntar
git pull --ff-only origin main
# Junta a dev na main
git merge --no-edit dev
# Envia para a main, que é o que o ArgoCD lê
git push origin main
```

**PASSO BLOQUEANTE.** Só avance para a [seção 7](#7-camada-k8s-e-argocd) quando o comando abaixo mostrar o endereço novo:

```bash
# Baixa o estado atual do GitHub
git fetch origin
# Mostra o REDIS_URL que está de fato na main remota
git show origin/main:gitops/overlays/prod/patches/endpoints.yaml | grep REDIS_URL
```

**Acesso ao cluster.**

```bash
# Confere que o principal é o mesmo que aplicou o cluster (compare o Arn com o da seção 1)
aws sts get-caller-identity
# Grava no kubeconfig o acesso ao cluster novo; sem isto o kubectl continua apontando para um endpoint antigo
aws eks update-kubeconfig --region "$REGIAO" --name togglemaster
# Lista os nós (esperado: 2 nós em Ready)
kubectl get nodes
```

---

## 7. Camada k8s e ArgoCD

A camada k8s cria dentro do cluster os 2 namespaces, os 5 Secrets, a StorageClass `gp3`, o ArgoCD (chart 7.7.11) e a Application que aponta para o Git. A partir daí, o ArgoCD aplica sozinho os manifestos de `gitops/overlays/prod`.

**Só para repositório privado.** Crie no GitHub um token *fine-grained* com **Resource owner** igual ao dono do repositório (a organização, se for o caso), acesso só ao repositório da cópia e permissão **Contents: Read-only**. Com repositório público, inclusive fork, pule este bloco: o Secret de credencial nem é criado.

```bash
# Lê o token sem mostrar na tela e sem gravar no histórico do shell
read -rs TF_VAR_github_token
# Exporta para o Terraform, que lê TF_VAR_<nome> como a variável github_token
export TF_VAR_github_token
```

**Duas etapas, nesta ordem.** A Application é de um tipo (CRD) que só existe depois de o chart do ArgoCD ser instalado, e o Terraform valida esse tipo já no `plan`. Um plan completo num cluster novo falha com `no matches for kind "Application"`.

```bash
# Conecta ao estado prod/k8s.tfstate
terraform -chdir=terraform/k8s init
# Etapa A: planeja só o ArgoCD, que instala o CRD Application
terraform -chdir=terraform/k8s plan -target=helm_release.argocd -out=k8s-a.tfplan
# Aplica a etapa A (o aviso sobre -target é esperado)
terraform -chdir=terraform/k8s apply k8s-a.tfplan
# Etapa B: com o CRD existindo, planeja o restante (Secrets, StorageClass e Application)
terraform -chdir=terraform/k8s plan -out=k8s-b.tfplan
# Aplica a etapa B
terraform -chdir=terraform/k8s apply k8s-b.tfplan
```

- **Tempo:** 4m44s somando as duas etapas (2026-09-11).
- **Número de recursos:** 13 com o token vazio, contados no destroy de 2026-09-15.

```bash
# Mostra o comando de port-forward da interface do ArgoCD
terraform -chdir=terraform/k8s output -raw argocd_port_forward
# Estado da Application (esperado em 1 a 2 minutos: Synced / Healthy)
kubectl get application togglemaster -n argocd -o jsonpath='{.status.sync.status} / {.status.health.status}'
# Lista os pods; espere os 5 serviços e o postgres-targeting-0 em Running com READY 1/1
kubectl get pods -n togglemaster
```

**Interface do ArgoCD.** Não há Ingress nem Load Balancer: o acesso é por túnel local. O comando abaixo trava a janela, então abra outra e rode nela o bloco de variáveis da [seção 0](#0-antes-de-começar).

```bash
# Abre o túnel até o argocd-server; acesse http://localhost:8080 com o usuário admin
kubectl port-forward svc/argocd-server -n argocd 8080:80
```

```bash
# Lê a senha inicial do admin, guardada pelo chart num Secret, e decodifica de base64
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
```

---

## 8. Schemas, chave de serviço e dados de exemplo

**Pods Running e ArgoCD Healthy não provam que há tabelas: o `/health` não consulta o banco. Sem esta seção, as chamadas reais devolvem erro.**

O Terraform cria as instâncias RDS e os bancos vazios. As tabelas estão em `services/auth-service/db/init.sql` e `services/flag-service/db/init.sql`, e na AWS ninguém as executa sozinho. O banco do targeting é exceção: roda em pod, e o schema entra por ConfigMap na primeira subida.

**Schemas.** O RDS fica em subnet privada, então o `psql` roda dentro do cluster, num pod descartável. A URL de conexão já está no Secret de cada serviço.

```bash
# Lê do Secret a URL de conexão do banco do auth, sem mostrar a senha
AUTH_DB=$(kubectl get secret auth-service-secret -n togglemaster -o jsonpath='{.data.DATABASE_URL}' | base64 -d)
# Lê do Secret a URL de conexão do banco do flag
FLAG_DB=$(kubectl get secret flag-service-secret -n togglemaster -o jsonpath='{.data.DATABASE_URL}' | base64 -d)
# Sobe um pod temporário com psql, executa o init.sql do auth enviado da sua máquina e apaga o pod
kubectl run psql-auth --rm -i --restart=Never -n togglemaster --image=postgres:16-alpine -- psql "$AUTH_DB" < services/auth-service/db/init.sql
# Mesmo processo para o banco do flag
kubectl run psql-flag --rm -i --restart=Never -n togglemaster --image=postgres:16-alpine -- psql "$FLAG_DB" < services/flag-service/db/init.sql
# Lista as tabelas do auth (esperado: api_keys)
kubectl run psql-check-auth --rm -i --restart=Never -n togglemaster --image=postgres:16-alpine -- psql "$AUTH_DB" -c "\dt" < /dev/null
# Lista as tabelas do flag (esperado: flags)
kubectl run psql-check-flag --rm -i --restart=Never -n togglemaster --image=postgres:16-alpine -- psql "$FLAG_DB" -c "\dt" < /dev/null
```

Os dois `init.sql` usam `CREATE TABLE IF NOT EXISTS`, então rodar de novo não quebra nada.

**Túneis.** Abra três janelas novas, rode o bloco de variáveis da [seção 0](#0-antes-de-começar) em cada uma e deixe um túnel por janela:

```bash
# Janela de túnel 1: porta 8001 até o auth-service
kubectl port-forward svc/auth-service -n togglemaster 8001:8001
```

```bash
# Janela de túnel 2: porta 8002 até o flag-service
kubectl port-forward svc/flag-service -n togglemaster 8002:8002
```

```bash
# Janela de túnel 3: porta 8003 até o targeting-service
kubectl port-forward svc/targeting-service -n togglemaster 8003:8003
```

**Chave de serviço.** O `SERVICE_API_KEY` do Secret do evaluation nasce com um valor provisório gerado pelo Terraform, que não existe no banco. É preciso criar uma chave real no auth-service e gravá-la no Secret. O Secret declara `ignore_changes`, então o Terraform não desfaz essa troca nos próximos applies. Rode tudo abaixo **na mesma janela**, porque a variável `CHAVE` só existe nela.

```bash
# Lê do Secret a chave administrativa do auth-service
MASTER=$(kubectl get secret auth-service-secret -n togglemaster -o jsonpath='{.data.MASTER_KEY}' | base64 -d)
# Guarda o corpo da requisição numa variável
CORPO='{"name":"demo-fase3"}'
# Cria a chave de API e guarda só o campo "key" da resposta (ela é devolvida uma única vez)
CHAVE=$(curl -s -X POST http://localhost:8001/admin/keys -H "Content-Type: application/json" -H "Authorization: Bearer $MASTER" -d "$CORPO" | sed -E 's/.*"key":"([^"]+)".*/\1/')
# Mostra só o começo da chave (esperado: tm_key_ seguido de caracteres)
echo "${CHAVE:0:12}..."
# Substitui o valor provisório pelo real (esperado: secret/evaluation-service-secret configured)
kubectl create secret generic evaluation-service-secret -n togglemaster --from-literal=SERVICE_API_KEY="$CHAVE" --dry-run=client -o yaml | kubectl apply -f -
# Reinicia o evaluation-service para ele ler a chave nova
kubectl rollout restart deployment/evaluation-service -n togglemaster
# Espera o pod novo ficar pronto
kubectl rollout status deployment/evaluation-service -n togglemaster
```

**Dados de exemplo.** O evaluation só implementa regras do tipo `PERCENTAGE`. Com `value` 100, o resultado é sempre `true`.

```bash
# Corpo da flag novo-painel, ligada
FLAG='{"name":"novo-painel","description":"Painel novo","is_enabled":true}'
# Cria a flag no flag-service (esperado: JSON com "novo-painel")
curl -s -X POST http://localhost:8002/flags -H "Content-Type: application/json" -H "Authorization: Bearer $CHAVE" -d "$FLAG"
# Corpo da regra de 100% para a mesma flag
REGRA='{"flag_name":"novo-painel","is_enabled":true,"rules":{"type":"PERCENTAGE","value":100}}'
# Cria a regra no targeting-service
curl -s -X POST http://localhost:8003/rules -H "Content-Type: application/json" -H "Authorization: Bearer $CHAVE" -d "$REGRA"
```

---

## 9. Verificação ponta a ponta

Esta seção prova, com comandos, que cada peça funciona: pods, métricas, banco, cache, fila, DynamoDB e ArgoCD.

Abra mais uma janela para o túnel do evaluation, **depois** do rollout da [seção 8](#8-schemas-chave-de-serviço-e-dados-de-exemplo):

```bash
# Janela de túnel 4: porta 8004 até o evaluation-service
kubectl port-forward svc/evaluation-service -n togglemaster 8004:8004
```

Na janela onde a variável `CHAVE` existe:

```bash
# Pods: 5 serviços e o postgres-targeting-0 em Running com READY 1/1
kubectl get pods -n togglemaster
# HPAs do evaluation e do analytics com percentual em TARGETS (<unknown> por cerca de 2 minutos é normal)
kubectl get hpa -n togglemaster
# Chamada autenticada que lê do banco: prova de que o schema do flag existe (esperado: lista com novo-painel)
curl -s -H "Authorization: Bearer $CHAVE" http://localhost:8002/flags
# Avalia a flag sem cabeçalho de autorização: /evaluate é aberto (esperado: "result": true)
curl -s "http://localhost:8004/evaluate?flag_name=novo-painel&user_id=user-123"
# Repete a mesma avaliação; em até 30 segundos a resposta vem do cache Redis
curl -s "http://localhost:8004/evaluate?flag_name=novo-painel&user_id=user-123"
# Mostra o log do evaluation (esperado: Cache MISS e depois Cache HIT para novo-painel)
kubectl logs deployment/evaluation-service -n togglemaster --tail=5
# Conta os eventos gravados pelo analytics no DynamoDB (esperado: Count maior que 0)
aws dynamodb scan --table-name ToggleMasterAnalytics --region "$REGIAO" --select COUNT
# Lê a URL da fila na saída da base
FILA=$(terraform -chdir=terraform output -raw sqs_queue_url)
# Mostra as mensagens pendentes na fila (esperado: perto de 0, porque o analytics consome)
aws sqs get-queue-attributes --queue-url "$FILA" --attribute-names ApproximateNumberOfMessages ApproximateNumberOfMessagesNotVisible --region "$REGIAO"
# Estado final da Application (esperado: Synced / Healthy)
kubectl get application togglemaster -n argocd -o jsonpath='{.status.sync.status} / {.status.health.status}'
```

Na interface do ArgoCD ([seção 7](#7-camada-k8s-e-argocd)), a Application `togglemaster` deve aparecer em **Synced** e **Healthy**, com os 5 Deployments na árvore. Se o `/evaluate` responder 502 e o log do pod mostrar 401, a chave do Secret não confere com a do banco: refaça o bloco da chave de serviço da [seção 8](#8-schemas-chave-de-serviço-e-dados-de-exemplo).

---

## 10. Destruição e checagem de custo

Destrua na ordem inversa da criação: k8s, cluster, base. Cada camada lê o estado da anterior, e o destroy também precisa dessa leitura. O tfvars de cada pasta garante que o destroy use os mesmos valores do apply, inclusive o `create_github_oidc_provider`. Antes, feche os túneis com `Ctrl+C`.

```bash
# Planeja a destruição da camada k8s (esperado: 0 to add, 0 to change e 13 to destroy com token vazio)
terraform -chdir=terraform/k8s plan -destroy -out=destroy-k8s.tfplan
# Executa a destruição planejada da camada k8s
terraform -chdir=terraform/k8s apply destroy-k8s.tfplan
# Planeja a destruição do cluster, dos bancos, do Redis e das roles IRSA
terraform -chdir=terraform/cluster plan -destroy -out=destroy-cluster.tfplan
# Executa a destruição planejada do cluster
terraform -chdir=terraform/cluster apply destroy-cluster.tfplan
# Planeja a destruição da base
terraform -chdir=terraform plan -destroy -out=destroy-base.tfplan
# Procura o provedor OIDC entre os recursos a destruir; com OIDC=false não pode aparecer nenhuma linha
terraform -chdir=terraform show -no-color destroy-base.tfplan | grep "openid_connect_provider.*will be destroyed"
# Executa a destruição da base: VPC, NAT, ECR com as imagens, SQS, DynamoDB e IAM do CI
terraform -chdir=terraform apply destroy-base.tfplan
```

Se o `grep` listar o provedor e ele pertencer a outro projeto, **não aplique**: corrija `create_github_oidc_provider` no tfvars e planeje de novo. Um provedor reaproveitado (`false`) é só lido e nunca destruído.

**Tempos medidos em 2026-09-15**

| Camada | Recursos | Tempo |
|---|---|---|
| k8s | 13 | 1m04s |
| cluster | 35 | RDS cerca de 2 min, EKS cerca de 3 min, ElastiCache 4m17s |
| base | 35 | 1m40s |

Destruir a camada k8s antes do cluster remove o PVC, e o driver EBS apaga o disco de 5 GB do banco do targeting, porque a StorageClass usa `reclaim_policy = Delete`. É o comportamento desejado: esse disco não pertence a nenhum estado do Terraform e ficaria cobrando sozinho.

**Checagem de sobras.** Todas as saídas abaixo devem vir vazias.

```bash
# Clusters EKS
aws eks list-clusters --region "$REGIAO"
# Instâncias RDS
aws rds describe-db-instances --region "$REGIAO" --query "DBInstances[].DBInstanceIdentifier"
# Redis (o projeto cria um replication group)
aws elasticache describe-replication-groups --region "$REGIAO" --query "ReplicationGroups[].ReplicationGroupId"
# NAT Gateways ainda ligados
aws ec2 describe-nat-gateways --region "$REGIAO" --query "NatGateways[?State=='available'].NatGatewayId"
# Discos EBS soltos, que cobram mesmo sem instância
aws ec2 describe-volumes --region "$REGIAO" --filters Name=status,Values=available --query "Volumes[].VolumeId"
# Load Balancers (o projeto não cria nenhum; se aparecer, é sobra)
aws elbv2 describe-load-balancers --region "$REGIAO" --query "LoadBalancers[].LoadBalancerName"
# Endereços IPv4 públicos, que também cobram
aws ec2 describe-addresses --region "$REGIAO" --query "Addresses[].PublicIp"
# Log groups de RDS, que sem expiração acumulam custo de armazenamento
aws logs describe-log-groups --region "$REGIAO" --log-group-name-prefix /aws/rds --query "logGroups[].logGroupName"
# Log groups de EKS
aws logs describe-log-groups --region "$REGIAO" --log-group-name-prefix /aws/eks --query "logGroups[].logGroupName"
# Segredos no Secrets Manager (os do projeto usam recovery_window_in_days = 0 e somem na hora)
aws secretsmanager list-secrets --region "$REGIAO" --query "SecretList[].Name"
# Qualquer recurso ainda marcado com as tags do projeto
aws resourcegroupstaggingapi get-resources --region "$REGIAO" --tag-filters Key=project,Values=fiap Key=phase,Values=3 --query "ResourceTagMappingList[].ResourceARN"
```

A API de tags pode demorar a refletir exclusões recentes [INCERTO]; confirme cada ARN listado no serviço dele.

**O bucket de estado fica fora do Terraform.** Ele custa frações de centavo. Apagá-lo exige remover todas as versões de todos os objetos, o que é **exclusão permanente** e perde o histórico dos estados. Faça pelo console, só quando não houver mais recriação.

---

## 11. Armadilhas conhecidas

| Sintoma | Causa | Como evitar |
|---|---|---|
| Erro de parser com `&&`, ou `\` tratado como argumento | PowerShell 5.1 não aceita `&&` nem continuação com barra invertida | Rodar os blocos no Git Bash |
| Um bloco colado "responde" sozinho ao `terraform apply` | Apply interativo: a linha seguinte do bloco vira a resposta do "yes" | Sempre `plan -out` e `apply <arquivo>.tfplan` |
| Apply da base para com `EntityAlreadyExists` no provedor OIDC, e o plan não avisou | A conta já tem `token.actions.githubusercontent.com`; o plan só compara com o estado | `create_github_oidc_provider = false` no tfvars da base ([seção 2](#2-valores-fixos-a-trocar-em-outra-conta)) |
| Plan da base falha no data source do provedor OIDC | `false` numa conta que não tem o provedor | Trocar para `true` e planejar de novo (36 recursos) |
| Todos os pods em `ImagePullBackOff` com as imagens no ECR | Base aplicada a partir do `terraform.tfvars.example`, que desliga o NAT | `enable_nat_gateway = true` e apply da base |
| Todos os pods em `ImagePullBackOff` logo após recriar | ECR vazio, ou camada k8s aplicada antes das imagens | [Seção 5](#5-publicação-das-imagens-no-ecr); depois `kubectl delete pod -n togglemaster <pod>` para baixar na hora |
| Disparo manual pela aba Actions não publica imagem | `workflow_dispatch` não satisfaz a condição dos jobs `image` e `gitops` | Commit na `main` ([seção 5](#5-publicação-das-imagens-no-ecr)) |
| `gh run rerun` recusado | Run antigo demais para re-execução | Caminho padrão: commit na `main` |
| Job de imagem falha em `Could not assume role with OIDC` | Role inexistente (base não aplicada), `AWS_ROLE_ARN` de outra conta ou `github_repository` diferente da cópia | Terminar a base; conferir a Tabela 1 e o tfvars; novo commit na `main` |
| Scan barra a imagem por CVE crítica nova, sem mudança no código | Imagem base ou dependência ganhou CVE depois de 2026-09-15 | Corrigir a dependência, ou registrar a exceção nominal no `.trivyignore` com data e motivo, e publicar por commit na `main` (o re-run usa o arquivo antigo) |
| `kubectl` responde `Unauthorized` ou `You must be logged in to the server` | Perfil AWS diferente do principal que criou o cluster | `aws sts get-caller-identity` e usar o mesmo `AWS_PROFILE` |
| `kubectl` tenta conectar num endereço que não existe mais | kubeconfig ainda aponta para um cluster antigo | `aws eks update-kubeconfig --region "$REGIAO" --name togglemaster` |
| evaluation em `CrashLoopBackOff`, ou analytics com `AccessDenied` | Overlay com `REDIS_URL`, fila ou ARNs de outra conta, ou commit ainda fora da `origin/main` | Passo bloqueante da [seção 6](#6-camada-cluster-e-endpoints-do-overlay) |
| Job de GitOps falha depois de 5 tentativas | Proteção de branch ou ruleset bloqueia o push do `github-actions[bot]` na `main` | Liberar o bot na proteção da `main` da cópia |
| Nenhum workflow roda no fork | Actions vêm desligadas em fork | Habilitar na aba Actions |
| `gh` age no repositório original em vez do fork | O fork clonado tem o remoto `upstream` | Passar `--repo "$REPO"` nos comandos `gh` |
| Plan da camada k8s falha com `no matches for kind "Application"` | CRD do ArgoCD ainda não existe | Etapa A com `-target=helm_release.argocd` antes ([seção 7](#7-camada-k8s-e-argocd)) |
| ArgoCD em `Unknown` com `authentication required` | Cópia privada sem token | `TF_VAR_github_token` antes da etapa A ([seção 7](#7-camada-k8s-e-argocd)) |
| HPA com `<unknown>` em TARGETS | metrics-server ainda inicializando | Aguardar cerca de 2 minutos |
| `kubectl kustomize` não tem `edit` | O subcomando `edit` só existe no kustomize autônomo | Usar o binário `kustomize` (o CI instala a 5.4.3) |
| Pods Healthy, mas o primeiro INSERT falha com `relation ... does not exist` | Schemas nunca aplicados no RDS | [Seção 8](#8-schemas-chave-de-serviço-e-dados-de-exemplo) |
| `/evaluate` responde 502 e o log mostra 401 | `SERVICE_API_KEY` ainda é o valor provisório | Bloco da chave de serviço da [seção 8](#8-schemas-chave-de-serviço-e-dados-de-exemplo) |
| `/evaluate` responde 400 | Parâmetros com nome errado | Usar `flag_name` e `user_id` |
| Trivy local não acusa o que o CI acusa | Observado localmente em 2026-09-15: o Trivy 0.74 não leu pacotes listados depois de `setuptools<81` e `Werkzeug<3`; o CI usa o Trivy v0.70.0 | Testar com a mesma versão do CI e, na demonstração, inserir a dependência na primeira linha |
| Arquivos não revisados entram num commit | `git add` de tudo | Listar os caminhos no `git add` |
| `git merge --ff-only` ou `git push` recusados na `main` | A `main` anda sozinha: o robô comita as tags nela | `git pull` antes de cada commit; usar `git merge --no-edit` |
| `QueueDeletedRecently` ao recriar a base | Fila SQS recriada em menos de 60 segundos | Esperar 1 minuto e planejar de novo |
| `RepositoryAlreadyExists` ou `ResourceInUseException` no apply da base | Recursos de fases anteriores com o mesmo nome na conta | Apagar os antigos e rodar plan e apply de novo |

Recriar logo depois de um destroy não esbarra em segredo antigo: os segredos do Secrets Manager usam `recovery_window_in_days = 0` e são apagados na hora, então o mesmo nome pode ser recriado.

---

## Apêndice A. Execução local com Docker Compose

Sem AWS, sem custo e sem credencial: os 5 serviços, 2 PostgreSQL, Redis e DynamoDB Local na sua máquina.

**Portas que precisam estar livres:** 8001 a 8005 (serviços), 5433 (postgres-auth), 5434 (postgres-app), 6379 (Redis) e 8000 (DynamoDB Local).

```bash
# Copia o modelo de variáveis locais; o .env.example só tem valores locais e fictícios
cp .env.example .env
# Constrói as 5 imagens e sobe tudo em segundo plano
docker compose up --build -d
# Confere se os contêineres ficaram saudáveis (o dynamodb-local não tem healthcheck)
docker compose ps
# Verifica o health do auth-service; repita nas portas 8002 a 8005
curl http://localhost:8001/health
```

**Chave de serviço local.** O `SERVICE_API_KEY` começa vazio: a chave precisa existir no banco local recém-criado.

```bash
# Corpo da requisição que cria a chave
CORPO='{"name":"evaluation-local"}'
# Cria a chave com a MASTER_KEY local do .env.example e guarda só o campo "key"
CHAVE=$(curl -s -X POST http://localhost:8001/admin/keys -H "Content-Type: application/json" -H "Authorization: Bearer local-master-key-change-me" -d "$CORPO" | sed -E 's/.*"key":"([^"]+)".*/\1/')
# Grava a chave no .env, na linha SERVICE_API_KEY
sed -i "s/^SERVICE_API_KEY=.*/SERVICE_API_KEY=$CHAVE/" .env
# Recria só o evaluation para ele ler a variável nova
docker compose up -d --force-recreate evaluation-service
```

Para cadastrar flag e regra, use os mesmos `curl` da [seção 8](#8-schemas-chave-de-serviço-e-dados-de-exemplo), nas portas 8002 e 8003 locais. Depois de `docker compose down -v` os bancos somem junto com a chave: refaça este bloco.

**Limitação.** No Compose padrão a SQS fica desligada (`AWS_SQS_URL` vazio): o evaluation só registra um aviso, o worker do analytics não sobe e nada chega ao DynamoDB Local.

**Teste integrado.** É o mesmo teste do workflow Compose Integration. Ele sobe o simulador Moto (SQS e DynamoDB) e exercita o fluxo completo, inclusive a fila. Precisa de `python3` no PATH, então no Windows rode pelo WSL.

```bash
# Sobe os 5 serviços com o Moto e executa o fluxo ponta a ponta
bash scripts/test-compose.sh
# Derruba o projeto de integração e apaga só os volumes dele
docker compose --env-file .env.example -p tc03-integration -f docker-compose.yaml -f docker-compose.integration.yaml down -v
```

---

## Apêndice B. Demonstração da falha de segurança e da sincronização do ArgoCD

Esta demonstração mostra o DevSecOps barrando uma dependência com CVE crítica, a correção passando e o ArgoCD aplicando a versão nova sozinho. **Só funciona com o ambiente de pé e a role do CI existindo** (seções 4 a 9).

**1. Colocar a dependência vulnerável, na `dev`.** Remova antes a linha atual da PyYAML: com duas versões no mesmo arquivo, o `pip` falharia no build e a demonstração mostraria o erro errado.

```bash
# Vai para a dev
git switch dev
# Baixa o estado do GitHub
git fetch origin
# Traz para a dev o que já está na main
git merge --no-edit origin/main
# Remove a linha atual da PyYAML do flag-service
sed -i '/^PyYAML==/d' services/flag-service/requirements.txt
# Insere a PyYAML 5.3.1, com CVE crítica, na primeira linha
sed -i '1i PyYAML==5.3.1' services/flag-service/requirements.txt
# Mostra o começo do arquivo (esperado: PyYAML==5.3.1 na primeira linha)
head -3 services/flag-service/requirements.txt
# Adiciona só este arquivo
git add services/flag-service/requirements.txt
# Registra a mudança
git commit -m "feat(flag-service): adiciona PyYAML 5.3.1"
# Envia para a dev; o pipeline do flag-service começa sozinho
git push origin dev
```

A primeira linha é precaução contra o comportamento do Trivy 0.74 observado localmente em 2026-09-15. No CI, com a linha no fim do arquivo, a falha foi detectada normalmente ([run 34985289399](https://github.com/fiap-devops-arqcloud-2026/tech-challenge-03/actions/runs/34985289399)).

**2. Acompanhar a falha.**

```bash
# Guarda o identificador do commit enviado
SHA=$(git rev-parse HEAD)
# Começa sem run encontrado
RUN=""
# Espera o GitHub criar o run deste commit, consultando a cada 5 segundos
until [ -n "$RUN" ]; do sleep 5; RUN=$(gh run list --repo "$REPO" --workflow flag-service.yml --commit "$SHA" --json databaseId --jq '.[0].databaseId // empty'); done
# Acompanha o run até o fim
gh run watch "$RUN" --repo "$REPO"
# Mostra a linha que barrou o pipeline (esperado: PyYAML, CVE-2020-14343, CRITICAL)
gh run view "$RUN" --repo "$REPO" --log-failed | grep -E "PyYAML|CVE-2020-14343"
```

Esperado: `SCA` vermelho, com os jobs de imagem e GitOps em `skipped`. Não faça outro push antes de o run terminar: fora da `main`, um push novo cancela o anterior.

**3. Corrigir.**

```bash
# Troca a versão vulnerável pela corrigida
sed -i 's/^PyYAML==5.3.1/PyYAML==6.0.1/' services/flag-service/requirements.txt
# Adiciona só este arquivo
git add services/flag-service/requirements.txt
# Registra a correção
git commit -m "fix(flag-service): atualiza PyYAML para 6.0.1 (CVE-2020-14343)"
# Envia para a dev; o pipeline roda de novo e fica verde, ainda sem publicar
git push origin dev
```

Em 2026-09-15 a correção ficou verde no [run 34985477955](https://github.com/fiap-devops-arqcloud-2026/tech-challenge-03/actions/runs/34985477955). Acompanhe com o mesmo bloco do passo 2.

**4. Levar para a `main` e ver o ArgoCD.** A mudança real em `services/flag-service/` faz o merge disparar o pipeline na `main`.

```bash
# Abre o pull request da dev para a main na sua cópia
gh pr create --repo "$REPO" --base main --head dev --title "fix(flag-service): atualiza PyYAML" --body "Correção de segurança demonstrada no pipeline."
# Faz o merge (nunca use --delete-branch, que apagaria a dev)
gh pr merge dev --repo "$REPO" --merge
# Baixa o commit de merge
git fetch origin
# Guarda o identificador do commit de merge
MERGE=$(git rev-parse origin/main)
# Mostra a tag que o pipeline vai publicar
echo "Tag esperada: v1.0.0-${MERGE:0:7}"
# Começa sem run encontrado
RUN=""
# Espera o run do flag-service para o commit de merge
until [ -n "$RUN" ]; do sleep 5; RUN=$(gh run list --repo "$REPO" --workflow flag-service.yml --commit "$MERGE" --json databaseId --jq '.[0].databaseId // empty'); done
# Acompanha até o fim (esperado: 6 jobs verdes, inclusive imagem e GitOps)
gh run watch "$RUN" --repo "$REPO"
# Baixa o commit do robô
git fetch origin
# Mostra os últimos commits (esperado no topo: chore(gitops): flag-service para v1.0.0-<sha7> [skip ci])
git --no-pager log origin/main --oneline -3
# Mostra a imagem que o flag-service usa agora (esperado: termina com a tag esperada)
kubectl get deploy flag-service -n togglemaster -o jsonpath='{.spec.template.spec.containers[0].image}'
```

Sem clicar em nada, o ArgoCD detecta o commit em até cerca de 30 segundos, porque a reconciliação foi configurada para 30s: a Application passa por `OutOfSync` e volta a `Synced` e `Healthy`. Em 2026-09-15 esse fluxo foi o [PR #16](https://github.com/fiap-devops-arqcloud-2026/tech-challenge-03/pull/16), o [run 34997028995](https://github.com/fiap-devops-arqcloud-2026/tech-challenge-03/actions/runs/34997028995) e o [commit a0c7b8e](https://github.com/fiap-devops-arqcloud-2026/tech-challenge-03/commit/a0c7b8e06f9e12da5bc838d64ead841e1f91072f) do robô.

**5. Prova de selfHeal.** Uma mudança feita à mão no cluster, fora do Git, é desfeita pelo ArgoCD.

```bash
# Escala o flag-service para 3 réplicas, contrariando o Git (que diz 1)
kubectl scale deploy/flag-service --replicas=3 -n togglemaster
# Observa o Deployment; em poucos segundos o ArgoCD volta para 1 réplica (Ctrl+C para sair)
kubectl get deploy flag-service -n togglemaster -w
```

Depois da demonstração, traga a `dev` para o ponto da `main` antes de voltar a trabalhar. Quando terminar, siga a [seção 10](#10-destruição-e-checagem-de-custo).
