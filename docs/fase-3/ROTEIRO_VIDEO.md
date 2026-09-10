# Roteiro do vídeo — máximo 20 minutos

> Ajustado em 2026-09-09: são **2 RDS + 1 banco em pod** (D-015) e **uma**
> Application do Argo CD gerenciando os cinco serviços. O roteiro
> detalhado, com o que já pode ser gravado sem o cluster no ar, está na
> FASE 3 do [runbook](../00_COLAB_IA/RUNBOOK-SESSAO.md).


1. **0:00–1:30** — equipe, problema e evolução das fases.
2. **1:30–4:00** — arquitetura e decisões de segurança/custo.
3. **4:00–7:00** — módulos Terraform, backend remoto e `plan`.
4. **7:00–10:00** — recursos no console AWS (VPC, EKS, os 2 RDS, Redis, SQS, DynamoDB, ECR).
5. **10:00–13:30** — PR, testes, SAST/SCA, Trivy e ECR por SHA.
6. **13:30–16:00** — Argo CD: a Application `togglemaster` em Healthy/Synced, com os cinco microsservicos dentro dela.
7. **16:00–18:30** — demonstração funcional e analytics no DynamoDB.
8. **18:30–20:00** — dificuldades, custos, conclusão e destruição do ambiente.
