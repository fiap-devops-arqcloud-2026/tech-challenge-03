# CHECKLIST_REQUISITOS_FASE3

TL;DR: checklist extraido do enunciado `docs/POSTECH - Tech Challenge - Fase 3.pdf`. Separa o que e OBRIGATORIO (vale nota), o que o enunciado marcou como opcional/recomendado e o que e sugestao dos modulos de aula. Entrega em grupo, prazo final 2026-09-15. Em 2026-08-27 a implementacao comecou: os 5 microsservicos ja estao em `services/`; o restante segue pendente.

Ultima atualizacao: 2026-08-27 20:40 -03:00, Claude.

Prazo final: 2026-09-15. Modalidade: entrega em grupo (D-006).

Fonte unica desta lista: paginas 2 a 6 do PDF do enunciado. Itens fora do PDF estao na secao 4 e marcados como sugestao propria.

---

## 1. OBRIGATORIO - Requisitos tecnicos

### 1.1 Infraestrutura como Codigo (Terraform)

- [ ] O-01 Projeto Terraform substituindo a criacao manual da Fase 2.
- [x] O-02 Networking: VPC, subnets publicas, subnets privadas, Internet Gateway e Route Tables. Aplicado na AWS em 2026-09-07 (P-038).
- [x] O-03 Cluster EKS provisionado por Terraform. Escrito e planejado em 2026-09-08 em `terraform/cluster/` (35 recursos no plan); pendente o apply.
- [x] O-04 Node Groups do EKS provisionados por Terraform. Escrito e planejado em 2026-09-08 em `terraform/cluster/` (35 recursos no plan); pendente o apply.
- [~] O-05 3 instancias RDS PostgreSQL. PARCIAL e de forma consciente: esta conta esta no plano gratuito novo da AWS e RECUSA a terceira instancia com "maximum number of instances available with free plan accounts" (F-023). Foram criadas 2 - `auth_db` e `flags_db` - e o terceiro banco, `targeting_db`, roda como StatefulSet dentro do EKS (D-015), mesmo arranjo da Fase 2 e confirmado com o professor em 2026-08-27. Precisa constar no relatorio (O-38).
- [x] O-06 1 cluster ElastiCache (Redis). Escrito e planejado em 2026-09-08 em `terraform/cluster/` (35 recursos no plan); pendente o apply.
- [x] O-07 1 tabela DynamoDB chamada `ToggleMasterAnalytics` (nome literal do enunciado). Aplicado na AWS em 2026-09-07 (P-038).
- [x] O-08 1 fila SQS. Aplicado na AWS em 2026-09-07 (P-038).
- [x] O-09 Backend remoto em bucket S3; `terraform.tfstate` nao pode ficar local. Bucket criado em 2026-08-27; blocos `backend "s3"` escritos nas duas camadas, com chaves `prod/base.tfstate` e `prod/cluster.tfstate` (D-017). Aplicado em 2026-09-07: `prod/base.tfstate` (61 KiB) existe no bucket e nada ficou local (P-038).

### 1.2 Pipeline de CI e DevSecOps

- [x] O-10 Workflow de CI para cada um dos 5 microsservicos (`auth`, `flag`, `targeting`, `evaluation`, `analytics`). Escrito em 2026-09-01 nos workflows do GitHub Actions; pendente a primeira execucao real (P-044). PROVADO em 2026-09-09: os 5 pipelines rodaram verdes na main.
- [x] O-11 Gatilho em Pull Request e em push na `main`. Escrito em 2026-09-01 nos workflows do GitHub Actions; pendente a primeira execucao real (P-044). PROVADO: disparou em push na main e na dev, com filtro de caminho por servico.
- [x] O-12 Job Build (compilar/empacotar o codigo). Escrito em 2026-09-01 nos workflows do GitHub Actions; pendente a primeira execucao real (P-044). PROVADO: job Build e testes verde nos 5.
- [x] O-13 Job Linter / analise estatica (ex.: `golangci-lint` para Go, `pylint`/`flake8` para Python). Escrito em 2026-09-01 nos workflows do GitHub Actions; pendente a primeira execucao real (P-044). PROVADO: golangci-lint v2.13.2 e flake8/pylint verdes nos 5.
- [x] O-14 Job SCA - vulnerabilidade em dependencias (ex.: Trivy modo `fs` ou OWASP Dependency Check). Escrito em 2026-09-01 nos workflows do GitHub Actions; pendente a primeira execucao real (P-044). PROVADO: Trivy fs barrou o CVE-2026-56854 (CRITICAL) em x/crypto e so liberou apos o upgrade.
- [x] O-15 Job SAST - vulnerabilidade no codigo fonte (ex.: SonarCloud gratuito, `gosec`, `bandit`). Escrito em 2026-09-01 nos workflows do GitHub Actions; pendente a primeira execucao real (P-044). PROVADO: gosec e bandit verdes nos 5, com 4 achados de SSRF analisados um a um.
- [x] O-16 Regra de bloqueio: vulnerabilidade CRITICA faz o pipeline falhar e nao prosseguir. Escrito em 2026-09-01 nos workflows do GitHub Actions; pendente a primeira execucao real (P-044). PROVADO NA PRATICA: o CVE critico do x/crypto derrubou o pipeline e o job de imagem foi SKIPPED - nao apenas falhou, nao prosseguiu.
- [x] O-17 Build da imagem Docker. Escrito em 2026-09-01 nos workflows do GitHub Actions; pendente a primeira execucao real (P-044). PROVADO: as 5 imagens foram construidas.
- [x] O-18 Scan de vulnerabilidade na imagem (container scan com Trivy). Escrito em 2026-09-01 nos workflows do GitHub Actions; pendente a primeira execucao real (P-044). PROVADO: scan de imagem verde nos 5.
- [x] O-19 Login no AWS ECR pelo pipeline. Escrito em 2026-09-01 nos workflows do GitHub Actions; pendente a primeira execucao real (P-044). PROVADO: login via OIDC funcionando, sem chave estatica.
- [x] O-20 Push da imagem para o ECR com tag do commit hash (padrao do enunciado: `v1.0.0-a1b2c3d`). Escrito em 2026-09-01 nos workflows do GitHub Actions; pendente a primeira execucao real (P-044). PROVADO: as 5 imagens no ECR com a tag v1.0.0-122174a, no padrao do enunciado.
- [x] O-21 Os 5 repositorios ECR precisam existir (criar via Terraform e recomendado, ver R-02). Aplicado na AWS em 2026-09-07 (P-038).

