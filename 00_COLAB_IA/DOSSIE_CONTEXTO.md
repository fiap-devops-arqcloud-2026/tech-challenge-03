# DOSSIE_CONTEXTO

TL;DR: repo da terceira entrega do Tech Challenge. Os cinco modulos da Fase 3 foram estudados e possuem guias HTML ao lado dos PDFs. A implementacao aguarda pedido explicito.

Ultima atualizacao: 2026-07-18 12:46 -03:00, Codex.

## 1 Objetivo

Construir a terceira entrega do Tech Challenge usando o ToggleMaster como base, com infraestrutura AWS por Terraform, pipelines DevSecOps, imagens no ECR e deploy GitOps via ArgoCD no EKS.

## 2 Regras/preferencias

- Responder em portugues do Brasil.
- Explicar de forma simples antes da parte tecnica.
- Usar datas absolutas.
- Nao registrar segredos, credenciais ou dados sensiveis.
- Manter contexto compartilhado em `00_COLAB_IA/`.
- Tratar materiais de `tech-challenge-02` como fonte de leitura, nao como destino de edicao.

## 3 Contexto

- Fase 2 construiu o ToggleMaster com 5 microsservicos: `auth`, `flag`, `targeting`, `evaluation`, `analytics`.
- Fase 3 pede automatizar infraestrutura e ciclo de vida dos 5 microsservicos.
- Usuario informou que sera usada conta pessoal AWS, nao AWS Academy.
- Em 2026-07-17 foram analisados os materiais da Fase 2 em `C:\Users\Gabriel Silva\Documents\GitHub\tech-challenge-02\docs\Material aulas`.
- Em 2026-07-18 o usuario rejeitou e apagou os guias Markdown anteriores. O estudo foi reiniciado pela Fase 3, um modulo por vez.
- O novo guia usa como referencia visual e didatica o HTML `GUIA-ESTUDO-Introducao-a-Containers.html`.
- Em 2026-07-18 os modulos Welcome e CI/CD receberam guias HTML no novo padrao.
- Em 2026-07-18 o modulo Infraestrutura como Codigo tambem recebeu seu guia HTML.
- Em 2026-07-18 o modulo Seguranca em DevOps (DevSecOps) recebeu seu guia HTML.
- Em 2026-07-18 o modulo Seguranca na Cloud recebeu seu guia HTML, concluindo a trilha de estudos da Fase 3.
- Em 2026-07-18 o estado consolidado foi publicado no branch `dev`; o commit principal dos guias e `200cdf5`.

## 4 Arquivos/caminhos

- Repo atual: `C:\Users\Gabriel Silva\Documents\GitHub\tech-challenge-03`
- Visao geral do repositorio: `README.md`
- Fonte Fase 2: `C:\Users\Gabriel Silva\Documents\GitHub\tech-challenge-02\docs\Material aulas`
- Primeiro guia do novo processo: `docs/01_Welcome to Automacao e Seguranca na Cloud/GUIA-ESTUDO-Automacao-e-Seguranca-na-Cloud.html`
- Segundo guia: `docs/02_CI-CD/GUIA-ESTUDO-CI-CD.html`
- Terceiro guia: `docs/03_Infraestrutura como codigo/GUIA-ESTUDO-Infraestrutura-como-Codigo.html`
- Quarto guia: `docs/04_Seguranca em DevOps (DevSecOps)/GUIA-ESTUDO-Seguranca-em-DevOps-DevSecOps.html`
- Quinto guia: `docs/05_Seguranca na Cloud/GUIA-ESTUDO-Seguranca-na-Cloud.html`
- Contexto compartilhado: `00_COLAB_IA/`

## 5 Processos

- Para estudo de PDFs, extrair conteudo com `pypdf` e sintetizar por modulo/aula.
- Para guias, usar HTML autocontido no padrao indicado pelo usuario: introducao leiga, glossario, fichas com finalidade/caso de uso/aplicacao no ToggleMaster e resumo.
- Estudar e criar apenas um modulo por vez, aguardando revisao do usuario antes de avancar.
- Para mudancas no repo, verificar, commitar e fazer push quando solicitado.

## 6 Decisoes

