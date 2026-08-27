# CHECKLIST_REQUISITOS_FASE3

TL;DR: checklist extraido do enunciado `docs/POSTECH - Tech Challenge - Fase 3.pdf`. Separa o que e OBRIGATORIO (vale nota), o que o enunciado marcou como opcional/recomendado e o que e sugestao dos modulos de aula. Entrega em grupo, prazo final 2026-09-15. Em 2026-08-27 a implementacao comecou: os 5 microsservicos ja estao em `services/`; o restante segue pendente.

Ultima atualizacao: 2026-08-27 19:50 -03:00, Claude.

Prazo final: 2026-09-15. Modalidade: entrega em grupo (D-006).

Fonte unica desta lista: paginas 2 a 6 do PDF do enunciado. Itens fora do PDF estao na secao 4 e marcados como sugestao propria.

---

## 1. OBRIGATORIO - Requisitos tecnicos

### 1.1 Infraestrutura como Codigo (Terraform)

- [ ] O-01 Projeto Terraform substituindo a criacao manual da Fase 2.
- [ ] O-02 Networking: VPC, subnets publicas, subnets privadas, Internet Gateway e Route Tables.
- [ ] O-03 Cluster EKS provisionado por Terraform.
- [ ] O-04 Node Groups do EKS provisionados por Terraform.
- [ ] O-05 3 instancias RDS PostgreSQL.
- [ ] O-06 1 cluster ElastiCache (Redis).
- [ ] O-07 1 tabela DynamoDB chamada `ToggleMasterAnalytics` (nome literal do enunciado).
- [ ] O-08 1 fila SQS.
- [~] O-09 Backend remoto em bucket S3; `terraform.tfstate` nao pode ficar local. Bucket criado em 2026-08-27 (`togglemaster-tfstate-891376952395-us-east-2-an`); falta o bloco `backend "s3"` em `terraform/backend.tf`.

### 1.2 Pipeline de CI e DevSecOps

- [ ] O-10 Workflow de CI para cada um dos 5 microsservicos (`auth`, `flag`, `targeting`, `evaluation`, `analytics`).
- [ ] O-11 Gatilho em Pull Request e em push na `main`.
- [ ] O-12 Job Build (compilar/empacotar o codigo).
- [ ] O-13 Job Linter / analise estatica (ex.: `golangci-lint` para Go, `pylint`/`flake8` para Python).
- [ ] O-14 Job SCA - vulnerabilidade em dependencias (ex.: Trivy modo `fs` ou OWASP Dependency Check).
- [ ] O-15 Job SAST - vulnerabilidade no codigo fonte (ex.: SonarCloud gratuito, `gosec`, `bandit`).
- [ ] O-16 Regra de bloqueio: vulnerabilidade CRITICA faz o pipeline falhar e nao prosseguir.
- [ ] O-17 Build da imagem Docker.
- [ ] O-18 Scan de vulnerabilidade na imagem (container scan com Trivy).
- [ ] O-19 Login no AWS ECR pelo pipeline.
- [ ] O-20 Push da imagem para o ECR com tag do commit hash (padrao do enunciado: `v1.0.0-a1b2c3d`).
- [ ] O-21 Os 5 repositorios ECR precisam existir (criar via Terraform e recomendado, ver R-02).

### 1.3 Entrega Continua (CD) e GitOps

- [x] O-22 Area de GitOps com apenas manifestos Kubernetes / Helm Charts (repo separado OU pasta separada no monorepo). Pasta `gitops/` no monorepo, em Kustomize (D-007, D-008).
- [ ] O-23 ArgoCD instalado no cluster EKS (Helm, ou Terraform com provider `helm`/`kubectl`).
- [ ] O-24 Passo final do CI que atualiza a tag da imagem no repositorio GitOps (altera o `deployment.yaml`).
- [ ] O-25 ArgoCD configurado para monitorar o repo GitOps e sincronizar automaticamente no EKS.
- [ ] O-26 Deploy sem `kubectl apply` direto pelo CI (o enunciado abandona o push direto).

