# Revalidação do parecer FIAP após os PRs 4 e 5

## Atualização: trabalho do Claude e regra exclusiva da dev

Última conferência: 2026-09-09 18:09 -03:00, Codex.
Fonte: pedido do usuário em 2026-09-09, git fetch/log/diff, metadados dos commits e código local no mesmo HEAD 5b8cd86.

- **Nada na main está ausente da dev:** 0 commits exclusivos de cada lado e nenhuma diferença de arquivos. Origin também confirmado em 5b8cd86.
- **Checkout transferido para dev**, preservando os documentos locais. Nenhum merge necessário ou executado; sem commit/push.
- **D-020 é a regra atual:** somente dev para trabalho; promoção por PR dev -> main e merge. AGENTS.md registra a instrução para próximos agentes.
- **Limitação ainda existente:** os jobs GitOps fazem push direto main em _ci-go.yml:563 e _ci-python.yml:589. P-052 precisa ajustar a automação; esta análise não modificou workflows.
- **Revisão atribuível ao Claude:** os commits bdaecf1 e b6a9ba0 têm metadado Co-Authored-By de Claude. As mudanças em versão EKS, schemas/roteiro, remoção de módulos não usados e caminhos de validação são úteis; o script completo ainda é bloqueado pelo security-check. Não se presume autoria exclusiva do restante do projeto.
- **Parecer mantido:** base técnica boa e extras proporcionais; documentação inconsistente e entrega ainda sem comprovação completa. Persistem P-045/P-046/P-048/P-040 e ensaio/entregáveis. As fontes e evidências detalhadas seguem abaixo; as menções anteriores a checkout main são históricas.

## Registro da revalidação anterior


TL;DR: a base técnica atende ao desenho do desafio, mas a entrega ainda exige correções e evidências. Dev e main agora estão sincronizadas; a defasagem de 19 commits foi resolvida. Houve correções no roteiro, na versão EKS e nos scripts, mas permanecem os bloqueios CRITICAL, bootstrap ArgoCD, gestão da chave do seed e endpoint Redis.

Última atualização: 2026-09-09 17:55 -03:00, Codex.
Snapshot: main = dev = origin/main = origin/dev = `5b8cd864233e27d40ea37ee01137bb6328b13fce`.
Este documento complementa o [parecer das 13:31](AUDITORIA_FIAP_2026-09-09_v01.md), preservado como evidência do estado `0242d33`. Para estado atual, prevalece esta revalidação. Não houve edição de código, checkout, commit, push ou apply pelo Codex nesta revalidação.

## 1. Conclusões para o usuário

1. **O projeto está bem direcionado, mas ainda não está pronto para entrega.** Código existente e CI verde não comprovam provisionamento completo, cinco serviços funcionando no EKS e sincronização real do ArgoCD.
2. **Não contém apenas o mínimo literal**, mas os extras são majoritariamente úteis: OIDC, IRSA, DLQ, estados separados e Compose integrado. Manter a arquitetura e corrigir o básico é mais apropriado que adicionar plataformas.
3. **Pastas bem separadas; documentação ainda inconsistente.** O problema é haver instruções incompatíveis e estados antigos apresentados como vigentes.
4. **Dev -> PR -> main é uma forma organizada.** Atualmente há sincronização e PRs; porém os dois últimos PRs vieram de branches auxiliares diretamente para main, não de dev. É um fluxo organizado alternativo, mas não segue literalmente a sequência informada pelo usuário.

Fonte: leitura integral/visual do [PDF FIAP](../../POSTECH%20-%20Tech%20Challenge%20-%20Fase%203.pdf), comparações Git e consultas GitHub realizadas em 2026-09-09. O detalhamento por página, critérios e fontes oficiais permanece no parecer original.

## 2. O que mudou desde a primeira análise