### 1.3 Entrega Continua (CD) e GitOps

- [x] O-22 Area de GitOps com apenas manifestos Kubernetes / Helm Charts (repo separado OU pasta separada no monorepo). Pasta `gitops/` no monorepo, em Kustomize (D-007, D-008).
- [x] O-23 ArgoCD instalado no cluster EKS (Helm, ou Terraform com provider `helm`/`kubectl`). Escrito em 2026-09-09 em `terraform/k8s/argocd.tf` (chart oficial via provider helm, versao fixa 7.7.11); pendente o apply.
- [x] O-24 Passo final do CI que atualiza a tag da imagem no repositorio GitOps (altera o `deployment.yaml`). Escrito em 2026-09-01 nos workflows do GitHub Actions; pendente a primeira execucao real (P-044). PROVADO: 5 commits chore(gitops) feitos pelo proprio pipeline, um por servico.
- [x] O-25 ArgoCD configurado para monitorar o repo GitOps e sincronizar automaticamente no EKS. Escrito em 2026-09-09 em `terraform/k8s/argocd.tf` (chart oficial via provider helm, versao fixa 7.7.11); pendente o apply.
- [x] O-26 Deploy sem `kubectl apply` direto pelo CI (o enunciado abandona o push direto). Escrito em 2026-09-01 nos workflows do GitHub Actions; pendente a primeira execucao real (P-044). PROVADO: nenhum kubectl apply no CI - so commit no Git.

## 2. OBRIGATORIO - Entregaveis

### 2.1 Video de demonstracao (limite de 20 min)

- [ ] O-27 IaC: `terraform plan` e `terraform apply` rodando, ou o resultado final na AWS (VPC, RDS, EKS criados por codigo).
- [ ] O-28 DevSecOps: alterar o codigo de um microsservico (erro proposital ou dependencia vulneravel) e mostrar o pipeline FALHANDO no passo de seguranca.
- [ ] O-29 DevSecOps: corrigir e mostrar o pipeline PASSANDO.
- [ ] O-30 GitOps: mostrar o pipeline atualizando a tag da imagem no repositorio GitOps.
- [ ] O-31 ArgoCD: mostrar a deteccao da mudanca e a sincronizacao automatica no cluster.
- [ ] O-32 ArgoCD: mostrar a interface gerenciando os 5 microsservicos.

### 2.2 Codigo fonte no repositorio

- [x] O-33 Todo o codigo Terraform, bem estruturado e componentizado. Tres camadas com estado independente (base permanente, cluster efemero, k8s), 7 modulos proprios e comentario linha a linha. `validate` e `fmt` passam nas tres.
- [x] O-34 Arquivos de workflow `.yaml` do GitHub Actions (ou ferramenta similar) com os passos DevSecOps. Sete arquivos em `.github/workflows/`: 2 reutilizaveis e 5 chamadores, com build, linter, SAST, SCA, scan de imagem e portao de bloqueio.
- [x] O-35 Manifestos Kubernetes ajustados para GitOps. Kustomize com base e overlay, 23 recursos renderizados. Pendencias fechadas em 2026-09-09: `storageClassName` explicito no StatefulSet (F-025) e os 5 Secrets agora criados por `terraform/k8s/secrets.tf` (D-018).

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
| M2 - Etapa 1 aplicada e CI dos 5 servicos | 2026-08-31 | O-02, O-07 a O-09, O-21, O-10 a O-20, R-03 | CONCLUIDO em 2026-09-07: camada base aplicada (33 recursos) e 5 workflows escritos. Falta a primeira execucao dos pipelines (P-044). |
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
