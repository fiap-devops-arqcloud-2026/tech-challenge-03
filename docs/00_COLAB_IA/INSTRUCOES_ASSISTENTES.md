# Instruções para assistentes de IA

TL;DR: o projeto foi entregue e o ambiente AWS não existe mais. Qualquer trabalho agora é de documentação ou de manutenção leve. Antes de editar, confira a Parte 3: tocar em `services/**` ou `.github/workflows/**` dispara pipelines que falham sem a role da AWS.

Última atualização: 2026-09-15 19:03 -03:00, Claude. Substitui a versão de 2026-09-14, arquivada em [_ARQUIVO_MORTO/INSTRUCOES_ASSISTENTES_2026-09-14.md](_ARQUIVO_MORTO/INSTRUCOES_ASSISTENTES_2026-09-14.md) (lá estão os antigos `CLAUDE.md` e `AGENTS.md` fundidos). Não existem `CLAUDE.md` nem `AGENTS.md` na raiz.

---

## Parte 1. Estado em 2026-09-15

- **Entrega:** FIAP POSTECH, Tech Challenge Fase 3, Grupo 203, prazo 2026-09-15 (D-006). Repositório **público**: https://github.com/fiap-devops-arqcloud-2026/tech-challenge-03
- **Vídeo:** regravado em 2026-09-15 (a gravação de 2026-09-11 saiu sem áudio). O link ainda é o marcador `PREENCHER_URL_DO_VIDEO` no README e no relatório.
- **Ambiente AWS:** recriado do zero e destruído em 2026-09-15, na ordem k8s, cluster, base. Os três estados do Terraform estão vazios.
- **Sobras na conta, com exclusão pendente do usuário** (bloqueada por permissão no fim do dia 2026-09-15):
  - bucket de estado `togglemaster-tfstate-891376952395-us-east-2-an`;
  - uma VPC da Fase 2.
- **Já limpos em 2026-09-15:** log groups de RDS da Fase 2 sem expiração, a VPC da Fase 1 e as roles IAM da Fase 2.
- **Últimas evidências:** run 34985289399 (SCA falhou com CVE-2020-14343 CRITICAL), run 34985477955 (verde), PR #16, run 34997028995 (publicação na `main`) e commit do robô a0c7b8e (flag-service `v1.0.0-a509d67`). O ArgoCD sincronizou sozinho e o selfHeal reverteu um `kubectl scale`.
- **Documentação:** consolidada em 2026-09-15 (D-024). Ver a Parte 4.
- **Integrantes:** os 5 do Grupo 203 estão na tabela do README; a confirmação da composição segue pendente (P-103).

### Fatos do projeto que valem para qualquer sessão

- **Serviços:** auth e evaluation em Go 1.25; flag, targeting e analytics em Python 3.12. Portas 8001 a 8005. Monorepo (D-007).
- **Conta:** AWS pessoal (não AWS Academy), região `us-east-2`, tags `project=fiap` e `phase=3` em minúsculas via `default_tags` (D-009).
- **Terraform em três camadas, estado no S3 com `use_lockfile`:**
  - `terraform/` (base): VPC com 1 NAT, 5 ECR, SQS com DLQ, DynamoDB `ToggleMasterAnalytics`, OIDC e role do CI. Chave `prod/base.tfstate`.
  - `terraform/cluster/`: EKS 1.34 com 2 `c7i-flex.large`, 2 RDS PostgreSQL 16, ElastiCache redis7, IRSA. Chave `prod/cluster.tfstate`.
  - `terraform/k8s/`: ArgoCD (chart 7.7.11), Application, 5 Secrets, StorageClass gp3. Chave `prod/k8s.tfstate`.
