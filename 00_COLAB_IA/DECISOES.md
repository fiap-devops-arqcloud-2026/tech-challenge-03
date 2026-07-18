# DECISOES

TL;DR: decisoes atuais concentram destino dos guias, estrategia de documentacao e direcao tecnica da Fase 3.

Ultima atualizacao: 2026-07-18 12:41 -03:00, Codex.

## D-001 - Repo destino da Fase 3

Contexto: o usuario pediu para trabalhar a terceira entrega a partir do repo `tech-challenge-03`.

Decisao: usar `C:\Users\Gabriel Silva\Documents\GitHub\tech-challenge-03` como destino de contexto, guias e proximas implementacoes.

Alternativas: editar `tech-challenge-02` diretamente.

Status: aceita em 2026-07-17.

## D-002 - Local dos guias de estudo

Contexto: materiais de origem estao em `tech-challenge-02\docs\Material aulas`, mas o projeto atual e a Fase 3.

Decisao: criar guias derivados em `docs/guias-de-estudo/fase-2/`, separados por modulo.

Alternativas: copiar os PDFs; salvar tudo em uma pasta unica; editar o repo da Fase 2.

Status: substituida por D-005 em 2026-07-18. Os guias Markdown foram removidos por decisao do usuario.

## D-005 - Guias HTML por modulo

Contexto: os guias Markdown agrupados em `docs/guias-de-estudo/fase-2/` nao atenderam ao usuario e foram apagados. O usuario decidiu estudar os materiais da Fase 3 por partes e indicou `GUIA-ESTUDO-Introducao-a-Containers.html` como padrao visual e didatico.

Decisao: criar um guia HTML por vez, salvo dentro da pasta do proprio modulo, seguindo a estrutura: introducao para leigos, glossario, fichas com finalidade/caso de uso/aplicacao no ToggleMaster e resumo.

Alternativas: manter os guias Markdown anteriores; agrupar todos os guias em uma pasta separada; gerar todos os modulos de uma vez.

Status: implementada em 2026-07-18 para os cinco modulos da Fase 3. Substitui D-002.

## D-003 - Direcao tecnica da Fase 3

Contexto: enunciado pede IaC, CI/CD, DevSecOps e GitOps para o ToggleMaster.

Decisao: preferir Terraform modular, GitHub Actions, ECR, ArgoCD e EKS. Usar conta pessoal AWS para criar IAM roles/policies via Terraform.

Alternativas: Jenkins; FluxCD; AWS Academy/LabRole; `kubectl apply` direto no CI.

Status: direcao atual.

## D-004 - Tratamento dos materiais da Fase 2

Contexto: materiais da Fase 2 ajudam a entender containers, Kubernetes, escalabilidade e balanceamento.

Decisao: usar PDFs e guias HTML existentes como fonte, mas nao copiar os PDFs para o repo da Fase 3. Registrar apenas sinteses proprias no formato vigente definido pelo usuario.

Alternativas: versionar todo o material da Fase 2 no repo da Fase 3.

Status: tratamento da fonte mantido. O formato Markdown foi substituido pelo HTML de D-005 em 2026-07-18.
