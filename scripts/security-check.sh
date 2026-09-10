#!/usr/bin/env bash
# ============================================================
# VARREDURA DE SEGREDOS - roda antes de qualquer commit
# ============================================================
# Procura no conteudo dos arquivos RASTREADOS pelo Git padroes que nunca
# deveriam estar versionados. E a ultima linha de defesa antes de um
# segredo virar historico publico - depois de commitado, remover do
# arquivo NAO remove do historico.
#
# Corrigido em 2026-09-09 (F-048/P-049): a regra de "conta legada"
# apontava para 891376952395, que e a conta ATUAL do projeto. Como esse
# numero aparece legitimamente no registry do ECR, na ARN da role de CI
# e no nome do bucket de estado, o script reprovava sempre - e por
# tabela derrubava o validate-all.sh, que o executa no primeiro passo.
# Um verificador que acusa 100% das execucoes deixa de ser verificador:
# vira ruido que se aprende a ignorar.
# ============================================================

# -e  aborta no primeiro comando que falhar
# -u  variavel nao definida vira erro em vez de string vazia
# -o pipefail  o pipe inteiro falha se qualquer etapa falhar
set -euo pipefail

# Sobe para a raiz do repositorio, para o script funcionar chamado de
# qualquer pasta.
root_dir="$(git rev-parse --show-toplevel)"
cd "$root_dir"

# Acumulador: vira 1 na primeira regra violada e decide o codigo de saida.
failed=0

# ------------------------------------------------------------
# FUNCAO check - aplica uma regra e registra a falha
# ------------------------------------------------------------
# $1 = frase explicando o que foi encontrado
# $2 = expressao regular procurada
check() {
  local description="$1"
  local pattern="$2"

  # git grep varre apenas arquivos rastreados - o que esta no .gitignore
  # nao interessa, porque nao sobe para o repositorio.
  #   -I  ignora binarios (evita lixo no terminal)
  #   -n  mostra o numero da linha
  #   -E  expressao regular estendida
  # As duas exclusoes finais evitam dois falsos positivos garantidos:
  # este proprio script (que contem os padroes) e os arquivos .example,
  # que existem justamente para mostrar o formato de um valor.
  if git grep -InE "$pattern" -- ':!scripts/security-check.sh' ':!*.example.*'; then
    echo "[ERRO] ${description}"
    failed=1
  fi
}

# ------------------------------------------------------------
# REGRAS
# ------------------------------------------------------------

# Chave de acesso da AWS. O prefixo AKIA seguido de 16 maiusculas e o
# formato oficial e nao tem como aparecer por acaso.
check "Possivel AWS Access Key encontrada" 'AKIA[0-9A-Z]{16}'

# Cabecalho de chave privada (RSA, EC ou OpenSSH). Se aparecer, alguem
# commitou um arquivo .pem ou .key.
check "Possivel chave privada encontrada" 'BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY'

# Conta do AWS Academy usada na Fase 2. Este numero NAO deve aparecer na
# Fase 3, que roda em conta pessoal (D-016). Se aparecer, e sinal de
# arquivo copiado da fase anterior sem revisao - o risco real nao e o
# numero em si, e a configuracao velha que veio junto (LabRole, endpoint
# antigo, ARN que nao existe mais).
#
# A conta ATUAL, 891376952395, e propositalmente NAO verificada aqui:
# ela precisa aparecer no registry do ECR, na ARN da role do OIDC e no
# nome do bucket de estado. ID de conta nao e credencial - sem chave ou
# federacao, conhece-lo nao da acesso a nada.
check "ID da conta da Fase 2 (AWS Academy) encontrado" '557849629939'

# Atribuicao direta de um valor longo a uma variavel de segredo conhecida.
# Pega o caso classico de "AWS_SECRET_ACCESS_KEY=wJalr..." em .env ou YAML.
check "Arquivo contem atribuicao suspeita de segredo" '(AWS_SECRET_ACCESS_KEY|GITHUB_TOKEN|TF_API_TOKEN)[[:space:]]*[:=][[:space:]]*[A-Za-z0-9/+]{16,}'

# ------------------------------------------------------------
# RESULTADO
# ------------------------------------------------------------
# Sair com 1 e o que faz o validate-all.sh (set -e) parar aqui e o CI
# marcar o job como vermelho.
if [[ "$failed" -ne 0 ]]; then
  exit 1
fi

echo "Verificacao concluida: nenhum segredo conhecido foi encontrado."
