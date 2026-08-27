# PENDENCIAS_E_PROXIMOS_PASSOS

TL;DR: plano do Terraform aprovado pelo usuario em 2026-08-27 (D-010 a D-014). Bucket de estado criado. A re-analise da Fase 2 revelou `infra/k8s/` com 28 manifestos reaproveitaveis, o que barateia muito o GitOps. O trabalho agora e implementacao pura, comecando pela Etapa 1 do Terraform. Entrega em grupo, prazo final 2026-09-15.

Ultima atualizacao: 2026-08-27 14:05 -03:00, Claude.

## Alta prioridade

- P-026: escrever a Etapa 1 do Terraform - `backend.tf`, `providers.tf`, network, ECR, SQS, DynamoDB e IAM/OIDC. Barata e rapida, destrava o pipeline de CI para correr em paralelo com o EKS.
- P-027: derivar `gitops/base/` de `infra/k8s/` da Fase 2, conforme D-014.
- P-018: obter os nomes dos integrantes do grupo para o relatorio de entrega (O-36). [INCERTO]

## Proximos passos

- P-028: Etapa 2 do Terraform - EKS, node group, 3 RDS e ElastiCache. Apply lento, cerca de 25 minutos.
- P-029: Etapa 3 - root `terraform/argocd/` com ArgoCD e External Secrets Operator via provider `helm`.
- P-030: workflows de CI dos 5 servicos (O-10 a O-21), com dois conjuntos de linter/SAST por causa das duas stacks (F-008).
- P-031: migrar o banco do `targeting` do StatefulSet no cluster para o RDS numero 3 (F-016), incluindo o `init.sql` que ja existe em `services/targeting-service/db/`.
- P-024: corrigir os exemplos de `AWS_REGION` nos READMEs de `services/analytics-service/` e `services/evaluation-service/`, que ainda dizem `us-east-1`. Aguarda aval do usuario por serem arquivos copiados da Fase 2.
- P-006: preparar roteiro do video final com evidencias: Terraform plan/apply, pipeline quebrando/passando, ECR, GitOps e ArgoCD.

## Revisoes pendentes do usuario (baixa prioridade agora)

- P-007, P-009, P-011, P-013, P-015: revisar os cinco guias HTML de estudo da Fase 3.

## Encerradas ou substituidas

- P-001: encerrada em 2026-07-18. Os guias Markdown anteriores foram rejeitados e apagados; D-005 define o novo padrao HTML por modulo.
- P-002: substituida em 2026-07-18 por P-014, que representava o ultimo modulo pendente.
- P-004: encerrada em 2026-08-27. O codigo dos 5 microsservicos vive neste monorepo em `services/` (D-007).
- P-005: encerrada em 2026-08-27. A area GitOps usa Kustomize (D-008).
- P-008, P-010, P-012, P-014: concluidas em 2026-07-18. Guias HTML dos modulos 2 a 5 criados.
- P-016: encerrada em 2026-07-30. O usuario confirmou entrega em grupo (D-006).
- P-017: encerrada em 2026-07-30. Prazo final confirmado pelo usuario: 2026-09-15 (D-006).
- P-019: encerrada em 2026-08-27. Bucket de estado criado pelo console: `togglemaster-tfstate-891376952395-us-east-2-an`, regiao `us-east-2`, versionamento ligado, SSE-S3, acesso publico bloqueado, policy TLS-only e lifecycle de 30 dias.
- P-020: encerrada em 2026-08-27 por D-010 (modulos hibridos) e D-009 (tags).
- P-021: encerrada em 2026-08-27 por D-014. O esqueleto do Kustomize deixa de ser autoria e vira adaptacao; a execucao virou P-027.
- P-022: encerrada em 2026-08-27. OIDC do GitHub Actions confirmado, sem access key estatica (S-01).
- P-023: encerrada em 2026-08-27 por D-013. Secrets Manager + External Secrets Operator.
- P-025: encerrada em 2026-08-27. O usuario aprovou o plano do Terraform, com duas alteracoes: ambiente unico chamado `prod` (D-011) e remocao do Ingress (D-012).

## Achados

