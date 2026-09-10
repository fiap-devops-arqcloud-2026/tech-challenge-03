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
# O nome do interpretador muda conforme o ambiente: no Linux do CI e
# `python3`, no Windows com o launcher oficial e `py`, e em alguns
# ambientes e so `python`. Sem esta deteccao o script morria no Git Bash
# do Windows, porque o alias `python` da Microsoft Store nao executa nada
# e ainda retorna sucesso aparente.
python_bin=""
for candidato in python3 python py; do
  # -c "" so pergunta "voce roda?"; nao imprime nada e sai com 0.
  if command -v "$candidato" >/dev/null 2>&1 && "$candidato" -c "" >/dev/null 2>&1; then
    python_bin="$candidato"
    break
  fi
done

if [[ -n "$python_bin" ]]; then
  echo "[python] compilando os 3 servicos com ${python_bin}"
  # compileall so compila para bytecode: nao executa o codigo, mas
  # quebra em erro de sintaxe. E o teste mais barato que existe.
  "$python_bin" -m compileall -q services/analytics-service services/flag-service services/targeting-service
else
  echo "[AVISO] Python nao encontrado; a checagem de sintaxe sera feita no CI."
fi

# ------------------------------------------------------------
# 5. Go - build e testes dos dois servicos
# ------------------------------------------------------------
# No Windows o instalador do Go coloca o binario em "C:\Program Files\Go\bin",
# mas essa pasta so entra no PATH de terminais abertos DEPOIS da instalacao.
# Como o Git Bash costuma ja estar aberto, o `go` some sem motivo aparente.
# Esta linha acrescenta o caminho padrao ao PATH so para esta execucao.
if [[ -x "/c/Program Files/Go/bin/go.exe" ]]; then
  PATH="$PATH:/c/Program Files/Go/bin"
fi

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