| Achado | Estado em 5b8cd86 | Evidência de 2026-09-09 |
|---|---|---|
| Dev atrasada | **Resolvido** | `git rev-list --left-right --count dev...main` = 0/0; `git ls-remote` confirmou os dois hashes. |
| F-049 / EKS 1.31 caro | **Corrigido no código** | `terraform/cluster/variables.tf` agora usa 1.34. Suporte padrão confirmado no [calendário AWS](https://docs.aws.amazon.com/eks/latest/userguide/kubernetes-versions.html); ainda validar compatibilidade operacional e gerar estimativa final. |
| F-045 / parâmetros e tipo de regra | **Corrigido no roteiro** | `RUNBOOK-SESSAO.md` agora usa `flag_name`, `user_id` e `PERCENTAGE` 100/0. Ainda precisa execução AWS. |
| F-044 / tabelas dos RDS | **Parcialmente resolvido** | Runbook ganhou etapa 1.7 para executar SQL com pods psql. A etapa existe; não foi demonstrada sua execução. |
| F-048 / módulos sem uso | **Removidos no PR #4** | network/sqs/dynamodb não estão mais no diretório ativo. Histórico mostra exclusão, sem movimentação desses módulos para arquivo morto nesse diff. |
| F-048 / validate-all em pastas removidas | **Caminhos corrigidos no PR #5** | Script usa base/cluster/k8s e inclui Kustomize; ainda para no security-check que reprova a conta vigente. |
| Checklist de extras | **Melhorou parcialmente** | Itens adotados passaram a ser marcados. Permanece mistura entre implementação e operação; S-08 menciona plan automático que o workflow não executa. |

As mudanças foram identificadas nos commits `bdaecf1` e `b6a9ba0`, integrados por outros fluxos de trabalho durante o intervalo da análise. Não atribuir sua execução ao Codex desta revalidação.

## 3. O que ainda impede considerar a entrega fechada

- **P-045 / F-042:** os quatro scans Trivy continuam com `ignore-unfixed: true` (`_ci-go.yml:294,391`; `_ci-python.yml:323,418`). O enunciado p.4 exige falha em crítica sem prever essa exceção. A [documentação Trivy](https://trivy.dev/docs/latest/configuration/filtering/) confirma que ela ignora vulnerabilidades sem correção disponível.
- **P-046 / F-043:** `terraform/k8s/argocd.tf:196` ainda declara Application via kubernetes_manifest junto com a instalação de seu CRD. `depends_on` não garante schema durante o plan de cluster novo. Separar etapas/mecanismos e ensaiar o primeiro bootstrap. [Explicação oficial HashiCorp](https://developer.hashicorp.com/terraform/tutorials/kubernetes/kubernetes-provider).
- **P-048 / F-046:** `terraform/k8s/secrets.tf:223` continua gerenciando chave aleatória provisória; o seed a troca manualmente. Um novo apply pode desfazer o valor válido e quebrar autenticação após restart.
- **P-040 / F-047:** `gitops/overlays/prod/patches/endpoints.yaml:28` ainda contém `PREENCHER` no Redis.
- **P-049 / F-048:** `scripts/security-check.sh:19` continua classificando o ID da conta vigente como legado; `validate-all.sh:27` o executa antes das demais verificações. Corrigir o falso positivo e rodar o script integralmente.
- **P-047/P-041/P-042:** executar schemas e seed no EKS, comprovar cinco serviços e ArgoCD Healthy/Synced, demonstrar alteração de imagem sincronizada automaticamente.
- **P-006/P-043:** concluir vídeo de até 20 min e relatório PDF/TXT com participantes, links, desafios/decisões e print de custos. Não foram localizados esses entregáveis finais no material revisado.

Os comandos psql novos usam redirecionamento Bash `< arquivo.sql`. O usuário trabalha em PowerShell, em que essa sintaxe não funciona. O guia precisa indicar Bash/WSL/Git Bash como pré-requisito ou fornecer a variante PowerShell; não tratar essa observação como falha do comando no shell Bash explicitamente indicado no bloco.

## 4. Organização e documentação atuais

As separações `services/`, `terraform/`, `gitops/`, `.github/workflows/` e `docs/` são adequadas para um monorepo de código. Não é necessário transferir tudo para uma estrutura genérica numerada.

Ainda há conflitos verificáveis:

- README e resumos antigos de CLAUDE/DOSSIE dizem que componentes existentes ainda precisam ser escritos.
- `docs/fase-3/GUIA_EXECUCAO.md` e `ARQUITETURA.md` descrevem Academy/LabRole, credenciais estáticas, Ingress, três RDS e diretórios removidos.
- `terraform/README.md` descreve duas camadas, apesar de existirem três.
- `gitops/README.md` ainda menciona ESO removido.
- `RUNBOOK-SESSAO.md:158` ainda recomenda push direto para main.
- O próprio aviso da primeira auditoria passou a dizer que dev estava atrasada depois de ela já ter sido sincronizada. Esta revalidação corrige o estado por nova entrada datada, preservando o registro anterior.
- O checklist ainda marca provisionamento EKS/ArgoCD como concluído enquanto registra apply pendente. Além disso, S-08 diz fmt/validate/plan automatizados, mas `.github/workflows/terraform-check.yml` executa fmt/validate, sem plan.

Recomendação: um README atual, um runbook executado de ponta a ponta, checklist separando escrito/validado/executado/evidenciado e LOG/PENDENCIAS curtos e coerentes. Arquivar documentos substituídos com de-para; preservar os testes de `docs/fase-3/TESTE_COMPOSE.md`, que são úteis. O histórico Git guarda as exclusões feitas nos PRs, mas isso não equivale ao arquivo morto solicitado pelo usuário.

## 5. Fluxo de branches confirmado no GitHub

- [PR #3](https://github.com/fiap-devops-arqcloud-2026/tech-challenge-03/pull/3) foi dev -> main. A integração anterior teve correções humanas posteriores sem PR, conforme evidências do primeiro parecer.
- [PR #4](https://github.com/fiap-devops-arqcloud-2026/tech-challenge-03/pull/4), `chore/limpeza-pos-merge -> main`, foi integrado em 2026-09-09 14:01:01 -03:00.
- [PR #5](https://github.com/fiap-devops-arqcloud-2026/tech-challenge-03/pull/5), `fix/validate-all-tres-camadas -> main`, foi integrado em 2026-09-09 14:48:52 -03:00.
- Dev e main agora apontam ao mesmo commit 5b8cd86. O checkout local permanece na main.
- Logo, a prática recente usa PRs e sincronização; a origem dos PRs não é sempre dev.

Para seguir a preferência do usuário: iniciar mudanças humanas em dev, validar, abrir PR dev -> main e sincronizar dev após o merge. Se o grupo precisar trabalhar em paralelo, branches por tarefa podem convergir para dev. Isso não exige criar outro ambiente AWS.

Os commits automáticos de tag GitOps precisam de política explícita. Exigir PR indiscriminadamente na main pode bloquear o push do bot atual; ajustar ambos conjuntamente. A primeira consulta de proteção/rulesets retornou HTTP 403 com indisponibilidade por plano/visibilidade, portanto não há proteção efetiva comprovada. Não alteramos plano, visibilidade ou regras. [Referência GitHub](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches).

## 6. Evidências atuais de validação

| Verificação | Evidência |
|---|---|
| Compose integrado no HEAD 5b8cd86 | [Sucesso](https://github.com/fiap-devops-arqcloud-2026/tech-challenge-03/actions/runs/34385212931); log confirma sete eventos gravados pelo analytics e SQS drenada. |
| Compose no PR #5 | [Sucesso](https://github.com/fiap-devops-arqcloud-2026/tech-challenge-03/actions/runs/34384579935). **Não é execução do validate-all.sh.** |
| Terraform após PR #4, commit 90ef921 | [Sucesso](https://github.com/fiap-devops-arqcloud-2026/tech-challenge-03/actions/runs/34380318176). Terraform/workflow não mudaram entre esse commit e HEAD. |
| Terraform no PR #4 | [Sucesso](https://github.com/fiap-devops-arqcloud-2026/tech-challenge-03/actions/runs/34379547518). |
| Cinco serviços em dev, commit 90ef921 | [auth](https://github.com/fiap-devops-arqcloud-2026/tech-challenge-03/actions/runs/34380361538), [evaluation](https://github.com/fiap-devops-arqcloud-2026/tech-challenge-03/actions/runs/34380361561), [flag](https://github.com/fiap-devops-arqcloud-2026/tech-challenge-03/actions/runs/34380361566), [targeting](https://github.com/fiap-devops-arqcloud-2026/tech-challenge-03/actions/runs/34380361589), [analytics](https://github.com/fiap-devops-arqcloud-2026/tech-challenge-03/actions/runs/34380361621): sucesso nos checks. Publicação/GitOps ficam skipped em dev. |

Serviços e workflows não mudaram desde a primeira auditoria. Publicação ECR e commits automáticos de imagem têm evidências anteriores vinculadas no parecer original. Não houve novo apply/plan remoto ou teste EKS nesta revalidação. Sucesso em Compose com AWS emulada não prova operação na AWS.

## 7. Escopo mínimo e próximos passos

Preservar monorepo, ambiente único, Kustomize, ArgoCD, OIDC/IRSA e teste integrado. Não acrescentar ambientes, Ingress, ESO ou charts próprios para concluir a entrega.

O PDF p.3 exige três RDS; 2 RDS + pod continua sendo uma exceção aprovada conforme registro D-015, não atendimento literal. Não pedir reaprovação; citar a exceção no relatório e vincular comprovante do professor caso disponível.

Ordem prática: P-045 e P-046; resolver chave/seed e executar schemas; preencher Redis; validar ensaio/ArgoCD; consolidar documentação e script; gravar vídeo e montar relatório. P-051 está resolvida quanto à sincronização, mas a disciplina dev -> PR -> main e a política do bot continuam relevantes.

A primeira auditoria já foi incorporada ao GitHub pelo PR #4. Este complemento e seus registros de continuidade permanecem locais até publicação autorizada; o Codex não fez commit/push.
