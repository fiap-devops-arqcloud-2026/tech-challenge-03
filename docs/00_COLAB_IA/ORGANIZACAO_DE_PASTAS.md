# ORGANIZACAO_DE_PASTAS

TL;DR: monorepo (D-007). Código em `services/`, infraestrutura em `terraform/`, manifestos em `gitops/`, pipelines em `.github/workflows/`, documentação em `docs/`. Esta pasta guarda a memória de trabalho; o que foi substituído vai para `_ARQUIVO_MORTO/` com data no nome.

Última atualização: 2026-09-15 19:03 -03:00, Claude. Substitui [_ARQUIVO_MORTO/ORGANIZACAO_DE_PASTAS_2026-08-27.md](_ARQUIVO_MORTO/ORGANIZACAO_DE_PASTAS_2026-08-27.md).

## Estrutura em 2026-09-15

```text
tech-challenge-03/
├── README.md, SECURITY.md, .gitignore, .env.example, .trivyignore, .pylintrc, pyproject.toml
├── docker-compose.yaml, docker-compose.integration.yaml
├── .github/workflows/      # 5 chamadores, 2 reutilizáveis, Terraform Check, Compose Integration
├── services/               # 5 microsserviços (READMEs herdados da Fase 2)
├── infra/                  # script de init do Postgres local do Compose
├── scripts/                # test-compose.sh e integration/ (usados pelo CI), validate-all.sh, security-check.sh
├── terraform/              # camada base; cluster/ e k8s/ são as outras duas; modules/
├── gitops/                 # base/ e overlays/prod/, README.md, SECRETS-CONTRATO.md
└── docs/
    ├── GUIA_DE_REPRODUCAO.md, ARQUITETURA.md, RELATORIO_DE_ENTREGA.md
    ├── POSTECH - Tech Challenge - Fase 3.pdf
    ├── apresentacao/       # ToggleMaster_Fase3.pptx
    ├── evidencias/         # estimativa-custos-aws-2026-09-11.png
    ├── aulas-fiap/         # 01_ a 05_, PDFs e guias HTML de estudo
    └── 00_COLAB_IA/
        ├── LEIA-PRIMEIRO.md, INSTRUCOES_ASSISTENTES.md, ORGANIZACAO_DE_PASTAS.md
        ├── PENDENCIAS_E_PROXIMOS_PASSOS.md, DECISOES.md, LOG_DE_TRABALHO.md
        └── _ARQUIVO_MORTO/ # só leitura
```

As pastas `00_COLAB_IA/02_TRABALHO/` e `03_ENTREGAVEIS/` deixaram de existir em 2026-09-15.

## Regras de destino

| O quê | Onde | Regra |
|---|---|---|
| Documento público | `docs/` | Nome em `MAIUSCULAS_COM_UNDERSCORE.md`; sem IA nem códigos internos |
| Material de aula da FIAP | `docs/aulas-fiap/<nn>_<Módulo>/` | Continua versionado por decisão do usuário |
| Enunciado | `docs/` | Mesmo nome do PDF original |
| Evidência datada (captura, estimativa) | `docs/evidencias/` | Data ISO no nome |
| Memória de trabalho | `docs/00_COLAB_IA/` | Pode citar IA e códigos internos |
| Versão substituída | `docs/00_COLAB_IA/_ARQUIVO_MORTO/` | Sufixo `_AAAA-MM-DD`; conteúdo nunca editado |
| Script | `scripts/` | Só se executável e em uso; obsoleto vai para o arquivo morto |
| Saída de geradores e rascunho | `output/`, `tmp/` | Ignorados pelo `.gitignore` |

Nunca versionar: `terraform.tfstate` e variantes, `*.tfvars`, `*.tfplan`, `.env`, chaves, kubeconfig, travas `~$*` do Office ou qualquer credencial.

## Registro de 2026-09-15: caminho antigo → novo