## 2. OBRIGATORIO - Entregaveis

### 2.1 Video de demonstracao (limite de 20 min)

- [ ] O-27 IaC: `terraform plan` e `terraform apply` rodando, ou o resultado final na AWS (VPC, RDS, EKS criados por codigo).
- [ ] O-28 DevSecOps: alterar o codigo de um microsservico (erro proposital ou dependencia vulneravel) e mostrar o pipeline FALHANDO no passo de seguranca.
- [ ] O-29 DevSecOps: corrigir e mostrar o pipeline PASSANDO.
- [ ] O-30 GitOps: mostrar o pipeline atualizando a tag da imagem no repositorio GitOps.
- [ ] O-31 ArgoCD: mostrar a deteccao da mudanca e a sincronizacao automatica no cluster.
- [ ] O-32 ArgoCD: mostrar a interface gerenciando os 5 microsservicos.

### 2.2 Codigo fonte no repositorio

- [ ] O-33 Todo o codigo Terraform, bem estruturado e componentizado.
- [ ] O-34 Arquivos de workflow `.yaml` do GitHub Actions (ou ferramenta similar) com os passos DevSecOps.
- [~] O-35 Manifestos Kubernetes ajustados para GitOps. Criados em `gitops/` em 2026-08-27 e validados com `kubectl kustomize`; faltam os placeholders de endpoint e ARN, que dependem da Etapa 2.

### 2.3 Relatorio de entrega (.PDF ou .txt)

- [~] O-36 Nomes dos participantes do grupo. Grupo 203 recuperado do README da Fase 2 e ja no `README.md`; aguarda confirmacao do usuario de que o grupo nao mudou.
- [ ] O-37 Link da documentacao e do video.
- [ ] O-38 Breve resumo dos desafios encontrados e das decisoes tomadas.
- [ ] O-39 Print da estimativa de custos da AWS.

---

## 3. NAO OBRIGATORIO - Opcional / recomendado pelo proprio enunciado

- [ ] R-01 Organizar o Terraform em modulos ("preferencialmente usando modulos").
- [ ] R-02 Criar os 5 repositorios ECR via Terraform ("opcional via Terraform, mas recomendado").
- [ ] R-03 Flag `use_lockfile` no backend S3 para lock de estado ("opcionalmente").
- [ ] R-04 Testes unitarios no job de build ("se houver" - condicional, nao exigido).
- [ ] R-05 Criar roles e policies IAM via Terraform - liberado e "recomendado para um portfolio profissional" porque o projeto usa conta pessoal (Opcao B). Nao se aplica a restricao da LabRole do AWS Academy.
- [ ] R-06 Usar Helm Charts em vez de YAMLs puros na area GitOps (o enunciado aceita os dois). **Nao adotado**: D-008 escolheu Kustomize, sobre a base de `infra/k8s/` da Fase 2 (D-014).
- [ ] R-07 Repositorio GitOps separado em vez de pasta no monorepo (o enunciado aceita os dois). **Nao adotado**: D-007 escolheu monorepo com a pasta `gitops/`.
- [ ] R-08 SonarCloud gratuito como SAST (alternativa a `gosec`/`bandit`).
- [ ] R-09 GitHub Actions como ferramenta de CI (o enunciado diz "ex.:" e "ou ferramenta similar").

## 4. NAO OBRIGATORIO - Sugestoes derivadas dos modulos de aula (fora do enunciado)

Estes itens nao valem nota por si so, mas apareceram nas aulas da Fase 3 e reforcam O-16, O-33 e a nota de seguranca.