- **CI:** 5 workflows chamadores e 2 reutilizáveis. Só CRITICAL bloqueia (`exit-code 1`, `ignore-unfixed: false`, exceções nominais no `.trivyignore`). O scan da imagem vem antes do push. Tag `v1.0.0-<sha7>`. O robô grava a tag no overlay com `[skip ci]`, num laço de 5 tentativas.
- **GitOps:** Kustomize com base e overlay `prod` (23 objetos). ArgoCD com `automated`, `prune` e `selfHeal`, reconciliação a cada 30 s. Sem Ingress: acesso por `port-forward`.
- **Desvios conscientes:** 2 RDS e o banco do targeting em StatefulSet (D-015; combinado com o professor em 2026-08-27, comprovante escrito não localizado); sem Ingress (D-012); ESO cortado (D-018); sem testes unitários Python; Redis sem TLS em trânsito.
- **Custo:** US$ 281,03/mês (730 h) na estimativa oficial de 2026-09-11; cerca de US$ 0,39/h por sessão; NAT Gateway a US$ 0,045/h.

## Parte 2. Regras permanentes

**Escrita**
- Português do Brasil, com acentuação. Primeiro explicação simples, depois o detalhe técnico.
- Fora desta pasta, nada de IA, assistente, Claude, Codex, agente, "gerado por", nome da pasta `00_COLAB_IA` ou códigos internos (D-, F-, P-, O-, R-, S-). Aqui dentro pode.
- Não inventar. Faltou confirmação, marque `[INCERTO]`. Número medido sempre com data.
- Evidência pública com link completo para o GitHub.

**Código e comandos**
- Todo código criado vem comentado linha a linha (o que a linha faz e por quê).
- Todo comando mostrado ao usuário vem com uma linha de comentário acima dizendo o que faz. O usuário quer aprender.
- Blocos em Git Bash: um comando por linha, sem `&&` e sem barra invertida de continuação. PowerShell 5.1 não aceita nenhum dos dois.
- Terraform sempre com `plan -out=<arquivo>.tfplan` e `apply <arquivo>.tfplan`. Nunca `apply` interativo: colado em bloco, a linha seguinte vira a resposta do "yes".
- Nunca segredo, token, senha ou chave em arquivo versionado nem em mensagem.

**Git**
- Assistente não faz `git add`, `commit`, `push`, `mv`, `rm`, `stash` ou `checkout` sem pedido explícito do usuário.
- Nunca `git add` de tudo (`git add .` ou `-A`). Em 2026-09-15 isso levou 13 arquivos não revisados e a trava `~$ToggleMaster_Fase3.pptx` para a `main` (commit 06f97c6). Adicione por caminho.
- Trabalho humano só na `dev`, promovido por PR para a `main` (D-020). O robô do CI comita a tag direto na `main` de propósito (D-021). Por isso a `main` anda sozinha: sincronize a `dev` antes de começar.

```bash
# Muda para a branch de trabalho
git switch dev
# Baixa o que mudou no GitHub, inclusive os commits do robô na main
git fetch origin
# Avança a dev até a main sem criar merge; se recusar, pare e pergunte ao usuário
git merge --ff-only origin/main
# Confere se sobrou alguma alteração local antes de editar
git status --short
```

**AWS e escopo**
- Nesta conta, `create_github_oidc_provider = false` (D-022). O provedor OIDC do GitHub pertence ao projeto rh-portfolio: o ToggleMaster só lê, nunca importa nem destrói.
- Medir antes de endurecer regra de segurança no CI: rodar a ferramenta no artefato real e ver o efeito antes de mudar o pipeline (foi assim com o `.trivyignore`).
- Entregar o básico que funciona. O alvo é o enunciado da FIAP. Extra só com justificativa direta e sem peça nova em runtime.
- Sem pedido explícito: nada de `terraform init/plan/apply/destroy` com backend, `aws` com escrita, `gh run rerun`, `gh workflow run` ou `gh pr`. Leitura (`git grep`, `git log`, `terraform fmt -check`, `kubectl kustomize`, `gh run view`, `gh run list`) é livre.

## Parte 3. Mapa de gatilhos de CI

Conferido nos filtros de caminho dos workflows em 2026-09-15.

