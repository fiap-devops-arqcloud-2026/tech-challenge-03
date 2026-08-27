# DOSSIE_CONTEXTO

TL;DR: repo da terceira entrega do Tech Challenge. Os cinco modulos da Fase 3 foram estudados e possuem guias HTML ao lado dos PDFs; o escopo esta em `CHECKLIST_REQUISITOS_FASE3.md`. Entrega em grupo, prazo final 2026-09-15. A implementacao comecou: monorepo com os 5 microsservicos em `services/` (D-007) e GitOps em Kustomize (D-008). Proximo bloqueio: criar o bucket S3 de estado (P-019).

Ultima atualizacao: 2026-08-27 11:12 -03:00, Claude.

## 1 Objetivo

Construir a terceira entrega do Tech Challenge usando o ToggleMaster como base, com infraestrutura AWS por Terraform, pipelines DevSecOps, imagens no ECR e deploy GitOps via ArgoCD no EKS.

## 2 Regras/preferencias

- Responder em portugues do Brasil.
- Explicar de forma simples antes da parte tecnica.
- Usar datas absolutas.
- Nao registrar segredos, credenciais ou dados sensiveis.
- Manter contexto compartilhado em `docs/00_COLAB_IA/`.
- Tratar materiais de `tech-challenge-02` como fonte de leitura, nao como destino de edicao.

## 3 Contexto

- Fase 2 construiu o ToggleMaster com 5 microsservicos: `auth`, `flag`, `targeting`, `evaluation`, `analytics`.
- Fase 3 pede automatizar infraestrutura e ciclo de vida dos 5 microsservicos.
- Usuario informou que sera usada conta pessoal AWS, nao AWS Academy.
- Em 2026-07-17 foram analisados os materiais da Fase 2 em `C:\Users\Gabriel\Documents\GitHub\tech-challenge-02\docs\Material aulas`.
- Em 2026-07-18 o usuario rejeitou e apagou os guias Markdown anteriores. O estudo foi reiniciado pela Fase 3, um modulo por vez.
- O novo guia usa como referencia visual e didatica o HTML `GUIA-ESTUDO-Introducao-a-Containers.html`.
- Em 2026-07-18 os cinco modulos da Fase 3 receberam guias HTML no novo padrao, concluindo a trilha de estudos.
- Em 2026-07-18 o estado consolidado foi publicado no branch `dev`; o commit principal dos guias e `200cdf5`.
- Em 2026-07-30 o enunciado foi relido por completo e virou o checklist `CHECKLIST_REQUISITOS_FASE3.md`: 39 itens obrigatorios (O-01 a O-39), 9 opcionais do proprio enunciado (R-01 a R-09) e 9 sugestoes derivadas das aulas (S-01 a S-09).
- Em 2026-07-30 o usuario confirmou que a entrega e em grupo e que o prazo final e 2026-09-15 (D-006).
- Em 2026-08-26 o usuario reorganizou o repo por conta propria: copiou os 5 microsservicos para `services/`, criou `.gitignore`, criou os esqueletos `terraform/` e `gitops/` e moveu `00_COLAB_IA/` para dentro de `docs/`. Essa mudanca ficou sem registro no log ate 2026-08-27.
- Em 2026-08-27 o usuario confirmou que monorepo e Kustomize foram decisoes dele (D-007 e D-008), o descompasso entre documentacao e disco foi corrigido e o passo a passo do bucket de estado foi escrito em `terraform/BOOTSTRAP-BACKEND-S3.md`.
- Os 5 microsservicos usam duas stacks: Go em `auth` e `evaluation`; Python em `flag`, `targeting` e `analytics` (F-008).
- Nenhum servico tem credencial hardcoded; tudo vem de variavel de ambiente (F-011).
- Regiao AWS do projeto: `us-east-1`, herdada da Fase 2 (F-012).

## 4 Arquivos/caminhos

- Repo atual: `C:\Users\Gabriel\Documents\GitHub\tech-challenge-03`
- Visao geral do repositorio: `README.md`
- Fonte Fase 2: `C:\Users\Gabriel\Documents\GitHub\tech-challenge-02\docs\Material aulas`
- Codigo dos microsservicos: `services/<nome>-service/`
- Bootstrap do backend de estado: `terraform/BOOTSTRAP-BACKEND-S3.md`
- Checklist de requisitos da entrega: `docs/00_COLAB_IA/CHECKLIST_REQUISITOS_FASE3.md`
- Contexto compartilhado: `docs/00_COLAB_IA/`
- Guias de estudo, um por modulo, dentro da pasta de cada modulo em `docs/`.

## 5 Processos

- Para estudo de PDFs, extrair conteudo com `pypdf` e sintetizar por modulo/aula.
- Para guias, usar HTML autocontido no padrao indicado pelo usuario: introducao leiga, glossario, fichas com finalidade/caso de uso/aplicacao no ToggleMaster e resumo.
- Para mudancas no repo, verificar, commitar e fazer push quando solicitado.
- Antes de qualquer commit, varrer o diff em busca de credenciais e arquivos sensiveis.

## 6 Decisoes