- [ ] S-01 Autenticacao do CI na AWS por OIDC em vez de chaves de acesso estaticas.
- [ ] S-02 Segredos de banco em AWS Secrets Manager / SSM Parameter Store, atacando diretamente a dor descrita no enunciado ("credenciais em arquivos de texto sem seguranca").
- [ ] S-03 Scan de IaC (Checkov, tfsec ou Trivy `config`) sobre o proprio Terraform.
- [ ] S-04 CSPM com Prowler para postura da conta AWS.
- [ ] S-05 Criptografia em repouso com KMS em RDS, DynamoDB, SQS e bucket de estado.
- [ ] S-06 Menor privilegio nas roles IAM e IRSA para os pods.
- [ ] S-07 Auditoria com CloudTrail e logs do EKS.
- [ ] S-08 `terraform fmt`/`validate` e `plan` automatizados em PR de infraestrutura.
- [ ] S-09 Estrategia de destroy/agendamento para conter custo da conta pessoal (EKS + 3 RDS + Redis nao sao baratos).

---

## 5. Decisoes que travavam o inicio - todas fechadas

- P-004: **fechada em 2026-08-27** (D-007). O codigo dos 5 microsservicos vive neste monorepo em `services/`.
- P-005: **fechada em 2026-08-27** (D-008). A area GitOps usa Kustomize em `gitops/`.
- Resolvido em 2026-07-30: entrega em grupo, prazo final 2026-09-15 (D-006). Encerra P-016 e P-017.

Bloqueios remanescentes, agora operacionais:

- P-019: **fechada em 2026-08-27**. Bucket de estado criado pelo console.
- P-025: **fechada em 2026-08-27**. Plano aprovado pelo usuario (D-010 a D-014).
- P-018: obter os nomes dos integrantes do grupo para o relatorio (O-36). [INCERTO]

## 5.1 Marcos rebaseados em 2026-08-27 (2a revisao, 19:50)

Reorganizados para refletir o plano em 4 fases de `PENDENCIAS_E_PROXIMOS_PASSOS.md`. O principio e adiantar tudo que nao custa credito e concentrar o cluster em duas sessoes de 3 horas. Continuam sendo proposta minha, nao exigencia do enunciado.

| Marco | Alvo | Cobre | Situacao |
|---|---|---|---|
| M1 - Decisoes e esqueleto | 2026-08-27 | D-007, D-008, servicos em `services/` | Concluido, com 19 dias de atraso |
| M2 - Etapa 1 aplicada e CI dos 5 servicos | 2026-08-31 | O-02, O-07 a O-09, O-21, O-10 a O-20, R-03 | Etapa 1 escrita e validada; falta aplicar |
| M3 - Etapas 2 e 3 escritas + runbook | 2026-09-04 | O-01, O-03 a O-06, O-23, R-01, R-05 | |
| M4 - Sessao de ensaio (3h de cluster) | 2026-09-07 | valida O-01 a O-26 ponta a ponta | |
| M5 - Sessao de gravacao (3h de cluster) | 2026-09-11 | O-27, O-31, O-32 | |
| M6 - Video montado, relatorio e revisao | 2026-09-14 | O-27 a O-39 | |
| Entrega | 2026-09-15 | - | |

Observacao de risco: o caminho critico e M4, a primeira vez que a pilha completa sobe. O `terraform apply` de EKS + 2 RDS + ElastiCache leva de 20 a 40 minutos e raramente passa de primeira. Por isso o ensaio (M4) esta 4 dias antes da gravacao (M5), e nao coladinho: se quebrar, ha tempo de corrigir sem o cluster ligado.

## 6. Observacoes de leitura do enunciado

- Os 5 microsservicos da Fase 2 sao 2 em Go (`auth`, `evaluation`) e 3 em Python (`flag`, `targeting`, `analytics`), conforme `tech-challenge-02/services/`. Isso define dois conjuntos de linter/SAST: `golangci-lint` + `gosec` e `pylint`/`flake8` + `bandit`.
- O enunciado pede 3 RDS PostgreSQL, mas nao diz quais servicos os usam; a Fase 2 tem bancos para `auth`, `flag` e `targeting`.
- A frase-guia da fase e "Se nao esta no codigo, nao existe": qualquer recurso criado no console fora do Terraform contraria o objetivo avaliado.
