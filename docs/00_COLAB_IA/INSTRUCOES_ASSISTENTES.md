# Instrucoes para assistentes de IA

Este arquivo reune as instrucoes detalhadas que antes ficavam em `CLAUDE.md` e
`AGENTS.md`, na raiz do repositorio. Elas foram movidas para ca em 2026-09-11
durante a reorganizacao da documentacao. Em 2026-09-14, o repositorio continua
privado. O `CLAUDE.md` curto da raiz apenas aponta para este arquivo.

**Consequencia pratica:** o `CLAUDE.md` da raiz deve ser mantido, pois permite
que o Claude Code encontre automaticamente estas instrucoes.

A documentacao do projeto em si esta no [README](../../README.md), em
[docs/ARQUITETURA.md](../ARQUITETURA.md) e em [docs/OPERACAO.md](../OPERACAO.md).

---

## Parte 1 - contexto de colaboracao (era o CLAUDE.md)

## Estado atual - 2026-09-14 10:20 -03:00, Codex

TL;DR: trabalhar na `dev` e promover mudancas humanas por PR para a `main`
(D-020). `dev` e `main` locais possuem a mesma arvore no commit de merge
`c60e792`; `origin/dev` esta apenas um merge commit atras de `origin/main`.
A AWS foi integralmente desmontada em 2026-09-11 e revalidada vazia em
2026-09-14. O relatorio FIAP foi refeito como versao preliminar curta; faltam o
video, a confirmacao dos participantes e o acesso do avaliador ao repo privado.

O CI de integracao e a validacao Terraform estao verdes no conteudo atual. A
ultima publicacao do `flag-service` falhou somente na autenticacao OIDC porque
a role, o provedor e o ECR foram removidos no encerramento da AWS. Antes de um
novo ensaio, recriar base, imagens, cluster e k8s, atualizar o endpoint Redis,
executar schemas/seed e capturar a nova tag sendo sincronizada pelo ArgoCD.

Os pushes automaticos de tags GitOps diretamente na `main` sao a excecao
intencional D-021. O GitHub ainda nao possui protecao de branch; a disciplina
dev -> PR -> main e processual, nao imposta pela plataforma.

## Regra de trabalho vigente - 2026-09-09 18:09 -03:00, Codex

TL;DR: por instrucao explicita do usuario em 2026-09-09, trabalhar SOMENTE na dev; promocao para main por PR dev -> main e merge (D-020). Ler tambem AGENTS.md.

Conferencia atual: main/dev/remotas em 5b8cd86, sem commits ou arquivos exclusivos; checkout ja transferido para dev, com documentos locais preservados. Os pushes automaticos GitOps ainda precisam ser adaptados (P-052); nenhuma mudanca de workflow/publicacao foi feita nesta analise.


## Revalidacao vigente - 2026-09-09 17:57 -03:00, Codex

TL;DR: main/dev/origin sincronizadas em 5b8cd86; a nota das 13:31 abaixo e historica. EKS default corrigido para 1.34; parametros do seed corrigidos e schemas documentados. Persistem CI ignore-unfixed, bootstrap ArgoCD, Secret/chave, Redis placeholder e documentacao divergente. Ler [revalidacao](03_ENTREGAVEIS/REVALIDACAO_AUDITORIA_FIAP_2026-09-09_v01.md) e topo atualizado de LOG/PENDENCIAS. Fluxo preferido D-019: dev -> PR -> main.


## Aviso de continuidade - auditoria 2026-09-09

TL;DR: o resumo historico abaixo esta desatualizado. Leia primeiro o topo de docs/00_COLAB_IA/LOG_DE_TRABALHO.md e PENDENCIAS_E_PROXIMOS_PASSOS.md, atualizados pela auditoria. Fonte: [parecer](03_ENTREGAVEIS/AUDITORIA_FIAP_2026-09-09_v01.md).
Ultima atualizacao deste aviso: 2026-09-09 13:31 -03:00, Codex.

A implementacao principal e os workflows existem; falta corrigir bootstrap ArgoCD, schemas/seed e filtro CRITICAL, atualizar documentacao e ensaiar no EKS. Diretriz D-019: dev -> PR -> main; dev precisa receber os 19 commits que ja estao em main. Auditoria nao fez checkout, merge, commit, push ou apply. P-049 consolida os documentos antigos preservados abaixo.

