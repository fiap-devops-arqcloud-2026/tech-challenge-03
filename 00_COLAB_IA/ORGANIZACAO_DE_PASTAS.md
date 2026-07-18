# ORGANIZACAO_DE_PASTAS

TL;DR: manter `00_COLAB_IA/` como memoria compartilhada e salvar cada guia HTML dentro da pasta do respectivo modulo em `docs/`.

Ultima atualizacao: 2026-07-18 12:41 -03:00, Codex.

## Estrutura atual

```text
tech-challenge-03/
|-- README.md
|-- CLAUDE.md
|-- 00_COLAB_IA/
|-- 01_ENTRADAS/
|-- 02_TRABALHO/
|-- 03_ENTREGAVEIS/
|-- 04_REFERENCIAS/
|-- docs/
|   |-- POSTECH - Tech Challenge - Fase 3.pdf
|   |-- 01_Welcome to Automacao e Seguranca na Cloud/
|   |-- 02_CI-CD/
|   |-- 03_Infraestrutura como codigo/
|   |-- 04_Seguranca em DevOps (DevSecOps)/
|   `-- 05_Seguranca na Cloud/
`-- _ARQUIVO_MORTO/
```

## Convencao de nomes

- Datas em ISO: `AAAA-MM-DD`.
- Evitar nomes como `copia`, `final-final` ou duplicatas sem versao.
- Usar `_v01`, `_v02` ou `_VIGENTE` quando houver versoes.
- Guias da Fase 3: `GUIA-ESTUDO-<Modulo>.html` dentro da pasta do modulo.

## Regras de destino

- Insumos originais: `01_ENTRADAS/` ou `docs/` quando ja fizerem parte do repo.
- Trabalho em andamento: `02_TRABALHO/`.
- Entregaveis finais: `03_ENTREGAVEIS/`.
- Referencias e materiais de apoio: `04_REFERENCIAS/`.
- Versoes antigas: `_ARQUIVO_MORTO/`.
- Contexto entre agentes: `00_COLAB_IA/`.
- Guias finais de estudo: pasta correspondente dentro de `docs/`.