Movimentos feitos com `git mv` no commit 3317204, separado das escritas para preservar o `git log --follow`. Na tabela, `_ARQUIVO_MORTO/` abrevia `docs/00_COLAB_IA/_ARQUIVO_MORTO/` e `00_COLAB_IA/` abrevia `docs/00_COLAB_IA/`. As entradas antigas de [LOG_DE_TRABALHO.md](LOG_DE_TRABALHO.md) e [DECISOES.md](DECISOES.md) continuam citando os caminhos da época, de propósito, porque histórico não se reescreve: esta tabela é o de-para para resolvê-los.

| Caminho antigo | Caminho novo |
|---|---|
| `docs/01_Welcome to Automação e Segurança na Cloud/` | `docs/aulas-fiap/01_Welcome to Automação e Segurança na Cloud/` |
| `docs/02_CI-CD/` | `docs/aulas-fiap/02_CI-CD/` |
| `docs/03_Infraestrutura como código/` | `docs/aulas-fiap/03_Infraestrutura como código/` |
| `docs/04_Segurança em DevOps (DevSecOps)/` | `docs/aulas-fiap/04_Segurança em DevOps (DevSecOps)/` |
| `docs/05_Segurança na Cloud/` | `docs/aulas-fiap/05_Segurança na Cloud/` |
| `docs/OPERACAO.md` | `_ARQUIVO_MORTO/OPERACAO_2026-09-15.md` (substituído por `docs/GUIA_DE_REPRODUCAO.md`) |
| `terraform/BOOTSTRAP-BACKEND-S3.md` | `_ARQUIVO_MORTO/BOOTSTRAP-BACKEND-S3_2026-08-27.md` (absorvido pela seção 3 do guia) |
| `scripts/build-report-fase3.py` | `_ARQUIVO_MORTO/build-report-fase3_2026-09-14.py` |
| `scripts/capturar-estimativa-aws.cjs` | `_ARQUIVO_MORTO/capturar-estimativa-aws_2026-09-11.cjs` |
| `00_COLAB_IA/PENDENCIAS_E_PROXIMOS_PASSOS.md` | `_ARQUIVO_MORTO/PENDENCIAS_E_PROXIMOS_PASSOS_2026-09-11.md` (novo arquivo curto no lugar) |
| `00_COLAB_IA/DOSSIE_CONTEXTO.md` | `_ARQUIVO_MORTO/DOSSIE_CONTEXTO_2026-09-11.md` |
| `00_COLAB_IA/CHECKLIST_REQUISITOS_FASE3.md` | `_ARQUIVO_MORTO/CHECKLIST_REQUISITOS_FASE3_2026-09-09.md` |
| `00_COLAB_IA/PLANO_GRAVACAO_2026-09-15.md` | `_ARQUIVO_MORTO/PLANO_GRAVACAO_2026-09-15.md` |
| `00_COLAB_IA/ORGANIZACAO_DE_PASTAS.md` | `_ARQUIVO_MORTO/ORGANIZACAO_DE_PASTAS_2026-08-27.md` (este arquivo no lugar) |
| `00_COLAB_IA/INSTRUCOES_ASSISTENTES.md` | `_ARQUIVO_MORTO/INSTRUCOES_ASSISTENTES_2026-09-14.md` (novo arquivo no lugar) |
| `00_COLAB_IA/02_TRABALHO/auditoria-2026-09-09/` | `_ARQUIVO_MORTO/auditoria-2026-09-09/` |
| `00_COLAB_IA/03_ENTREGAVEIS/AUDITORIA_FIAP_2026-09-09_v01.md` | `_ARQUIVO_MORTO/AUDITORIA_FIAP_2026-09-09_v01.md` |
| `00_COLAB_IA/03_ENTREGAVEIS/REVALIDACAO_AUDITORIA_FIAP_2026-09-09_v01.md` | `_ARQUIVO_MORTO/REVALIDACAO_AUDITORIA_FIAP_2026-09-09_v01.md` |
| `docs/apresentacao/~$ToggleMaster_Fase3.pptx` | removido do Git (trava do PowerPoint) |