## Contexto anterior preservado


Ultima atualizacao: 2026-08-27 14:05 -03:00, Claude.

TL;DR: este repositorio e a base da terceira entrega do Tech Challenge. Os cinco modulos da Fase 3 ja foram estudados e possuem guias HTML, e o escopo esta mapeado em `docs/00_COLAB_IA/CHECKLIST_REQUISITOS_FASE3.md`. A entrega e em grupo e vence em 2026-09-15. A implementacao comecou: e um monorepo com os 5 microsservicos em `services/` (D-007) e GitOps em Kustomize (D-008). O bucket S3 de estado ja existe (`togglemaster-tfstate-891376952395-us-east-2-an`, `us-east-2`). O proximo passo e escrever o Terraform, aguardando o usuario aprovar o plano (P-025). Antes de trabalhar, leia `docs/00_COLAB_IA/LEIA-PRIMEIRO.md`.

## Regras essenciais

- Idioma: portugues do Brasil.
- Explicar primeiro de forma simples e depois tecnica.
- **Comentar linha a linha todo codigo criado** (Terraform, YAML, workflows, scripts), explicando o que cada linha faz e por que esta ali. Padrao pedido pelo usuario em 2026-08-27 e ja usado nos manifestos da Fase 2.
- Nao inventar: marque `[INCERTO]` quando faltar confirmacao.
- Nao commitar segredos, credenciais ou dados sensiveis.
- Entradas devem ser tratadas como somente leitura.
- Registros de trabalho ficam em `docs/00_COLAB_IA/`.
- Guias de estudo ficam dentro da pasta de cada modulo em `docs/`.

## Estado atual - 2026-09-09

**Placar:** 24 obrigatorios comprovados, 6 escritos e validados sem apply,
9 nao iniciados - e os 9 sao, todos, video e relatorio. Nenhum requisito
tecnico do enunciado esta em aberto. Detalhe item a item em
`docs/00_COLAB_IA/CHECKLIST_REQUISITOS_FASE3.md`.

**Fatos que valem para qualquer sessao:**

- Entrega em grupo, prazo final 2026-09-15 (D-006). Os 5 integrantes do
  Grupo 203 estao na tabela do `README.md`; falta so o usuario confirmar
  que a composicao nao mudou (P-018).
- Monorepo (D-007): codigo em `services/`, infra em `terraform/`,
  manifestos em `gitops/`, pipelines em `.github/workflows/`.
- Microsservicos em duas stacks: Go (`auth`, `evaluation`) e Python
  (`flag`, `targeting`, `analytics`).
- Conta pessoal AWS, nao AWS Academy; regiao `us-east-2`; IAM criado por
  Terraform (D-016, R-05). **Nao ha chave estatica em lugar nenhum**: o
  CI usa OIDC (S-01) e os pods usam IRSA (S-06).
- Bucket de estado: `togglemaster-tfstate-891376952395-us-east-2-an`.
- Tags padrao de todo recurso: `project = fiap`, `phase = 3`, em
  MINUSCULAS (D-009), via `default_tags`.

**Terraform em TRES camadas com estado separado (D-017):**

| Camada | Contem | Situacao |
|---|---|---|
| `terraform/` | VPC, 5 ECR, SQS + DLQ, DynamoDB, OIDC do CI | **aplicada** em 2026-09-07, 33 recursos |
| `terraform/cluster/` | EKS, node group, 2 RDS, ElastiCache, IRSA | escrita e validada, `plan` com 35 recursos, apply pendente |
| `terraform/k8s/` | 5 Secrets, StorageClass gp3, ArgoCD + Application | escrita e validada, apply pendente |

**O que ja rodou de verdade:** os 5 pipelines verdes na main e na dev; as
5 imagens no ECR com tag `v1.0.0-<commit>`; o bloqueio por CRITICAL
testado na pratica (um CVE do `x/crypto` derrubou o pipeline e o job de
imagem ficou `skipped`); e 5 commits `chore(gitops)` feitos pelo proprio
pipeline atualizando a tag.

