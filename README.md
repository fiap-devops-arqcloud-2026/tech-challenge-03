<div align="center">

# 🚩 ToggleMaster — Fase 3

### Infraestrutura como Código, CI/CD, DevSecOps e GitOps

*A mesma aplicação da Fase 2 — mas agora nada é criado no console, e ninguém dá deploy pela própria máquina.*

[![Terraform](https://img.shields.io/badge/Terraform-1.16-7B42BC?logo=terraform&logoColor=white)](https://www.terraform.io/)
[![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-CI%2FCD-2088FF?logo=githubactions&logoColor=white)](https://github.com/features/actions)
[![ArgoCD](https://img.shields.io/badge/ArgoCD-GitOps-EF7B4D?logo=argo&logoColor=white)](https://argo-cd.readthedocs.io/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-EKS-326CE5?logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![AWS](https://img.shields.io/badge/AWS-EKS%20%7C%20RDS%20%7C%20ECR%20%7C%20SQS-FF9900?logo=amazonaws&logoColor=white)](https://aws.amazon.com/)

---

**Tech Challenge — Fase 3 | POSTECH FIAP | Grupo 203**

[📋 Enunciado](./docs/POSTECH%20-%20Tech%20Challenge%20-%20Fase%203.pdf) · [📦 Fase 2](https://github.com/fiap-devops-arqcloud-2026/tech-challenge-02) · [🏗️ Terraform](./terraform/) · [☸️ GitOps](./gitops/)

</div>

---

## 📑 Índice

- [O problema que a Fase 3 resolve](#-o-problema-que-a-fase-3-resolve)
- [Escopo: o obrigatório e o extra](#-escopo-o-obrigatório-e-o-extra)
- [Arquitetura](#️-arquitetura)
- [Tecnologias](#-tecnologias)
- [Estrutura do repositório](#-estrutura-do-repositório)
- [Problemas encontrados e como contornamos](#️-problemas-encontrados-e-como-contornamos)
- [Controle de custo](#-controle-de-custo)
- [Como reproduzir](#-como-reproduzir)
- [Estado atual](#-estado-atual)
- [Time](#-time)

---

## 💡 O problema que a Fase 3 resolve

Na Fase 2 o ToggleMaster ficou **funcionando** na AWS. Mas ele foi colocado lá **na mão**: cliques no console para criar cluster, bancos e filas; `docker push` manual; `kubectl apply` do notebook de quem estava com o terminal aberto.

O enunciado da Fase 3 descreve quatro dores concretas dessa operação:

| Dor descrita no enunciado | Como resolvemos |
|---|---|
| *"Desenvolvedores rodando `kubectl apply` de suas máquinas locais, gerando conflitos de versão"* | **GitOps com ArgoCD** — ninguém aplica nada. O Git é a fonte da verdade e o ArgoCD reconcilia o cluster |
| *"As credenciais do banco de dados estão sendo passadas em arquivos de texto sem segurança"* | **Nenhum segredo no Git.** Senhas geradas pelo Terraform e guardadas no AWS Secrets Manager; pods acessam a AWS por **IRSA**, sem chave estática |
| *"Uma vulnerabilidade em uma biblioteca Go passou despercebida e foi para produção"* | **Pipeline DevSecOps** com SCA, SAST e scan de imagem. Vulnerabilidade crítica **quebra o build** |
| *"Recriar o ambiente leva dias porque foi feito manualmente no console"* | **Terraform.** Um `apply` recria tudo; um `destroy` apaga tudo |

A frase-guia da fase é **"se não está no código, não existe"**.

> **E o que é o ToggleMaster?** Uma plataforma de *feature flags*: permite ligar e desligar funcionalidades de um app em tempo real, sem novo deploy. São 5 microsserviços — `auth`, `flag`, `targeting`, `evaluation` e `analytics`. A explicação completa da aplicação está no [README da Fase 2](https://github.com/fiap-devops-arqcloud-2026/tech-challenge-02).

---

## 🎯 Escopo: o obrigatório e o extra

O enunciado foi lido linha a linha e virou um checklist com **39 itens obrigatórios**. Esta seção existe para o grupo não se perder: **entregar o básico bem feito vale nota; enfeite não vale.**

O detalhamento item a item está em [`CHECKLIST_REQUISITOS_FASE3.md`](./docs/00_COLAB_IA/CHECKLIST_REQUISITOS_FASE3.md).

### ✅ Obrigatório — é isso que vale nota

| Bloco | O que o enunciado exige |
|---|---|
| **IaC** | VPC + subnets + IGW + route tables · EKS + node group · 3 RDS PostgreSQL · 1 ElastiCache · 1 DynamoDB `ToggleMasterAnalytics` · 1 fila SQS · estado remoto em S3 |
| **CI/DevSecOps** | Workflow por microsserviço · dispara em PR e push na `main` · build · linter · SCA · SAST · **vulnerabilidade crítica quebra o pipeline** · build da imagem · scan da imagem · push no ECR com tag do commit |
| **CD/GitOps** | Pasta com os manifestos · ArgoCD no EKS · CI atualiza a tag no repositório GitOps · ArgoCD sincroniza sozinho · **sem `kubectl apply` pelo CI** |
| **Entregáveis** | Vídeo até 20 min · código Terraform · workflows · manifestos · relatório com nomes, links, desafios e print de custos |

### ➕ Extras que adotamos — e por quê

Poucos, e cada um com justificativa direta numa dor do enunciado:

| Extra | Por que entrou mesmo assim |
|---|---|
| **OIDC no GitHub Actions** (S-01) | Sem ele, seria preciso guardar `AWS_ACCESS_KEY_ID` nos secrets do GitHub — exatamente a prática que o enunciado critica. Custo: ~40 linhas de Terraform, zero componente novo |
| **IRSA nos pods** (S-06) | Mesma coisa do lado do cluster: sem IRSA, as chaves da AWS voltam para dentro de um Secret do Kubernetes, como era na Fase 2 |
| **Secrets Manager** (S-02) | As senhas do RDS precisam existir em algum lugar. Gerá-las no Terraform e guardá-las lá custa o mesmo que qualquer alternativa |
| **DLQ na fila SQS** | 6 linhas. Sem ela, uma mensagem defeituosa volta para a fila para sempre |

### ❌ O que decidimos **não** fazer

| Deixado de fora | Motivo |
|---|---|
| **Ingress / Load Balancer** | O enunciado da Fase 3 **não menciona** ingress, load balancer nem acesso externo em nenhuma das 7 páginas. Economiza ~US$ 16–20/mês. No vídeo usamos `kubectl port-forward` |
| **Múltiplos ambientes** | Um só, chamado `prod`. Cada ambiente extra multiplicaria o custo de EKS, RDS e cache |
| **KEDA, DAST, Prowler, CloudTrail** | Sugestões das aulas, fora do enunciado |
| **Helm Charts próprios** | O enunciado aceita YAML ou Helm. Kustomize resolve com menos peça |
| **Multi-AZ, réplicas de leitura, WAF, CloudFront** | Nada disso vale nota |

---

## 🏗️ Arquitetura

O fluxo completo, do commit ao pod rodando:

```
   Desenvolvedor
        │  git push / abre PR
        ▼
   ┌─────────────────────────────────────────────┐
   │  GitHub Actions  (1 workflow por serviço)   │
   │                                             │
   │   build → linter → SCA → SAST → docker      │
   │                                  build      │
   │                                    ↓        │
   │                            scan da imagem   │
   │                                    ↓        │
   │        vulnerabilidade CRÍTICA = ❌ para    │
   └───────────────┬─────────────────────────────┘
                   │ autentica por OIDC (sem chave estática)
                   ▼
        ┌──────────────────────┐
        │  Amazon ECR          │  imagem com tag v1.0.0-<commit>
        └──────────────────────┘
                   │
                   │ último passo do CI:
                   │ kustomize edit set image
                   ▼
        ┌──────────────────────┐
        │  gitops/  (Git)      │  ← fonte da verdade
        └──────────┬───────────┘
                   │ ArgoCD observa e sincroniza
                   ▼
   ┌─────────────────────────────────────────────┐
   │  Amazon EKS                                 │
   │                                             │
   │   auth   flag   targeting   evaluation      │
   │                                 │  analytics│
   │   postgres-targeting (pod)      │      │    │
   └─────────────────────────────────┼──────┼────┘
                   │                 │      │
      ┌────────────┴──────┐          │      │
      ▼                   ▼          ▼      ▼
   2× RDS            ElastiCache    SQS → DynamoDB
   (auth, flags)     (cache)
```

Tudo isso — VPC, EKS, bancos, cache, fila, tabela, ECR e as roles IAM — nasce de `terraform apply`.

---

## 🔧 Tecnologias

| Camada | Ferramenta | Por que esta |
|---|---|---|
| IaC | **Terraform 1.16** | Exigido pelo enunciado. Estado remoto em S3 com `use_lockfile` |
| Módulos | `terraform-aws-modules/vpc` e `/eks` + módulos próprios | VPC e EKS escritos do zero consomem dias; RDS, ECR, SQS e IAM são simples e ficaram autorais |
| CI/CD | **GitHub Actions** | Já é onde o código vive |
| Segurança | **Trivy** (SCA + imagem), **gosec** (Go), **bandit** (Python) | Citados no enunciado, gratuitos |
| Registro | **Amazon ECR** | Exigido |
| GitOps | **Kustomize** + **ArgoCD** | Kustomize é nativo do `kubectl` e do ArgoCD, e o `kustomize edit set image` altera **um campo** — o pipeline não precisa fazer `sed` em YAML |
| Cluster | **Amazon EKS**, 2× `c7i-flex.large` | Ver [problemas](#️-problemas-encontrados-e-como-contornamos) |
| Dados | RDS PostgreSQL · ElastiCache Redis · DynamoDB · SQS | Exigidos |

**Aplicação:** Go (`auth`, `evaluation`) e Python (`flag`, `targeting`, `analytics`) — herdada da Fase 2, sem alteração de código.

---

## 📁 Estrutura do repositório

```text
tech-challenge-03/
├── services/               # código dos 5 microsserviços (cópia da Fase 2)
├── terraform/              # infraestrutura como código
│   ├── backend.tf          #   estado remoto no S3
│   ├── main.tf             #   composição dos módulos
│   ├── modules/            #   ecr · messaging · iam-ci
│   └── BOOTSTRAP-BACKEND-S3.md
├── gitops/                 # manifestos observados pelo ArgoCD
│   ├── base/               #   o que não muda entre ambientes
│   └── overlays/prod/      #   tags de imagem e endpoints da AWS
├── .github/workflows/      # pipelines de CI e DevSecOps
└── docs/
    ├── 00_COLAB_IA/        # checklist, decisões, pendências, log
    └── ...                 # enunciado e guias de estudo dos 5 módulos
```

---

## ⚠️ Problemas encontrados e como contornamos

Esta seção alimenta diretamente o relatório de entrega.

### 1. A AWS não deixa criar a 3ª instância RDS

O enunciado pede **3 RDS**. A conta está no plano gratuito novo da AWS, que recusa a terceira com o erro literal:

```
maximum number of instances available with free plan accounts
```

Não é limite de custo — é recusa da API.

**Como contornamos:** `auth_db` e `flags_db` ficam no RDS; o `targeting_db` roda como **StatefulSet PostgreSQL dentro do cluster**, com disco EBS persistente. Foi a mesma solução da Fase 2, e o **professor confirmou que segue aceita na Fase 3**.

### 2. A AWS não deixa lançar `t3.medium`

Ao criar o node group, o EC2 recusou:

```
The specified instance type is not eligible for Free Tier
```

O plano gratuito só permite tipos elegíveis ao Free Tier. E `t3.micro` é inviável: cabem ~4 pods por nó (os DaemonSets do sistema já ocupam) e só tem 1 GB de RAM.

**Como contornamos:** node group com **`c7i-flex.large`** (2 vCPU / 4 GB — equivalente direto da `t3.medium`), aceito pela conta. Custa cerca do dobro por hora, mas é o que funciona.

### 3. O disco do banco em pod ficava `Pending`

Na Fase 2, o PVC do `postgres-targeting` travou porque o cluster tinha a StorageClass `gp2` mas **nenhuma marcada como padrão**. O volume nunca era provisionado e o deploy parava ali, até alguém descobrir na mão.

**Como contornamos:** na Fase 3 o addon `aws-ebs-csi-driver` e uma StorageClass padrão **nascem do Terraform**. O problema deixa de depender de alguém lembrar.

### 4. Região errada na documentação herdada

Os READMEs de `analytics-service` e `evaluation-service`, copiados da Fase 2, trazem `AWS_REGION="us-east-1"` nos exemplos. A infraestrutura toda está em **`us-east-2` (Ohio)**. Quem copiasse aquelas linhas apontaria para a região errada.

**Como contornamos:** registrado como armadilha conhecida; a região correta está fixada no Terraform e nos ConfigMaps.

### 5. Conflito de versão entre provider e módulo

Fixar o provider AWS em `~> 6.0` gerava conflito insolúvel com a restrição interna do módulo de VPC da comunidade, travando o `terraform init`.

**Como contornamos:** restrição do provider como `>= 5.46`, **sem teto**, deixando o `.terraform.lock.hcl` — versionado no Git — travar a versão exata. Resolveu para provider 6.62.0 com módulo VPC 5.21.0.

---

## 💰 Controle de custo

A conta tem crédito limitado, então a infraestrutura **não fica de pé**.

| Recurso | US$/h |
|---|---|
| EKS control plane | 0,100 |
| 2× `c7i-flex.large` | 0,170 |
| NAT Gateway | 0,045 |
| 2× `db.t3.micro` | 0,036 |
| ElastiCache `t3.micro` | 0,017 |
| **Total com tudo ligado** | **~0,37** |

**Regra do projeto:** o cluster sobe apenas para ensaio e gravação — cerca de **3 horas por sessão**, e é destruído em seguida. Uma sessão custa ~US$ 1,10.

Recursos que ficam de pé permanentemente por custarem ~US$ 0: ECR, SQS, DynamoDB e o bucket de estado.

> Metade do vídeo **não precisa do cluster**: o pipeline falhando e passando (O-28/O-29) e a atualização da tag no GitOps (O-30) rodam inteiramente no GitHub Actions. Só o bloco do ArgoCD exige o EKS no ar.

---

## 🚀 Como reproduzir

```bash
# 1. Bucket de estado — uma única vez, fora do Terraform.
#    Passo a passo completo em terraform/BOOTSTRAP-BACKEND-S3.md

# 2. Infraestrutura
export AWS_PROFILE=togglemaster
cd terraform
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply

# 3. Conferir os manifestos antes de sincronizar
kubectl kustomize gitops/overlays/prod
```

O `terraform/README.md` detalha as etapas do apply e o porquê da divisão.

---

## 📌 Estado atual

| Entrega | Situação |
|---|---|
| Estado remoto em S3 (O-09) | ✅ bucket criado, `backend.tf` escrito |
| Rede, ECR, SQS, DynamoDB, OIDC (Etapa 1) | ✅ escrito e validado — ainda não aplicado |
| Manifestos GitOps (O-22, O-35) | ✅ escritos e validados com `kubectl kustomize` |
| EKS, RDS, ElastiCache, IRSA (Etapa 2) | ⏳ a escrever |
| ArgoCD (O-23) | ⏳ a escrever |
| Workflows de CI (O-10 a O-21) | ⏳ a escrever |
| Vídeo e relatório (O-27 a O-39) | ⏳ pendente |

Pendências e próximos passos: [`PENDENCIAS_E_PROXIMOS_PASSOS.md`](./docs/00_COLAB_IA/PENDENCIAS_E_PROXIMOS_PASSOS.md).

---

## 👥 Time

Projeto desenvolvido para a **Fase 3 do Tech Challenge** da pós-graduação em **DevOps e Arquitetura Cloud** — POSTECH FIAP.

**Grupo 203:**

| Integrante | RM | GitHub |
|---|---|---|
| Gabriel Pinelli Silva | RM373763 | [@Tocaccelli](https://github.com/Tocaccelli) |
| João Vitor de Jesus Ciardullo | RM372155 | [@joaociardullo](https://github.com/joaociardullo) |
| Douglas Deveza dos Santos | RM373827 | [@Douglasdeveza](https://github.com/Douglasdeveza) |
| João Carlos da Silva Brito | RM371738 | [@Durmiand](https://github.com/Durmiand) |
| João Gabriel da Cruz Sales | RM372444 | [@jgabrieldev1](https://github.com/jgabrieldev1) |

---

<div align="center">

Se não está no código, não existe.

</div>