- D-001: o repo `tech-challenge-03` e o destino dos guias e do contexto atual.
- D-002: decisao anterior sobre guias Markdown, substituida por D-005.
- D-003: estrategia tecnica preferencial da Fase 3: Terraform modular, GitHub Actions, ECR, ArgoCD e EKS.
- D-004: nao copiar PDFs da Fase 2; usar como fonte externa e registrar guias derivados no repo da Fase 3.
- D-005: novos guias ficam em HTML dentro da pasta de cada modulo; substitui D-002 para o trabalho atual.
- D-006: entrega em grupo, prazo final 2026-09-15, confirmado pelo usuario.
- D-007: o codigo dos 5 microsservicos vive neste monorepo em `services/`; a area GitOps e a pasta `gitops/`.
- D-008: a area GitOps usa Kustomize, com `base/` por servico e `overlays/` por ambiente.

## 7 Pendencias

- P-019: criar o bucket S3 de estado seguindo `terraform/BOOTSTRAP-BACKEND-S3.md`. Bloqueia todo o Terraform.
- P-018: obter os nomes dos integrantes do grupo para o relatorio de entrega.
- P-003: escrever o Terraform da Fase 3 assim que o bucket existir.
- P-020 a P-023: modulos Terraform, esqueleto Kustomize, OIDC no CI e local dos segredos de banco.
- P-006: roteiro do video final.
- P-007, P-009, P-011, P-013, P-015: revisao dos cinco guias HTML pelo usuario.

## 8 Glossario

- IaC: Infrastructure as Code, infraestrutura declarada em codigo.
- CI/CD: integracao, entrega e/ou implantacao continua.
- GitOps: Git como fonte da verdade do estado desejado do ambiente.
- Bootstrap: recurso criado uma unica vez fora do IaC para quebrar dependencia circular; no projeto, o bucket de estado.
- Estado (tfstate): mapa do que o Terraform criou; contem segredos e nunca fica local nem no Git.
- Kustomize: sobreposicao de manifestos Kubernetes sem templating, nativo do `kubectl` e do ArgoCD.
- EKS: Kubernetes gerenciado da AWS.
- ECR: registro de imagens Docker da AWS.
- RDS: banco relacional gerenciado da AWS.
- SQS: fila gerenciada da AWS.
- ArgoCD: ferramenta GitOps para sincronizar Kubernetes a partir do Git.
- IAM: gerenciamento de identidades e permissoes.
- OIDC: federacao de identidade que permite ao CI assumir role na AWS sem chave estatica.
- KMS: servico de gerenciamento de chaves criptograficas.
- CSPM: monitoramento e correcao da postura de seguranca da infraestrutura cloud.
- CWPP: protecao de workloads antes e durante a execucao.
- CASB: controle de politicas entre usuarios e aplicacoes SaaS.

## 9 Cuidados

- Nunca commitar `.env`, chaves AWS, kubeconfigs sensiveis ou senhas.
- `terraform.tfstate` nao deve ficar local no repo nem ser versionado.
- Access key e pessoal: nenhum integrante compartilha a sua com o grupo.
- Ao substituir arquivo, mover versao antiga para `_ARQUIVO_MORTO/` e registrar no log.
- EKS + 3 RDS + ElastiCache pesam na fatura da conta pessoal; ver S-09 sobre `destroy` entre sessoes.

## 10 Resumo das conversas

- 2026-07-16: analisado PDF principal da Fase 3 e criado checklist de entregaveis.
- 2026-07-16: estudados os modulos Welcome, CI/CD e Infraestrutura como Codigo da Fase 3.
- 2026-07-17: estudados materiais da Fase 2 e criados guias por modulo.
- 2026-07-18: guias anteriores rejeitados e apagados pelo usuario; estudo reiniciado modulo por modulo e criados os cinco guias HTML da Fase 3.
- 2026-07-18: cinco guias, README e contexto consolidados no commit `200cdf5` e enviados para `origin/dev`.
- 2026-07-30: enunciado relido, criado o checklist de requisitos obrigatorios e opcionais e confirmadas as condicoes de entrega (grupo, 2026-09-15).
- 2026-08-26: usuario reorganizou o repo, copiou os microsservicos e criou o `.gitignore`, sem registrar no log.
- 2026-08-27: descompasso identificado e corrigido; D-007 e D-008 registradas; criado o passo a passo do bucket de estado; cronograma rebaseado.

## 11 Memoria interna <-> espelho

Essenciais espelhados aqui: objetivo da Fase 3, uso de AWS pessoal em `us-east-1`, processo de estudo modulo por modulo, padrao HTML dos guias, condicoes de entrega (grupo, prazo 2026-09-15), estrutura de implementacao (monorepo + Kustomize) e o bootstrap do bucket de estado como unica excecao a regra "se nao esta no codigo, nao existe".

## 12 Instrucoes iniciais para o proximo assistente

Leia `LEIA-PRIMEIRO.md`, depois `PENDENCIAS_E_PROXIMOS_PASSOS.md`, o topo de `LOG_DE_TRABALHO.md` e `CHECKLIST_REQUISITOS_FASE3.md`. Os estudos estao concluidos e as decisoes estruturais fechadas. O trabalho agora e implementacao, na ordem: bucket S3 de estado (P-019, tarefa manual do usuario), depois `terraform/backend.tf` e VPC, depois EKS/RDS/ElastiCache/DynamoDB/SQS/ECR, depois CI DevSecOps, depois ArgoCD/Kustomize, e por fim video e relatorio. Confirme com o usuario se o bucket ja existe antes de escrever qualquer `backend "s3"`.
