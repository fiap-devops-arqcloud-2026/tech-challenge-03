# Tech Challenge 03 - Contexto de Colaboracao

Ultima atualizacao: 2026-08-27 12:23 -03:00, Claude.

TL;DR: este repositorio e a base da terceira entrega do Tech Challenge. Os cinco modulos da Fase 3 ja foram estudados e possuem guias HTML, e o escopo esta mapeado em `docs/00_COLAB_IA/CHECKLIST_REQUISITOS_FASE3.md`. A entrega e em grupo e vence em 2026-09-15. A implementacao comecou: e um monorepo com os 5 microsservicos em `services/` (D-007) e GitOps em Kustomize (D-008). O proximo passo depende de uma acao manual do usuario: criar o bucket S3 de estado seguindo `terraform/BOOTSTRAP-BACKEND-S3.md` (P-019). Antes de trabalhar, leia `docs/00_COLAB_IA/LEIA-PRIMEIRO.md`.

## Regras essenciais

- Idioma: portugues do Brasil.
- Explicar primeiro de forma simples e depois tecnica.
- Nao inventar: marque `[INCERTO]` quando faltar confirmacao.
- Nao commitar segredos, credenciais ou dados sensiveis.
- Entradas devem ser tratadas como somente leitura.
- Registros de trabalho ficam em `docs/00_COLAB_IA/`.
- Guias de estudo ficam dentro da pasta de cada modulo em `docs/`.

## Estado atual

- Entrega em grupo, prazo final 2026-09-15 (D-006). Integrantes ainda nao informados (P-018).
- Escopo mapeado em `docs/00_COLAB_IA/CHECKLIST_REQUISITOS_FASE3.md`: 39 itens obrigatorios, 9 opcionais do enunciado e 9 sugestoes das aulas. Nenhum item obrigatorio concluido ainda.
- Monorepo (D-007): codigo em `services/`, infra em `terraform/`, manifestos em `gitops/`, pipelines em `.github/workflows/`.
- Area GitOps em Kustomize (D-008), com `base/` por servico e `overlays/` por ambiente.
- Microsservicos em duas stacks: Go (`auth`, `evaluation`) e Python (`flag`, `targeting`, `analytics`).
- Toda a configuracao dos servicos vem de variaveis de ambiente; nao ha segredo hardcoded (F-011).
- Conta pessoal AWS, nao AWS Academy; regiao `us-east-2`; IAM pode ser criado via Terraform.
- `terraform/`, `gitops/` e `.github/workflows/` ainda estao vazios ou inexistentes.
- Bloqueio atual: P-019, criar o bucket S3 de estado. E tarefa manual do usuario e trava todo o Terraform.
- Fonte principal da Fase 3: `docs/POSTECH - Tech Challenge - Fase 3.pdf`.

## Ponteiros

- Protocolo de sessao: `docs/00_COLAB_IA/LEIA-PRIMEIRO.md`
- Checklist de requisitos: `docs/00_COLAB_IA/CHECKLIST_REQUISITOS_FASE3.md`
- Dossie do projeto: `docs/00_COLAB_IA/DOSSIE_CONTEXTO.md`
- Decisoes: `docs/00_COLAB_IA/DECISOES.md`
- Pendencias: `docs/00_COLAB_IA/PENDENCIAS_E_PROXIMOS_PASSOS.md`
- Log: `docs/00_COLAB_IA/LOG_DE_TRABALHO.md`
- Organizacao: `docs/00_COLAB_IA/ORGANIZACAO_DE_PASTAS.md`
- Bootstrap do backend S3: `terraform/BOOTSTRAP-BACKEND-S3.md`
