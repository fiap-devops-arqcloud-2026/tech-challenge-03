# PENDENCIAS_E_PROXIMOS_PASSOS

TL;DR: os guias HTML dos modulos 1 a 5 estao prontos para revisao. A trilha de estudos da Fase 3 foi concluida e o checklist de requisitos ja existe. Entrega em grupo com prazo final 2026-09-15; a implementacao permanece em espera ate pedido explicito.

Ultima atualizacao: 2026-07-30 15:38 -03:00, Claude.

## Alta prioridade

- P-018: obter os nomes dos integrantes do grupo para o relatorio de entrega (O-36). [INCERTO]
- P-004 e P-005 viraram bloqueio de cronograma: sem elas o marco M1 (2026-08-08) nao fecha. Detalhes em `CHECKLIST_REQUISITOS_FASE3.md`.

- P-007: usuario revisar o guia `docs/01_Welcome to Automacao e Seguranca na Cloud/GUIA-ESTUDO-Automacao-e-Seguranca-na-Cloud.html`.
- P-009: usuario revisar o guia `docs/02_CI-CD/GUIA-ESTUDO-CI-CD.html`.
- P-011: usuario revisar o guia `docs/03_Infraestrutura como codigo/GUIA-ESTUDO-Infraestrutura-como-Codigo.html`.
- P-013: usuario revisar o guia `docs/04_Seguranca em DevOps (DevSecOps)/GUIA-ESTUDO-Seguranca-em-DevOps-DevSecOps.html`.
- P-015: usuario revisar o guia `docs/05_Seguranca na Cloud/GUIA-ESTUDO-Seguranca-na-Cloud.html`.

## Em espera ate pedido do usuario

- P-003: desenhar a arquitetura Terraform da Fase 3: VPC, EKS, RDS, Redis, DynamoDB, SQS, ECR, IAM e backend remoto.
- P-004: definir se o codigo dos 5 microsservicos sera copiado do repo Fase 2 para este repo ou mantido como referencia externa.
- P-005: decidir entre manifests YAML simples, Kustomize ou Helm para a area GitOps.
- P-006: preparar roteiro do video final com evidencias: Terraform plan/apply, pipeline quebrando/passando, ECR, GitOps e ArgoCD.

## Encerradas ou substituidas

- P-001: encerrada em 2026-07-18. Os guias Markdown anteriores foram rejeitados e apagados; D-005 define o novo padrao HTML por modulo.
- P-008: concluida em 2026-07-18. O modulo `02_CI-CD` foi analisado e recebeu seu guia HTML.
- P-010: concluida em 2026-07-18. O modulo `03_Infraestrutura como codigo` foi analisado e recebeu seu guia HTML.
- P-012: concluida em 2026-07-18. O modulo `04_Seguranca em DevOps (DevSecOps)` foi analisado e recebeu seu guia HTML.
- P-002: substituida em 2026-07-18 por P-014, que representa o ultimo modulo pendente.
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
- F-010: o enunciado marca como opcional/recomendado apenas: modulos Terraform, ECR via Terraform, flag `use_lockfile`, testes unitarios "se houver", IAM via Terraform (conta pessoal), Helm vs YAML, repo GitOps separado vs pasta no monorepo e a escolha da ferramenta de CI. Todo o restante e obrigatorio. Detalhamento em `00_COLAB_IA/CHECKLIST_REQUISITOS_FASE3.md`.
