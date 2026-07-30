# CHECKLIST_REQUISITOS_FASE3

TL;DR: checklist extraido do enunciado `docs/POSTECH - Tech Challenge - Fase 3.pdf`. Separa o que e OBRIGATORIO (vale nota), o que o enunciado marcou como opcional/recomendado e o que e sugestao dos modulos de aula. Entrega em grupo, prazo final 2026-09-15. Nada aqui foi implementado ainda.

Ultima atualizacao: 2026-07-30 15:38 -03:00, Claude.

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
- [ ] O-09 Backend remoto em bucket S3; `terraform.tfstate` nao pode ficar local.

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

- [ ] O-22 Area de GitOps com apenas manifestos Kubernetes / Helm Charts (repo separado OU pasta separada no monorepo).
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
- [ ] O-35 Manifestos Kubernetes ajustados para GitOps.

### 2.3 Relatorio de entrega (.PDF ou .txt)

- [ ] O-36 Nomes dos participantes do grupo. [INCERTO] a lista de integrantes ainda nao foi informada.
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
- [ ] R-06 Usar Helm Charts em vez de YAMLs puros na area GitOps (o enunciado aceita os dois).
- [ ] R-07 Repositorio GitOps separado em vez de pasta no monorepo (o enunciado aceita os dois).
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

## 5. Decisoes em aberto que travam o inicio

- P-004: o codigo dos 5 microsservicos sera copiado da Fase 2 para este repo ou ficara como referencia externa? Sem isso, O-10 nao tem onde rodar.
- P-005: YAML puro, Kustomize ou Helm na area GitOps (afeta O-22 e R-06).
- P-018: obter os nomes dos integrantes do grupo para o relatorio (O-36). [INCERTO]
- Resolvido em 2026-07-30: entrega em grupo, prazo final 2026-09-15 (D-006). Encerra P-016 e P-017.

## 5.1 Marcos sugeridos ate 2026-09-15

Sao marcos propostos por mim para caber no prazo, nao imposicoes do enunciado. Ajuste conforme a agenda do grupo.

| Marco | Alvo | Cobre |
|---|---|---|
| M1 - Decisoes e esqueleto | 2026-08-08 | P-004, P-005, backend S3 (O-09) |
| M2 - Infra Terraform aplicada | 2026-08-22 | O-01 a O-09, R-01, R-02, R-05 |
| M3 - CI/DevSecOps nos 5 servicos | 2026-09-01 | O-10 a O-21 |
| M4 - ArgoCD e GitOps sincronizando | 2026-09-08 | O-22 a O-26 |
| M5 - Video, relatorio e revisao final | 2026-09-13 | O-27 a O-39 |
| Entrega | 2026-09-15 | - |

## 6. Observacoes de leitura do enunciado

- Os 5 microsservicos da Fase 2 sao 2 em Go (`auth`, `evaluation`) e 3 em Python (`flag`, `targeting`, `analytics`), conforme `tech-challenge-02/services/`. Isso define dois conjuntos de linter/SAST: `golangci-lint` + `gosec` e `pylint`/`flake8` + `bandit`.
- O enunciado pede 3 RDS PostgreSQL, mas nao diz quais servicos os usam; a Fase 2 tem bancos para `auth`, `flag` e `targeting`.
- A frase-guia da fase e "Se nao esta no codigo, nao existe": qualquer recurso criado no console fora do Terraform contraria o objetivo avaliado.