- F-001: a pasta de material da Fase 2 contem 6 modulos, 34 PDFs e guias HTML por modulo.
- F-002: a Fase 2 explica a base operacional que a Fase 3 automatiza: containers, Kubernetes, escalabilidade, Ingress, balanceamento e HA.
- F-003: o modulo Welcome possui um PDF introdutorio de 4 paginas e apresenta quatro pilares: CI/CD, IaC, DevSecOps e Seguranca na Cloud.
- F-004: o modulo CI/CD possui 7 PDFs sobre fundamentos, otimizacao, Kubernetes, GitOps, Terraform, serverless e AIOps.
- F-005: o modulo Infraestrutura como Codigo possui 8 PDFs e termina com uma infraestrutura AWS completa automatizada por GitHub Actions.
- F-006: o modulo DevSecOps possui 7 PDFs e cobre pipeline seguro, segredos, SAST/SCA, containers/IaC, DAST, gestao de vulnerabilidades e auditoria.
- F-007: o modulo Seguranca na Cloud possui 5 PDFs e cobre ameacas, responsabilidade compartilhada, IAM/MFA/Zero Trust, criptografia/privacidade e CSPM/CWPP/CASB.
- F-008: os 5 microsservicos usam duas stacks - Go em `auth` e `evaluation`, Python em `flag`, `targeting` e `analytics`. Logo o CI precisa de dois conjuntos de linter/SAST (`golangci-lint`+`gosec` e `pylint`/`flake8`+`bandit`).
- F-009: o enunciado fixa o nome literal da tabela DynamoDB como `ToggleMasterAnalytics` e o padrao de tag de imagem como `v1.0.0-<commit-hash>`.
- F-010: o enunciado marca como opcional/recomendado apenas: modulos Terraform, ECR via Terraform, flag `use_lockfile`, testes unitarios "se houver", IAM via Terraform (conta pessoal), Helm vs YAML, repo GitOps separado vs pasta no monorepo e a escolha da ferramenta de CI.
- F-011: varredura de segredos em `services/` nao encontrou credencial hardcoded. Toda a configuracao vem de variaveis de ambiente: `DATABASE_URL`, `REDIS_URL`, `AWS_REGION`, `AWS_SQS_URL`, `AWS_DYNAMODB_TABLE`, `MASTER_KEY`, `SERVICE_API_KEY`, `PORT`, `AUTH_SERVICE_URL`, `FLAG_SERVICE_URL`, `TARGETING_SERVICE_URL`.
- F-012: a regiao do projeto e `us-east-2` (Ohio). Cuidado: os READMEs copiados em `services/analytics-service/` e `services/evaluation-service/` trazem `us-east-1` nos exemplos; sao herdados da Fase 2 e estao errados (P-024).
- F-013: os marcos M1 (2026-08-08) e M2 (2026-08-22) originais venceram sem conclusao; o cronograma foi rebaseado em `CHECKLIST_REQUISITOS_FASE3.md`.
- F-014: o nome do bucket adotado inclui o numero da conta AWS e vai para o `backend.tf` versionado. Account ID nao e credencial, mas a AWS recomenda nao publicar sem necessidade. Mitigacao adotada: manter o repositorio privado ate a entrega.
- F-015: o `git pull` da Fase 2 em 2026-08-27 foi fast-forward de `0f3abe8` para `3d8a9b2` e trouxe 4 commits, todos de documentacao (35 PDFs de aula, 6 guias HTML, secao do README e log de colaboracao). Nenhuma alteracao em codigo. Diff confirmou que `services/` daqui e identico ao da Fase 2, exceto `__pycache__`.
- F-016: a Fase 2 tinha 2 RDS, nao 3. `auth_db` e `flags_db` em RDS; o `targeting_db` rodava como StatefulSet `postgres-targeting` dentro do cluster. O `GUIA-AWS.md` da Fase 2 confirma: "repita 2 vezes" e "O targeting NAO usa RDS". O terceiro RDS exigido pela Fase 3 e exatamente essa migracao (P-031).
- F-017: na Fase 2, `analytics` e `evaluation` acessam SQS e DynamoDB com `AWS_ACCESS_KEY_ID` e `AWS_SECRET_ACCESS_KEY` estaticas dentro de um Secret do Kubernetes. E literalmente a dor descrita no enunciado e o "antes" ideal para demonstrar IRSA no video e no relatorio (O-38).
- F-018: o enunciado da Fase 3 nao exige Ingress, Load Balancer nem acesso externo. Extracao do PDF em 2026-08-27 com `pdftotext`: as palavras "ingress", "load balancer", "balanceador", "acesso externo", "http", "url", "endpoint", "dominio", "expor", "publico", "nginx" e "alb" aparecem zero vezes nas 7 paginas. Base factual de D-012.
- F-019: nomes canonicos ja em uso na Fase 2, reaproveitados para evitar divergencia entre Terraform, Kustomize e codigo: namespace `togglemaster`; repositorios ECR `<servico>-service`; fila `togglemaster-events`; cache `togglemaster-redis`; tabela `ToggleMasterAnalytics`; bancos `auth_db`, `flags_db`, `targeting_db` com usuario `toggle`; portas auth 8001, flag 8002, targeting 8003, evaluation 8004, analytics 8005.
- F-020: soma dos `requests` reais dos 5 deployments da Fase 2: 450m de CPU e 512Mi de RAM. Com ArgoCD, ESO e kube-system, o total fica em torno de 1,25 vCPU e 1,9 GiB. Confirma que 2 nos `t3.medium` (4 vCPU / 8 GiB) atendem com folga, incluindo espaco para o HPA do `evaluation` escalar.
