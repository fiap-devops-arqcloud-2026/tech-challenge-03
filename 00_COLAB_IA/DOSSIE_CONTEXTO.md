# DOSSIE_CONTEXTO

TL;DR: repo da terceira entrega do Tech Challenge. O ToggleMaster da Fase 2 deve ser elevado para IaC, CI/CD, DevSecOps e GitOps na AWS pessoal. Guias da Fase 2 foram gerados em `docs/guias-de-estudo/fase-2/` para recuperar base de containers, Kubernetes, escalabilidade e balanceamento.

Ultima atualizacao: 2026-07-17 16:31 -03:00, Codex.

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

## 4 Arquivos/caminhos

- Repo atual: `C:\Users\Gabriel Silva\Documents\GitHub\tech-challenge-03`
- Fonte Fase 2: `C:\Users\Gabriel Silva\Documents\GitHub\tech-challenge-02\docs\Material aulas`
- Guias gerados: `docs/guias-de-estudo/fase-2/`
- Contexto compartilhado: `00_COLAB_IA/`

## 5 Processos

- Para estudo de PDFs, extrair conteudo com `pypdf` e sintetizar por modulo/aula.
- Para guias, usar estrutura: resumo leigo, explicacao tecnica, aulas, glossario, caso de uso no ToggleMaster e checklist.
- Para mudancas no repo, verificar, commitar e fazer push quando solicitado.

## 6 Decisoes

- D-001: o repo `tech-challenge-03` e o destino dos guias e do contexto atual.
- D-002: guias da Fase 2 ficam em `docs/guias-de-estudo/fase-2/`, separados por modulo.
- D-003: estrategia tecnica preferencial da Fase 3: Terraform modular, GitHub Actions, ECR, ArgoCD e EKS.
- D-004: nao copiar PDFs da Fase 2; usar como fonte externa e registrar guias derivados no repo da Fase 3.

## 7 Pendencias

- P-001: revisar guias de estudo gerados e ajustar se o usuario quiser formato HTML em vez de Markdown.
- P-002: estudar os modulos restantes da Fase 3: DevSecOps e Seguranca na Cloud.
- P-003: iniciar desenho tecnico da infraestrutura Terraform da Fase 3.

## 8 Glossario

- IaC: Infrastructure as Code, infraestrutura declarada em codigo.
- CI/CD: integracao, entrega e/ou implantacao continua.
- GitOps: Git como fonte da verdade do estado desejado do ambiente.
- EKS: Kubernetes gerenciado da AWS.
- ECR: registro de imagens Docker da AWS.
- RDS: banco relacional gerenciado da AWS.
- SQS: fila gerenciada da AWS.
- ArgoCD: ferramenta GitOps para sincronizar Kubernetes a partir do Git.

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

## 11 Memoria interna <-> espelho

Essenciais espelhados aqui: objetivo da Fase 3, decisao de usar AWS pessoal, estrutura dos guias e ligacao entre Fase 2 e Fase 3.

## 12 Instrucoes iniciais para o proximo assistente

Leia `LEIA-PRIMEIRO.md`, depois `PENDENCIAS_E_PROXIMOS_PASSOS.md` e o topo de `LOG_DE_TRABALHO.md`. Se a proxima tarefa for implementacao, comece por inventariar o repo e confirmar se a base do ToggleMaster sera copiada da Fase 2 ou reconstruida neste repo.