- D-001: o repo `tech-challenge-03` e o destino dos guias e do contexto atual.
- D-002: decisao anterior sobre guias Markdown, substituida por D-005.
- D-003: estrategia tecnica preferencial da Fase 3: Terraform modular, GitHub Actions, ECR, ArgoCD e EKS.
- D-004: nao copiar PDFs da Fase 2; usar como fonte externa e registrar guias derivados no repo da Fase 3.
- D-005: novos guias ficam em HTML dentro da pasta de cada modulo; substitui D-002 para o trabalho atual.

## 7 Pendencias

- P-007: usuario revisar o guia HTML do modulo 1.
- P-009: usuario revisar o guia HTML do modulo 2.
- P-011: usuario revisar o guia HTML do modulo 3.
- P-013: usuario revisar o guia HTML do modulo 4.
- P-015: usuario revisar o guia HTML do modulo 5.
- P-003: implementacao Terraform permanece em espera ate pedido explicito.

## 8 Glossario

- IaC: Infrastructure as Code, infraestrutura declarada em codigo.
- CI/CD: integracao, entrega e/ou implantacao continua.
- GitOps: Git como fonte da verdade do estado desejado do ambiente.
- EKS: Kubernetes gerenciado da AWS.
- ECR: registro de imagens Docker da AWS.
- RDS: banco relacional gerenciado da AWS.
- SQS: fila gerenciada da AWS.
- ArgoCD: ferramenta GitOps para sincronizar Kubernetes a partir do Git.
- IAM: gerenciamento de identidades e permissoes.
- KMS: servico de gerenciamento de chaves criptograficas.
- CSPM: monitoramento e correcao da postura de seguranca da infraestrutura cloud.
- CWPP: protecao de workloads antes e durante a execucao.
- CASB: controle de politicas entre usuarios e aplicacoes SaaS.

## 9 Cuidados

- Nunca commitar `.env`, chaves AWS, kubeconfigs sensiveis ou senhas.
- `terraform.tfstate` nao deve ficar local no repo.
- Ao substituir arquivo, mover versao antiga para `_ARQUIVO_MORTO/` e registrar no log.

## 10 Resumo das conversas

- 2026-07-16: analisado PDF principal da Fase 3 e criado checklist de entregaveis.
- 2026-07-16: estudado modulo Welcome da Fase 3.
- 2026-07-16: estudado modulo CI/CD da Fase 3.
- 2026-07-16: estudado modulo Infraestrutura como Codigo da Fase 3.
- 2026-07-17: estudados materiais da Fase 2 e criados guias por modulo.
- 2026-07-18: guias anteriores rejeitados e apagados pelo usuario; estudo reiniciado modulo por modulo; criado guia HTML do modulo Welcome.
- 2026-07-18: analisadas as 7 aulas de CI/CD e criado `docs/02_CI-CD/GUIA-ESTUDO-CI-CD.html`.
- 2026-07-18: analisadas as 8 aulas de Infraestrutura como Codigo e criado `docs/03_Infraestrutura como codigo/GUIA-ESTUDO-Infraestrutura-como-Codigo.html`.
- 2026-07-18: analisadas as 7 aulas de DevSecOps e criado `docs/04_Seguranca em DevOps (DevSecOps)/GUIA-ESTUDO-Seguranca-em-DevOps-DevSecOps.html`.
- 2026-07-18: analisadas as 5 aulas de Seguranca na Cloud e criado `docs/05_Seguranca na Cloud/GUIA-ESTUDO-Seguranca-na-Cloud.html`, concluindo os guias dos cinco modulos.
- 2026-07-18: cinco guias, README e contexto consolidados no commit `200cdf5` e enviados para `origin/dev`.

## 11 Memoria interna <-> espelho

Essenciais espelhados aqui: objetivo da Fase 3, uso de AWS pessoal, processo de estudo modulo por modulo, padrao HTML dos guias, conclusao dos cinco modulos e estado anterior ao inicio da implementacao.

## 12 Instrucoes iniciais para o proximo assistente

Leia `LEIA-PRIMEIRO.md`, depois `PENDENCIAS_E_PROXIMOS_PASSOS.md` e o topo de `LOG_DE_TRABALHO.md`. Os cinco guias da Fase 3 estao prontos. Nao avance para implementacao sem pedido explicito; aguarde revisao do usuario ou uma nova orientacao.
