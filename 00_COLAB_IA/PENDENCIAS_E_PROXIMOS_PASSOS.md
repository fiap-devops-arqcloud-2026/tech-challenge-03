# PENDENCIAS_E_PROXIMOS_PASSOS

TL;DR: guias da Fase 2 foram gerados. Proximos passos naturais: revisar formato, estudar DevSecOps/Seguranca na Cloud e iniciar desenho Terraform/GitOps.

Ultima atualizacao: 2026-07-17 16:31 -03:00, Codex.

## Alta prioridade

- P-001: revisar com o usuario se os guias em Markdown atendem ou se devem ser convertidos para HTML no mesmo estilo dos guias existentes da Fase 2.
- P-002: estudar os modulos restantes da Fase 3: `04_Segurança em DevOps (DevSecOps)` e `05_Segurança na Cloud`.
- P-003: desenhar a arquitetura Terraform da Fase 3: VPC, EKS, RDS, Redis, DynamoDB, SQS, ECR, IAM e backend remoto.

## Media prioridade

- P-004: definir se o codigo dos 5 microsservicos sera copiado do repo Fase 2 para este repo ou mantido como referencia externa.
- P-005: decidir entre manifests YAML simples, Kustomize ou Helm para a area GitOps.
- P-006: preparar roteiro do video final com evidencias: Terraform plan/apply, pipeline quebrando/passando, ECR, GitOps e ArgoCD.

## Achados

- F-001: a pasta `tech-challenge-02\docs\Material aulas` contem 6 modulos, 34 PDFs e guias HTML por modulo.
- F-002: a Fase 2 explica a base operacional que a Fase 3 automatiza: containers, Kubernetes, escalabilidade, Ingress, balanceamento e HA.
