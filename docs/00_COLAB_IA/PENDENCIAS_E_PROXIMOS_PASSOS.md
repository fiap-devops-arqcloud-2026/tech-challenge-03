# PENDENCIAS_E_PROXIMOS_PASSOS

TL;DR: as decisoes que travavam o inicio foram fechadas (D-007 monorepo, D-008 Kustomize). A implementacao comecou: os 5 microsservicos estao em `services/`. O proximo bloqueio e operacional, nao de decisao - alguem do grupo precisa executar `terraform/BOOTSTRAP-BACKEND-S3.md` e informar o nome do bucket (P-019). Entrega em grupo, prazo final 2026-09-15.

Ultima atualizacao: 2026-08-27 12:23 -03:00, Claude.

## Alta prioridade

- P-019: criar o bucket S3 de estado seguindo `terraform/BOOTSTRAP-BACKEND-S3.md` e preencher o nome na secao 8 daquele arquivo. **Bloqueia todo o Terraform (O-09 e M2).**
- P-018: obter os nomes dos integrantes do grupo para o relatorio de entrega (O-36). [INCERTO]
- P-003: com o bucket pronto, escrever `terraform/backend.tf` e a VPC, e seguir para EKS, RDS, ElastiCache, DynamoDB, SQS, ECR e IAM.

## Proximos passos apos P-019

- P-020: definir a estrutura de modulos do Terraform (R-01) e o padrao de tags/nomes dos recursos.
- P-021: montar o esqueleto `gitops/base/<servico>` e `gitops/overlays/<ambiente>` em Kustomize (D-008), antes de escrever os workflows que vao alterar essas tags.
- P-022: decidir entre OIDC (S-01) e access keys estaticas para o GitHub Actions autenticar na AWS. Recomendacao atual: OIDC.
- P-023: decidir onde ficam os segredos dos bancos - Secrets Manager ou SSM Parameter Store (S-02) - antes de escrever os manifests que consomem `DATABASE_URL`.
- P-024: corrigir os exemplos de `AWS_REGION` nos READMEs de `services/analytics-service/` e `services/evaluation-service/`, que ainda dizem `us-east-1`. Aguarda aval do usuario por serem arquivos copiados da Fase 2.
- P-006: preparar roteiro do video final com evidencias: Terraform plan/apply, pipeline quebrando/passando, ECR, GitOps e ArgoCD.

## Revisoes pendentes do usuario (baixa prioridade agora)

- P-007: revisar o guia `docs/01_Welcome to Automacao e Seguranca na Cloud/GUIA-ESTUDO-Automacao-e-Seguranca-na-Cloud.html`.
- P-009: revisar o guia `docs/02_CI-CD/GUIA-ESTUDO-CI-CD.html`.
- P-011: revisar o guia `docs/03_Infraestrutura como codigo/GUIA-ESTUDO-Infraestrutura-como-Codigo.html`.
- P-013: revisar o guia `docs/04_Seguranca em DevOps (DevSecOps)/GUIA-ESTUDO-Seguranca-em-DevOps-DevSecOps.html`.
- P-015: revisar o guia `docs/05_Seguranca na Cloud/GUIA-ESTUDO-Seguranca-na-Cloud.html`.

## Encerradas ou substituidas

- P-001: encerrada em 2026-07-18. Os guias Markdown anteriores foram rejeitados e apagados; D-005 define o novo padrao HTML por modulo.
- P-002: substituida em 2026-07-18 por P-014, que representava o ultimo modulo pendente.
- P-004: encerrada em 2026-08-27. O codigo dos 5 microsservicos vive neste monorepo em `services/` (D-007).
- P-005: encerrada em 2026-08-27. A area GitOps usa Kustomize (D-008).
- P-008: concluida em 2026-07-18. O modulo `02_CI-CD` foi analisado e recebeu seu guia HTML.
- P-010: concluida em 2026-07-18. O modulo `03_Infraestrutura como codigo` foi analisado e recebeu seu guia HTML.
- P-012: concluida em 2026-07-18. O modulo `04_Seguranca em DevOps (DevSecOps)` foi analisado e recebeu seu guia HTML.
- P-014: concluida em 2026-07-18. O modulo `05_Seguranca na Cloud` foi analisado e recebeu seu guia HTML.
- P-016: encerrada em 2026-07-30. O usuario confirmou entrega em grupo (D-006). A lista de nomes segue pendente em P-018.
- P-017: encerrada em 2026-07-30. Prazo final confirmado pelo usuario: 2026-09-15 (D-006).

