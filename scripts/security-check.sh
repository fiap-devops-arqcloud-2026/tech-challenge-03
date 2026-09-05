#!/usr/bin/env bash
set -euo pipefail

root_dir="$(git rev-parse --show-toplevel)"
cd "$root_dir"

failed=0
check() {
  local description="$1"
  local pattern="$2"
  if git grep -InE "$pattern" -- ':!scripts/security-check.sh' ':!*.example.*'; then
    echo "[ERRO] ${description}"
    failed=1
  fi
}

check "Possível AWS Access Key encontrada" 'AKIA[0-9A-Z]{16}'
check "Possível chave privada encontrada" 'BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY'
check "ID de conta legado encontrado" '891376952395'
check "Arquivo contém atribuição suspeita de segredo" '(AWS_SECRET_ACCESS_KEY|GITHUB_TOKEN|TF_API_TOKEN)[[:space:]]*[:=][[:space:]]*[A-Za-z0-9/+]{16,}'

if [[ "$failed" -ne 0 ]]; then
  exit 1
fi
echo "Verificação concluída: nenhum segredo conhecido foi encontrado."
