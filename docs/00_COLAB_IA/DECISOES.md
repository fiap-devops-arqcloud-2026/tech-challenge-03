# DECISOES

TL;DR: decisoes atuais cobrem destino dos guias, estrategia de documentacao, direcao tecnica da Fase 3, condicoes de entrega (grupo, prazo 2026-09-15) e a estrutura de implementacao (monorepo + Kustomize).

Ultima atualizacao: 2026-08-27 11:12 -03:00, Claude.

## D-008 - Kustomize na area GitOps

Contexto: P-005 perguntava se os manifestos do Kubernetes seriam YAML puro, Kustomize ou Helm. O enunciado aceita YAML ou Helm Charts (R-06) e nao exige nenhum dos dois.

Decisao: usar **Kustomize** em `gitops/`, com `base/` por microsservico e `overlays/` por ambiente. Confirmada pelo usuario em 2026-08-27; ja refletida no `README.md` desde 2026-08-26.

Por que: Kustomize e nativo do `kubectl` e do ArgoCD, nao exige templating nem manter um chart. O passo final do CI que atualiza a tag da imagem (O-24) vira um `kustomize edit set image`, que altera um unico campo de um `kustomization.yaml` - mais simples de automatizar e de auditar em diff do que reescrever `values.yaml` de Helm.

Alternativas: YAML puro (duplicaria manifesto por ambiente); Helm Charts (R-06, mais poder de templating, mais complexidade para 5 servicos parecidos).

Status: aceita em 2026-08-27, informada pelo usuario. Encerra P-005.

## D-007 - Codigo dos microsservicos neste monorepo

Contexto: P-004 perguntava se o codigo dos 5 microsservicos viria da Fase 2 para este repo ou ficaria como referencia externa. O enunciado tambem aceita repo GitOps separado ou pasta no monorepo (R-07).

Decisao: o codigo dos 5 microsservicos vive neste repositorio em `services/`, e a area GitOps e a pasta `gitops/` do mesmo monorepo. Confirmada pelo usuario em 2026-08-27; a copia ja havia sido feita em 2026-08-26.

Por que: os workflows de CI (O-10 a O-21) precisam do codigo no mesmo repo para disparar em Pull Request e push na `main`. Monorepo tambem simplifica o passo de CI que atualiza a tag no GitOps (O-24), que passa a ser um commit no proprio repositorio, sem precisar de token cruzado entre repos.

Alternativas: manter o codigo em `tech-challenge-02` como referencia externa; criar um repositorio GitOps separado (R-07).

Status: aceita em 2026-08-27, informada pelo usuario. Encerra P-004.

## D-006 - Modalidade e prazo da entrega

Contexto: o enunciado diz que o Tech Challenge "em principio" deve ser desenvolvido em grupo e pede os nomes dos participantes no relatorio, mas nao traz prazo. Os itens ficaram como [INCERTO] em P-016 e P-017.

Decisao: o usuario confirmou em 2026-07-30 que a entrega e em grupo e que o prazo final e 2026-09-15. Todo planejamento e cronograma passam a usar essa data como limite.

Alternativas: tratar como entrega individual; seguir sem data definida.

Status: aceita em 2026-07-30, informada pelo usuario. Os nomes dos integrantes ainda nao foram informados (P-018).

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
