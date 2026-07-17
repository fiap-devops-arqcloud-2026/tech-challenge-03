# DECISOES

TL;DR: decisoes atuais concentram destino dos guias, estrategia de documentacao e direcao tecnica da Fase 3.

Ultima atualizacao: 2026-07-17 16:31 -03:00, Codex.

## D-001 - Repo destino da Fase 3

Contexto: o usuario pediu para trabalhar a terceira entrega a partir do repo `tech-challenge-03`.

Decisao: usar `C:\Users\Gabriel Silva\Documents\GitHub\tech-challenge-03` como destino de contexto, guias e proximas implementacoes.

Alternativas: editar `tech-challenge-02` diretamente.

Status: aceita em 2026-07-17.

## D-002 - Local dos guias de estudo

Contexto: materiais de origem estao em `tech-challenge-02\docs\Material aulas`, mas o projeto atual e a Fase 3.

Decisao: criar guias derivados em `docs/guias-de-estudo/fase-2/`, separados por modulo.

Alternativas: copiar os PDFs; salvar tudo em uma pasta unica; editar o repo da Fase 2.

Status: implementada em 2026-07-17.

## D-003 - Direcao tecnica da Fase 3

Contexto: enunciado pede IaC, CI/CD, DevSecOps e GitOps para o ToggleMaster.

Decisao: preferir Terraform modular, GitHub Actions, ECR, ArgoCD e EKS. Usar conta pessoal AWS para criar IAM roles/policies via Terraform.

Alternativas: Jenkins; FluxCD; AWS Academy/LabRole; `kubectl apply` direto no CI.

Status: direcao atual.

## D-004 - Tratamento dos materiais da Fase 2

Contexto: materiais da Fase 2 ajudam a entender containers, Kubernetes, escalabilidade e balanceamento.

Decisao: usar PDFs e guias HTML existentes como fonte, mas nao copiar os PDFs para o repo da Fase 3. Registrar sintese propria em Markdown.

Alternativas: versionar todo o material da Fase 2 no repo da Fase 3.

Status: implementada em 2026-07-17.
