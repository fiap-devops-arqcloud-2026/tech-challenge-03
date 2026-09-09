#!/usr/bin/env bash
# ============================================================
# VALIDACAO LOCAL - roda antes de abrir um PR
# ============================================================
# Reproduz na maquina o essencial do que o CI faz, para pegar erro
# barato antes de gastar uma volta no GitHub Actions.
#
# Atualizado em 2026-09-09: as pastas terraform/bootstrap e
# terraform/environments/dev foram removidas na consolidacao do merge
# hibrido, e o script apontava para elas - ou seja, falhava sempre.
# Agora valida as TRES camadas vigentes: base, cluster e k8s.
# ============================================================

# -e  aborta no primeiro comando que falhar
# -u  trata variavel nao definida como erro
# -o pipefail  faz um pipe falhar se qualquer etapa dele falhar
set -euo pipefail

# Sobe para a raiz do repositorio, independentemente de onde o script
# foi chamado.
root_dir="$(git rev-parse --show-toplevel)"
cd "$root_dir"

# ------------------------------------------------------------
# 1. Varredura de seguranca do repositorio
# ------------------------------------------------------------
./scripts/security-check.sh

# ------------------------------------------------------------
# 2. Terraform - formatacao e sintaxe das tres camadas
# ------------------------------------------------------------
if command -v terraform >/dev/null 2>&1; then
  # fmt recursivo cobre os roots e os modulos de uma vez so.
  terraform fmt -check -recursive terraform/

  # validate precisa de init por camada: sao roots independentes.
  # -backend=false dispensa credencial da AWS, porque aqui so se
  # confere sintaxe e referencia entre modulos.
  for camada in terraform terraform/cluster terraform/k8s; do
    echo "[terraform] validando ${camada}"
    terraform -chdir="${camada}" init -backend=false -input=false >/dev/null
    terraform -chdir="${camada}" validate
  done
else
  echo "[AVISO] Terraform nao instalado; validacao HCL sera feita no CI."
fi

# ------------------------------------------------------------
# 3. Kustomize - a area GitOps renderiza?
# ------------------------------------------------------------
# Erro de indentacao ou referencia quebrada aparece aqui, antes de o
# ArgoCD tentar aplicar no cluster.
if command -v kubectl >/dev/null 2>&1; then
  echo "[kustomize] renderizando gitops/overlays/prod"
  kubectl kustomize gitops/overlays/prod >/dev/null
else
  echo "[AVISO] kubectl nao instalado; render do Kustomize sera feito no CI."
fi

# ------------------------------------------------------------
# 4. Python - sintaxe dos tres servicos
# ------------------------------------------------------------
python -m compileall -q services/analytics-service services/flag-service services/targeting-service

# ------------------------------------------------------------
# 5. Go - build e testes dos dois servicos
# ------------------------------------------------------------
if command -v go >/dev/null 2>&1; then
  for service in services/auth-service services/evaluation-service; do
    echo "[go] ${service}"
    # Subshell para o cd nao vazar para a proxima iteracao.
    (cd "$service" && go build ./... && go test -count=1 ./...)
  done
else
  echo "[AVISO] Go nao instalado; build e testes Go serao executados no CI."
fi

echo "Validacoes locais concluidas."