## Achados

- F-001: a pasta `tech-challenge-02\docs\Material aulas` contem 6 modulos, 34 PDFs e guias HTML por modulo.
- F-002: a Fase 2 explica a base operacional que a Fase 3 automatiza: containers, Kubernetes, escalabilidade, Ingress, balanceamento e HA.
- F-003: o modulo Welcome possui um PDF introdutorio de 4 paginas e apresenta quatro pilares: CI/CD, IaC, DevSecOps e Seguranca na Cloud.
- F-004: o modulo CI/CD possui 7 PDFs sobre fundamentos, otimizacao, Kubernetes, GitOps, Terraform, serverless e AIOps.
- F-005: o modulo Infraestrutura como Codigo possui 8 PDFs e termina com uma infraestrutura AWS completa automatizada por GitHub Actions.
- F-006: o modulo DevSecOps possui 7 PDFs e cobre pipeline seguro, segredos, SAST/SCA, containers/IaC, DAST, gestao de vulnerabilidades e auditoria.
- F-007: o modulo Seguranca na Cloud possui 5 PDFs e cobre ameacas, responsabilidade compartilhada, IAM/MFA/Zero Trust, criptografia/privacidade e CSPM/CWPP/CASB.
- F-008: os 5 microsservicos da Fase 2 usam duas stacks - Go em `auth` e `evaluation`, Python em `flag`, `targeting` e `analytics`. Logo o CI precisa de dois conjuntos de linter/SAST (`golangci-lint`+`gosec` e `pylint`/`flake8`+`bandit`).
- F-009: o enunciado fixa o nome literal da tabela DynamoDB como `ToggleMasterAnalytics` e o padrao de tag de imagem como `v1.0.0-<commit-hash>`.
- F-010: o enunciado marca como opcional/recomendado apenas: modulos Terraform, ECR via Terraform, flag `use_lockfile`, testes unitarios "se houver", IAM via Terraform (conta pessoal), Helm vs YAML, repo GitOps separado vs pasta no monorepo e a escolha da ferramenta de CI. Todo o restante e obrigatorio. Detalhamento em `CHECKLIST_REQUISITOS_FASE3.md`.
- F-011: varredura de segredos em `services/` nao encontrou credencial, chave privada ou senha hardcoded. Toda a configuracao vem de variaveis de ambiente: `DATABASE_URL`, `REDIS_URL`, `AWS_REGION`, `AWS_SQS_URL`, `AWS_DYNAMODB_TABLE`, `MASTER_KEY`, `SERVICE_API_KEY`, `PORT`, `AUTH_SERVICE_URL`, `FLAG_SERVICE_URL`, `TARGETING_SERVICE_URL`. Isso mapeia direto para ConfigMap/Secret no Kustomize.
- F-012: a regiao do projeto e `us-east-2` (Ohio), a mesma da Fase 2, confirmada pelo usuario em 2026-08-27. **Cuidado**: os READMEs copiados em `services/analytics-service/` e `services/evaluation-service/` trazem `us-east-1` nos exemplos de variavel de ambiente. Sao exemplos herdados da Fase 2 e estao errados para este projeto; quem copiar de la aponta para a regiao errada (P-024).
- F-013: os marcos M1 (2026-08-08) e M2 (2026-08-22) venceram sem conclusao. Em 2026-08-27 restam 19 dias ate a entrega; o cronograma foi rebaseado em `CHECKLIST_REQUISITOS_FASE3.md`.