| Caminho editado | Push só na `dev` | PR para `main` ou `dev` | Merge (push na `main`) |
|---|---|---|---|
| `services/<svc>/**`, inclusive `README.md` | pipeline do serviço (build, lint, SAST, SCA) | idem | pipeline completo: **image e gitops tentam OIDC e falham sem a role** |
| `.github/workflows/_ci-go.yml` ou `_ci-python.yml` | os pipelines daquela linguagem | idem | idem, com falha no OIDC |
| `.github/workflows/<svc>.yml` | pipeline do serviço | idem | idem, com falha no OIDC |
| `terraform/**` (inclusive `.md`) | nada | Terraform Check (fmt e validate, sem AWS) e Compose Integration | Terraform Check e Compose Integration |
| `gitops/**` | nada | Compose Integration | Compose Integration |
| `docs/**`, `README.md`, `SECURITY.md`, `.gitignore`, `.env.example`, `scripts/**` | nada | Compose Integration (sem AWS) | Compose Integration |

Regras que saem da tabela:
- Sem ambiente e sem role: **não editar `services/**` nem `.github/workflows/**`**. Registre em PENDENCIAS.
- `workflow_dispatch` não publica imagem. Image e gitops só rodam em push na `main`.
- O commit do robô leva `[skip ci]` e `gitops/**` não está em nenhum filtro, então não há laço.
- Compose Integration roda em todo PR e em todo push na `main`, sem filtro de caminho, e usa o Moto no lugar da AWS.

## Parte 4. Mapa da documentação

Regra: cada fato tem detalhe em um lugar só; nos outros aparece em uma frase com link.

| Assunto | Onde fica o detalhe |
|---|---|
| Intuito, arquitetura em diagrama, decisões, dificuldades, escopo, custo, integrantes | [README.md](../../README.md) |
| Comandos, tempos medidos, tabela de valores fixos para outra conta, bucket, destroy, armadilhas, Compose local, demonstração | [docs/GUIA_DE_REPRODUCAO.md](../GUIA_DE_REPRODUCAO.md) |
| Portas, probes, IRSA, Secrets, criptografia, jobs, versões | [docs/ARQUITETURA.md](../ARQUITETURA.md) |
| Relatório da FIAP | [docs/RELATORIO_DE_ENTREGA.md](../RELATORIO_DE_ENTREGA.md) |
| Política de credenciais | [SECURITY.md](../../SECURITY.md) |
| Camadas do Terraform, só a pasta | [terraform/README.md](../../terraform/README.md) |
| Kustomize e quem altera o overlay | [gitops/README.md](../../gitops/README.md) |
| Nomes e chaves dos Secrets | [gitops/SECRETS-CONTRATO.md](../../gitops/SECRETS-CONTRATO.md) |
| Exceções do Trivy | [.trivyignore](../../.trivyignore) (revisão marcada para 2026-10-15) |

Onde registrar, nesta pasta:

| O quê | Onde |
|---|---|
| O que foi feito na sessão | topo do [LOG_DE_TRABALHO.md](LOG_DE_TRABALHO.md), no formato existente |
| Decisão com alternativa descartada | [DECISOES.md](DECISOES.md), próxima D-025, no topo |
| Algo que ficou para depois | [PENDENCIAS_E_PROXIMOS_PASSOS.md](PENDENCIAS_E_PROXIMOS_PASSOS.md) |
| Arquivo substituído | [_ARQUIVO_MORTO/](_ARQUIVO_MORTO/) com data no nome, e o de-para no LOG |

Os READMEs de `services/` são herança da Fase 2 e estão desatualizados. Continuam assim por causa dos gatilhos de CI; o guia prevalece.

## Parte 5. Armadilhas de operação