**Correcoes desta rodada (2026-09-09):** `ignore-unfixed` desligado nos 4
scans Trivy com excecoes nominais em `.trivyignore` (F-042); bootstrap do
ArgoCD documentado em duas etapas por causa do CRD (F-043); disputa da
`SERVICE_API_KEY` resolvida com `ignore_changes` (F-046); `REDIS_URL`
com comando pronto no runbook (F-047); `security-check.sh` deixou de
reprovar a conta atual, e por isso o `validate-all.sh` roda inteiro pela
primeira vez; documentacao alinhada ao codigo (F-048).

**Nos EKS:** 2 x `c7i-flex.large`. O `t3.medium` do plano original foi
recusado pela conta como nao elegivel ao Free Tier (F-023). Versao do
EKS: **1.34**, e nao 1.31 - fora do suporte padrao o preco vai de
US$ 0,10/h para US$ 0,60/h.

**Desvios conscientes que precisam constar no relatorio (O-38):** 2 RDS
em vez de 3, com o terceiro banco em pod (D-015, liberado pelo
professor); sem Ingress nem Load Balancer (D-012, F-018); External
Secrets Operator cortado, com os Secrets criados por
`terraform/k8s/secrets.tf` (D-018).

**Fluxo de Git (D-020):** trabalho humano so na `dev`; promocao para a
`main` por PR. A `main` tambem recebe commits do robo do CI, que atualiza
a tag da imagem - por isso, **sincronize a `dev` antes de comecar**.

Fonte principal da Fase 3: `docs/POSTECH - Tech Challenge - Fase 3.pdf`.

## Ponteiros

- Protocolo de sessao: `docs/00_COLAB_IA/LEIA-PRIMEIRO.md`
- Checklist de requisitos: `docs/00_COLAB_IA/CHECKLIST_REQUISITOS_FASE3.md`
- Dossie do projeto: `docs/00_COLAB_IA/DOSSIE_CONTEXTO.md`
- Decisoes: `docs/00_COLAB_IA/DECISOES.md`
- Pendencias: `docs/00_COLAB_IA/PENDENCIAS_E_PROXIMOS_PASSOS.md`
- Log: `docs/00_COLAB_IA/LOG_DE_TRABALHO.md`
- Organizacao: `docs/00_COLAB_IA/ORGANIZACAO_DE_PASTAS.md`
- Bootstrap do backend S3: `terraform/BOOTSTRAP-BACKEND-S3.md`
- Runbook da sessao (subir, semear, gravar, derrubar): `docs/OPERACAO.md`
- Guia de gravacao (o que a FIAP quer ver e como mostrar): `docs/00_COLAB_IA/_ARQUIVO_MORTO/GUIA_GRAVACAO.md`
- Relatorio de entrega (rascunho + PDF gerado): `docs/RELATORIO_DE_ENTREGA.md`
- Contrato de Secrets entre Terraform e GitOps: `gitops/SECRETS-CONTRATO.md`
- Excecoes de seguranca com justificativa: `.trivyignore`
- Instrucoes para agentes (regra da branch dev): `AGENTS.md`


---

## Parte 2 - regras de trabalho dos agentes (era o AGENTS.md)

TL;DR: trabalhar somente na branch dev; promover para main apenas por PR dev -> main e merge.
Ultima atualizacao: 2026-09-09 18:09 -03:00, Codex.
Fonte: instrucao explicita do usuario em 2026-09-09; D-020 em docs/00_COLAB_IA/DECISOES.md.

- Ler docs/00_COLAB_IA/LEIA-PRIMEIRO.md, topo de PENDENCIAS_E_PROXIMOS_PASSOS.md e LOG_DE_TRABALHO.md antes de trabalhar.
- Antes de editar, conferir git status e a branch atual. Usar dev, preservando alteracoes locais; nao criar commits nem fazer push direto na main.
- Promocao para main: validar dev, abrir PR dev -> main, revisar e fazer merge. Nao promover branches auxiliares diretamente para main sem nova instrucao do usuario.
- A regra de fluxo nao e, por si so, uma ordem para publicar ou fazer merge nesta sessao.
- Depois de um merge, conferir main/dev e sincronizar dev sem descartar trabalho.
- CI GitOps ainda possui pushes diretos na main; isso esta pendente de adaptacao em P-052. Nao afirmar que a politica ja esta imposta pela configuracao remota.
- A branch dev nao implica criar outro ambiente AWS: o ambiente de infraestrutura continua prod.
- Preservar fontes, segredos fora do Git e registros anteriores. Documentar trabalho e verificar antes de encerrar.


