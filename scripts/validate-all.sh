#!/usr/bin/env bash
set -euo pipefail

root_dir="$(git rev-parse --show-toplevel)"
cd "$root_dir"

./scripts/security-check.sh

if command -v terraform >/dev/null 2>&1; then
  terraform -chdir=terraform/bootstrap fmt -check -recursive
  terraform -chdir=terraform/environments/dev fmt -check -recursive
else
  echo "[AVISO] Terraform não instalado; validação HCL será feita no CI."
fi

python -m compileall -q services/analytics-service services/flag-service services/targeting-service

if command -v go >/dev/null 2>&1; then
  for service in services/auth-service services/evaluation-service; do
    (cd "$service" && go test ./...)
  done
else
  echo "[AVISO] Go não instalado; testes Go serão executados no CI."
fi

echo "Validações locais concluídas."