Resumo do que já aconteceu. Sintoma, causa e prevenção completos em [GUIA_DE_REPRODUCAO.md, seção 11](../GUIA_DE_REPRODUCAO.md#11-armadilhas-conhecidas).

- **Ordem da subida:** base, imagens no ECR, cluster, k8s. A camada k8s antes das imagens deixa os pods em `ImagePullBackOff` (2026-09-15).
- **ECR vazio:** a base destruída leva o ECR e as imagens (`force_delete`). Em 2026-09-15 as imagens voltaram com `gh run rerun` dos últimos runs de push na `main` (commit do robô 3a193c4).
- **Provedor OIDC de outro projeto:** criar outro falha com `EntityAlreadyExists`, e o `plan` não avisa (D-022).
- **kubeconfig antigo:** depois de recriar o cluster, rode `aws eks update-kubeconfig`; senão o kubectl fala com o endpoint antigo.
- **kubectl Unauthorized:** só o principal IAM que criou o cluster o administra. Use o mesmo perfil em todas as camadas.
- **Camada k8s em duas etapas:** `-target=helm_release.argocd` primeiro, porque o CRD da Application precisa existir no plan.
- **Destroy da k8s antes do cluster:** o driver EBS apaga o disco de 5 GB do PVC. É o desejado; o disco não pertence a nenhum estado.
- **`terraform.tfvars.example`:** vem com `enable_nat_gateway = false`. Copiado sem trocar, os nós ficam sem saída e sem imagem.
- **Pods Healthy sem schema:** o `/health` não consulta o banco. Rodar os `init.sql` antes de testar.
- **Trivy local diferente do CI:** observado localmente em 2026-09-15, o Trivy 0.74 não leu pacotes listados depois de `setuptools<81` e `Werkzeug<3`. O CI usa o Trivy v0.70.0 (fixado pelo SHA do trivy-action) e detectou normalmente.
- **PowerShell 5.1:** sem `&&` e sem continuação de linha. Use o Git Bash.

## Parte 6. Evidências para conferir antes de afirmar

Todo ID abaixo foi conferido com `gh run view` em 2026-09-15. Use estes links em vez de repetir o fato de memória; se precisar de um run novo, confira antes de escrever.

| O que prova | Onde |
|---|---|
| CVE crítico barrando o pipeline (PyYAML 5.3.1, `CVE-2020-14343`) | [run 34985289399](https://github.com/fiap-devops-arqcloud-2026/tech-challenge-03/actions/runs/34985289399) |
| Correção para 6.0.1 deixando verde | [run 34985477955](https://github.com/fiap-devops-arqcloud-2026/tech-challenge-03/actions/runs/34985477955) |
| Publicação da imagem e atualização da tag na `main` | [run 34997028995](https://github.com/fiap-devops-arqcloud-2026/tech-challenge-03/actions/runs/34997028995) |
| Commit do robô que o ArgoCD sincronizou sozinho | [a0c7b8e](https://github.com/fiap-devops-arqcloud-2026/tech-challenge-03/commit/a0c7b8e06f9e12da5bc838d64ead841e1f91072f) |
| Bloqueio anterior por CVE em `golang.org/x/crypto` | [run 34360653255](https://github.com/fiap-devops-arqcloud-2026/tech-challenge-03/actions/runs/34360653255) |
| Reaproveitamento do provedor OIDC | [PR #15](https://github.com/fiap-devops-arqcloud-2026/tech-challenge-03/pull/15), commit b78f6bd |
| Demonstração completa da esteira, da `dev` à `main` | [PR #16](https://github.com/fiap-devops-arqcloud-2026/tech-challenge-03/pull/16), merge a509d67 |

Três afirmações que parecem certas e estão erradas, conferidas nos workflows em 2026-09-15: `workflow_dispatch` **não** publica imagem (os jobs `image` e `gitops` exigem evento `push` na `main`); o scan da imagem acontece **antes** do login e do push no ECR; e a confiança da role do CI aceita `repo:<owner>/<repo>:*`, ou seja, qualquer branch ou PR — quem restringe à `main` é o `if` do workflow, não a AWS.
