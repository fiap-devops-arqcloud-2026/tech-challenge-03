# ORGANIZACAO_DE_PASTAS

TL;DR: o repo e um monorepo (D-007). Codigo em `services/`, infraestrutura em `terraform/`, manifestos Kustomize em `gitops/`, pipelines em `.github/workflows/`. Toda a documentacao, incluindo a memoria compartilhada `00_COLAB_IA/`, vive dentro de `docs/`.

Ultima atualizacao: 2026-08-27 11:12 -03:00, Claude.

## Estrutura atual

```text
tech-challenge-03/
|-- README.md
|-- CLAUDE.md
|-- .gitignore
|-- services/                     # codigo dos 5 microsservicos (D-007)
|   |-- auth-service/             # Go
|   |-- evaluation-service/       # Go
|   |-- flag-service/             # Python
|   |-- targeting-service/        # Python
|   `-- analytics-service/        # Python
|-- terraform/                    # infraestrutura como codigo
|   `-- BOOTSTRAP-BACKEND-S3.md   # criacao unica do bucket de estado
|-- gitops/                       # manifestos Kustomize (D-008)
|-- .github/workflows/            # pipelines de CI e DevSecOps
`-- docs/
    |-- POSTECH - Tech Challenge - Fase 3.pdf
    |-- 01_Welcome to Automacao e Seguranca na Cloud/
    |-- 02_CI-CD/
    |-- 03_Infraestrutura como codigo/
    |-- 04_Seguranca em DevOps (DevSecOps)/
    |-- 05_Seguranca na Cloud/
    `-- 00_COLAB_IA/              # memoria compartilhada entre agentes
        |-- LEIA-PRIMEIRO.md
        |-- PENDENCIAS_E_PROXIMOS_PASSOS.md
        |-- LOG_DE_TRABALHO.md
        |-- DECISOES.md
        |-- DOSSIE_CONTEXTO.md
        |-- CHECKLIST_REQUISITOS_FASE3.md
        |-- ORGANIZACAO_DE_PASTAS.md
        |-- 01_ENTRADAS/
        |-- 02_TRABALHO/
        |-- 03_ENTREGAVEIS/
        |-- 04_REFERENCIAS/
        `-- _ARQUIVO_MORTO/
```

`terraform/`, `gitops/` e `.github/workflows/` ainda estao vazios ou inexistentes; serao preenchidos a partir de M2.

## Convencao de nomes

- Datas em ISO: `AAAA-MM-DD`.
- Evitar nomes como `copia`, `final-final` ou duplicatas sem versao.
- Usar `_v01`, `_v02` ou `_VIGENTE` quando houver versoes.
- Guias da Fase 3: `GUIA-ESTUDO-<Modulo>.html` dentro da pasta do modulo.
- Servicos: `<nome>-service`, igual ao nome usado no ECR e no Kustomize.

## Regras de destino

- Codigo de aplicacao: `services/<nome>-service/`.
- Infraestrutura: `terraform/`.
- Manifestos Kubernetes: `gitops/base/<servico>/` e `gitops/overlays/<ambiente>/`.
- Pipelines: `.github/workflows/`.
- Insumos originais: `docs/` quando ja fizerem parte do repo, ou `docs/00_COLAB_IA/01_ENTRADAS/`.
- Trabalho em andamento: `docs/00_COLAB_IA/02_TRABALHO/`.
- Entregaveis finais (relatorio, links, prints de custo): `docs/00_COLAB_IA/03_ENTREGAVEIS/`.
- Referencias e materiais de apoio: `docs/00_COLAB_IA/04_REFERENCIAS/`.
- Versoes antigas: `docs/00_COLAB_IA/_ARQUIVO_MORTO/`.
- Contexto entre agentes: `docs/00_COLAB_IA/`.
- Guias finais de estudo: pasta correspondente dentro de `docs/`.

## Nunca versionar

`terraform.tfstate` e variantes, `*.tfvars`, `.env`, chaves `.pem`/`.key`, kubeconfigs e qualquer credencial AWS. O `.gitignore` da raiz ja cobre esses padroes.
