# PENDENCIAS_E_PROXIMOS_PASSOS

## Estado apos a rodada de correcoes - 2026-09-09 22:40 -03:00, Claude

TL;DR: **nenhum requisito tecnico do enunciado esta em aberto.** O que falta e uma sessao com o cluster no ar e, depois dela, video e relatorio. Placar: 24 comprovados / 6 escritos e validados / 9 nao iniciados, e os 9 sao entregaveis.

### Fechadas nesta rodada

- **P-045 / F-042** - FECHADA. `ignore-unfixed: false` nos 4 scans, com `.trivyignore` nominal e justificado. Efeito medido nas imagens reais do ECR antes de mudar.
- **P-046 / F-043** - FECHADA. Bootstrap do ArgoCD em duas etapas, documentado em `terraform/k8s/argocd.tf` e no passo 1.4 do runbook.
- **P-048 / F-046** - FECHADA. `ignore_changes = [data]` no Secret do evaluation-service encerra a disputa com o seed.
- **P-040 / F-047** - FECHADA. Comando pronto no passo 1.5 do runbook substitui o `PREENCHER` do `REDIS_URL`.
- **P-049 / F-048** - FECHADA na parte documental. README raiz, `terraform/README.md`, `gitops/README.md`, os quatro documentos de `docs/fase-3/`, o checklist e o `CLAUDE.md` foram alinhados ao codigo. `security-check.sh` corrigido e `validate-all.sh` rodando inteiro.
- **P-051** - FECHADA. main e dev identicas (0/0, diff vazio), e as tres branches auxiliares remotas ja estao integradas.
- **P-052** - FECHADA por decisao, sem alterar workflow. Ver **D-021**: o push do robo na main e intencional; D-020 rege trabalho humano.

### Abertas - em ordem de execucao

1. **P-041 - Sessao de ensaio com o cluster** (CAMINHO CRITICO). Primeira vez que a pilha completa sobe. Seguir o runbook: NAT -> `cluster/` -> kubeconfig -> `k8s/` **em dois comandos** -> schemas (passo 1.7) -> seed -> conferir ArgoCD Healthy/Synced -> destroy. Reservar 3h.
2. **P-047 - Criar os schemas nos RDS.** Etapa documentada (runbook 1.7), nunca executada. Sem ela os servicos sobem, respondem `/health` com 200 e falham no primeiro INSERT. Os comandos sao Bash: rodar no Git Bash ou WSL.
3. **P-042 - Gravar o video** (O-27 a O-32). Roteiro cena a cena, com comandos prontos e a demo de falha JA TESTADA, em [GUIA_GRAVACAO.md](../fase-3/GUIA_GRAVACAO.md). Metade nao precisa do cluster: pipeline falhando/passando (O-28/O-29) e atualizacao da tag no GitOps (O-30) rodam so no GitHub Actions. Gravar essa metade ANTES da sessao paga.
4. **P-006 / P-043 - Relatorio** (O-37, O-38, O-39). Os desvios que precisam estar la: 2 RDS + 1 pod (D-015), sem Ingress (D-012), ESO cortado (D-018) e a excecao do `.trivyignore`. Print de custo pelo AWS Pricing Calculator.
5. **P-018 - Confirmar os integrantes.** A tabela do README ja tem os 5 do Grupo 203; falta so o usuario confirmar que nao mudou.

### Item opcional barato, se sobrar tempo

- **R-04 - Testes unitarios.** Confirmado em 2026-09-09: nao existe nenhum arquivo de teste nos 5 servicos. Os jobs de build ja estao preparados e passam sem falhar. Um unico teste por servico fecharia o item.

### Nao repetir

- Nao sincronizar "os 19 commits" da dev: ja foi feito, as branches estao iguais.
- Nao tratar ArgoCD escrito como ArgoCD instalado - o apply ainda nao aconteceu.
- Nao rodar `terraform -chdir=terraform/k8s apply` direto num cluster novo: sao dois comandos (F-043).
- Nao concluir que a regra da dev esta imposta pela configuracao do GitHub: protecao de branch nao esta disponivel neste plano/visibilidade. A regra e acordo, nao trava tecnica.


## Regra dev e conferencia atual - 2026-09-09 18:09 -03:00, Codex

TL;DR: D-020 determina trabalhar somente na dev e promover por PR dev -> main. Checkout ja esta na dev; comparacao local/remota 0/0 em 5b8cd86. Nao ha conteudo exclusivo da main a integrar.

- P-051: sincronizacao resolvida e branch de trabalho corrigida. Preservados documentos locais ainda sem commit/push.
- P-052 - ABERTA: adaptar os jobs GitOps em _ci-go.yml:563 e _ci-python.yml:589, que ainda fazem push direto main, ao fluxo D-020. Avaliar promocao de tags via dev -> PR -> main preservando trabalho existente na dev; nao trocar destino do push sem revisar fetch/base/concorrencia. Este ponto nao foi implementado durante a analise.
- P-045/P-046/P-048/P-040 continuam abertas; P-047 exige execucao dos schemas; P-049 consolidacao dos documentos/scripts; P-041/P-042/P-006/P-043 ensaio, video e relatorio.
- Fonte de revisao do Claude: commits bdaecf1 e b6a9ba0 tem Co-Authored-By de Claude. Corrigiram EKS/roteiro/caminhos do validate-all, mas nao os bloqueios acima.


## Atualizacao apos PRs 4 e 5 - 2026-09-09 17:57 -03:00, Codex

TL;DR: esta nota atualiza o estado dos itens abaixo; registros das 13:31 permanecem historicos. Fonte: [revalidacao](03_ENTREGAVEIS/REVALIDACAO_AUDITORIA_FIAP_2026-09-09_v01.md), HEAD 5b8cd86.

- P-051: SINCRONIZACAO RESOLVIDA. Main/dev/remotas iguais, 0/0; manter a disciplina D-019 e definir politica do bot. PRs #4/#5 foram de branches auxiliares para main.
- P-050: DEFAULT CORRIGIDO para EKS 1.34, em suporte padrao; ainda revisar estimativa/compatibilidade no ensaio.
- P-047: ETAPA DOCUMENTADA no runbook 1.7; executar e verificar schemas AWS. Comandos psql sao Bash; explicitar shell ou adaptar ao PowerShell.
- P-048: PARAMETROS/REGRA CORRIGIDOS no roteiro; falta resolver F-046 (Secret/chave) e validar ciclo apply/restart.
- P-049: PARCIAL. Modulos orfaos removidos e caminhos validate-all corrigidos, mas security-check, guias, README e resumos continuam divergentes.
- P-045/P-046/P-040: ABERTAS, sem mudanca nos trechos de CI/ArgoCD/Redis.
- P-041/P-042/P-006/P-043: ABERTAS; nenhuma evidencia nova de ensaio EKS/video/relatorio final.


TL;DR da auditoria: implementacao principal existe e CI tem execucoes verdes, mas ainda ha bloqueios antes do ensaio AWS. Seguir P-045 a P-051 e depois P-040/P-041/P-042/P-006/P-043. Nao repetir P-038 nem tratar ArgoCD escrito como instalado.

Ultima atualizacao desta sintese: 2026-09-09 13:31 -03:00, Codex.
Fonte: [parecer verificado](03_ENTREGAVEIS/AUDITORIA_FIAP_2026-09-09_v01.md), snapshot main 0242d33 e consultas GitHub de 2026-09-09.

## Pendencias da auditoria (prioridade vigente)

- P-045 - ALTA: retirar ignore-unfixed dos quatro scans CRITICAL e validar falha/sucesso reais (F-042).
- P-046 - ALTA: corrigir bootstrap da Application ArgoCD; o CRD precisa existir no plan do kubernetes_manifest (F-043).
- P-047 - ALTA: executar schemas idempotentes dos RDS auth e flag antes do seed (F-044).
- P-048 - ALTA: corrigir parametros e regras do seed; resolver disputa de SERVICE_API_KEY entre seed e Terraform; verificar apply/restart (F-045/F-046).
- P-049 - MEDIA: consolidar README, CLAUDE, dossie, checklist, guias e scripts; arquivar documentos substituidos com de-para, preservando testes uteis (F-048). CONFLITO: docs/fase-3 descreve Academy/LabRole/Ingress/3 RDS; codigo e decisoes descrevem conta pessoal/OIDC/IRSA/sem Ingress/2 RDS + pod. Nesta auditoria apenas registramos as duas versoes, sem eliminar nenhuma.
- P-050 - ANTES DE SUBIR AWS: revisar Kubernetes 1.31 e estimativa; o default esta em suporte estendido, nao corresponde a tarifa do orçamento (F-049).
- P-051 - ANTES DE CODIFICAR: sincronizar dev com main e retomar alteracoes humanas via PR conforme D-019. Main esta 19 commits a frente, dev sem exclusivos; nenhum merge/checkout/push feito nesta auditoria. Definir politica para commits automaticos GitOps antes de impor protecao de main.
- P-040 - ABERTA: Redis ainda tem PREENCHER; conferir endpoint e ARNs apos apply. As cinco imagens JA possuem hashes no overlay (F-047).
- P-041/P-042 - ABERTAS: ensaio completo e gravacao no EKS depois das correcoes.
- P-006/P-043 - ABERTAS: video ate 20 minutos e relatorio PDF/TXT com links, participantes, desafios e print de estimativa AWS. Prazo 2026-09-15 conforme D-006.
- D-015 mantida: excecao 2 RDS + pod aprovada segundo registro anterior do usuario. Nao pedir reaprovacao; vincular comprovacao do professor ao relatorio, caso disponivel.

## Achados novos

- F-042: ignore-unfixed permite ignorar criticas sem correcao; PDF p.4 nao preve a excecao.
- F-043: dependência do CRD ArgoCD no plan nao e resolvida por depends_on no mesmo apply.
- F-044: caminho AWS nao executa os schemas dos dois RDS; Compose executa, por isso seu sucesso nao prova os schemas AWS.
- F-045: runbook usa flag/user e regra user_ids; API exige flag_name/user_id e implementa PERCENTAGE.
- F-046: Terraform pode restaurar SERVICE_API_KEY provisoria sobre a chave valida criada no seed.
- F-047: endpoint Redis incompleto confirmado no YAML renderizado; tags das imagens ja preenchidas.
- F-048: guias, resumos e scripts permanecem incompatíveis com a implementacao consolidada; detalhes no parecer.
- F-049: Kubernetes default 1.31 em suporte estendido; tarifa control plane US$ 0,60/h segundo AWS em 2026-09-09, contra US$ 0,10/h usado no orçamento.

## Registros anteriores preservados

CONFLITO DOCUMENTAL: o plano abaixo conserva tarefas abertas e encerradas simultaneamente e resumos desatualizados. Nao usa-lo isoladamente como estado atual. A auditoria acima acrescenta evidencias sem apagar o historico dos outros agentes.


TL;DR: plano organizado em 4 fases ate 2026-09-15. Principio: fazer primeiro tudo que nao custa nada e deixar o cluster para o fim, em duas sessoes de 3 horas. Prontos e validados: Etapa 1 do Terraform, `gitops/` (sem ESO, ver D-018) e os 5 workflows de CI. Proxima acao: P-038, aplicar a camada base com o NAT desligado - e o que destrava a primeira execucao real do pipeline (P-044).

Ultima atualizacao: 2026-09-09 (segunda sessao), Claude.

## Plano em 4 fases ate 2026-09-15

Principio de ordenacao: fazer PRIMEIRO tudo que nao custa nada, e deixar o
cluster para o fim, em poucas sessoes de 3 horas (F-026, F-028).

### Fase A - trabalho sem custo (alvo: 2026-08-31)

- P-044: primeira execucao real dos 5 pipelines. Os workflows estao
  escritos e com YAML validado, mas NUNCA rodaram. Depende de P-038
  (a role OIDC e os repositorios ECR precisam existir). Espere ajustes
  na primeira rodada - ver a secao "Riscos conhecidos de P-044".
- Ao fim da Fase A da para GRAVAR O-28, O-29 e O-30: pipeline falhando,
  pipeline passando e a tag sendo atualizada no GitOps. Tudo no GitHub
  Actions, com o cluster desligado (F-028).

### Fase B - escrever o resto sem aplicar (alvo: 2026-09-04)

- P-028: preencher `terraform/cluster/` - EKS com node group `c7i-flex.large`
  (D-016), 2 RDS, ElastiCache, roles IRSA e segredos no Secrets Manager.
- P-035: no mesmo Terraform, addon `aws-ebs-csi-driver` e StorageClass
  default, senao o PVC do banco em pod fica Pending (F-025).
- P-039: incluir o Metrics Server, senao os dois HPA ficam com `<unknown>`
  e nunca escalam.
- P-029: Etapa 3 - root `terraform/argocd/` com ArgoCD via provider `helm`
  e a `Application` apontando para `gitops/overlays/prod`.
- P-034: runbook de subir, semear, gravar e derrubar, com script de seed
  (chave de API, uma flag e uma regra), porque o destroy apaga os bancos.
- P-040: preencher os placeholders de `overlays/prod/patches/` apos o
  primeiro apply da camada cluster (ARNs de role IRSA e endpoints).

### Fase C - sessoes com o cluster (alvo: 2026-09-11)

- P-041: sessao de ENSAIO, ate 3 horas. Apply completo, corrigir o que
  quebrar, conferir os 5 servicos verdes no ArgoCD, destruir. Custo
  aproximado: US$ 1,10.
- P-042: sessao de GRAVACAO, ate 3 horas. Apply, gravar O-27, O-31 e O-32,
  destruir. Conferir na conta que nada caro ficou de pe.

### Fase D - entrega (alvo: 2026-09-14)

- P-006: montar o video final juntando o que foi gravado nas fases A e C,
  respeitando o limite de 20 minutos.
- P-043: relatorio de entrega (O-36 a O-39): nomes do Grupo 203, links,
  resumo dos desafios - a secao de problemas do `README.md` ja serve de
  base - e print da estimativa de custos do AWS Pricing Calculator.

### Decisoes pendentes que nao bloqueiam o inicio

- P-018: confirmar que o Grupo 203 continua o mesmo. Afeta so o relatorio.

### Fora do caminho critico

- P-024: corrigir os exemplos de `AWS_REGION` nos READMEs de
  `services/analytics-service/` e `services/evaluation-service/`.

## Revisoes pendentes do usuario (baixa prioridade agora)

- P-007, P-009, P-011, P-013, P-015: revisar os cinco guias HTML de estudo da Fase 3.

## Riscos conhecidos de P-044 (primeira execucao do pipeline)

Os workflows foram escritos contra codigo da Fase 2 que nunca passou por
linter nem por scanner. E esperado que a primeira rodada acuse coisas.
Onde olhar primeiro, em ordem de probabilidade:

1. **SCA (Trivy fs) nos servicos Python.** Os `requirements.txt` trazem
   versoes antigas e pinadas: `Flask==2.2.2`, `requests==2.28.1`,
   `gunicorn==20.1.0`, `Werkzeug<3`. Se alguma tiver CVE CRITICAL com
   correcao publicada, o pipeline barra (O-16) e a dependencia precisa
   subir de versao. Observacao: `flag-service/requirements.txt` declara
   `Flask==2.2.2` DUAS vezes - vale limpar.
2. **pylint.** O corte esta em `--fail-under=7.0`. Codigo legado pode
   ficar abaixo disso. Ajuste o numero ou corrija os apontamentos.
3. **gosec e bandit.** Configurados para falhar so em severidade alta.
   Se acusarem, e achado real e vale corrigir, nao afrouxar.
4. **Scan da imagem.** As bases `python:3.12-slim` e `alpine:3.20` podem
   ter CVE critico de sistema operacional. A correcao e reconstruir com
   a base atualizada.

Recomendacao: rodar primeiro em `dev`, onde os jobs de verificacao
executam mas nada e publicado no ECR nem no GitOps.

## Encerradas ou substituidas

- P-034: concluida em 2026-09-09. Runbook em
  `docs/00_COLAB_IA/RUNBOOK-SESSAO.md`, com as 5 fases (pre-voo, subir,
  seed, gravar, derrubar), o roteiro do video mapeado item a item, uma
  tabela de armadilhas conhecidas e a conferencia final de custo.
  Inclui o passo que mais doi se for esquecido: ligar o NAT antes do
  cluster e DESLIGAR depois, porque a camada base nunca e destruida.

- P-029: concluida em 2026-09-09. ArgoCD escrito em `terraform/k8s/argocd.tf`:
  chart oficial via provider helm com versao fixa 7.7.11, Application
  apontando para `gitops/overlays/prod` na branch `main`, com prune e
  selfHeal ligados. Fecha O-23 e O-25. NAO aplicado.
- P-044: concluida em 2026-09-09. Alem dos dois defeitos de configuracao
  (F-032), os tres achados legitimos foram tratados (F-035). Os quatro
  jobs de verificacao Python passam localmente nos tres servicos.
- P-040: parcialmente resolvida. O `storageClassName` e os Secrets foram
  fechados; restam os placeholders de `overlays/prod/patches/`
  (REDIS_URL com "PREENCHER" e as tags `v1.0.0-placeholder`), que so
  podem ser preenchidos depois do primeiro apply da camada cluster.

- P-028: concluida em 2026-09-08. Camada `terraform/cluster/` escrita com
  quatro modulos novos - eks, rds, elasticache e irsa. `validate` e `fmt`
  passam; o `plan` resolve em 35 recursos, 0 a destruir. NAO aplicada.
  Fecha O-03, O-04 e O-06; deixa O-05 parcial por D-015.
- P-035: concluida em 2026-09-08. Addon `aws-ebs-csi-driver` incluido no
  modulo eks, com role IRSA propria. Sem ele o PVC do banco em pod ficaria
  Pending, como travou a Fase 2 (F-025).
- P-039: concluida em 2026-09-08. Addon `metrics-server` incluido. Sem ele
  os dois HPA ficariam com `<unknown>` e nunca escalariam.
- P-044: parcialmente resolvida em 2026-09-08. Os 5 pipelines rodaram pela
  primeira vez e falharam. Dois defeitos meus foram corrigidos (ver F-032);
  tres achados sao legitimos e exigem mexer no codigo dos servicos (F-033).

- P-038: concluida em 2026-09-07. Camada base aplicada na AWS: 33 recursos
  (VPC com 4 subnets, IGW e route tables; 5 repositorios ECR com lifecycle;
  SQS `togglemaster-events` mais DLQ; tabela `ToggleMasterAnalytics`;
  provedor OIDC, role e policy do CI). Estado gravado em
  `s3://togglemaster-tfstate-891376952395-us-east-2-an/prod/base.tfstate`
  (61 KiB). NAT desligado. Fecha O-02, O-07, O-08, O-09 e O-21.
  Conferido: `github_actions_role_arn` bate com o ARN escrito nos dois
  workflows reutilizaveis, e o registro ECR bate com o `newName` do
  `gitops/overlays/prod/kustomization.yaml`.

- P-030: concluida em 2026-09-01. Sete workflows criados em
  `.github/workflows/`: dois reutilizaveis (`_ci-go.yml`, `_ci-python.yml`)
  e cinco chamadores, um por servico. YAML validado nos 7. Cobre O-10 a
  O-20, O-24 e O-26 - 13 itens obrigatorios.
- P-036: concluida em 2026-09-01. O binario `kustomize` v5.4.3 e instalado
  no job `gitops` dos dois workflows reutilizaveis (F-027).
- P-037: encerrada em 2026-09-01 por D-018. O External Secrets Operator foi
  cortado; os Secrets passam a ser criados pelo Terraform. Os 5
  `externalsecret.yaml` e o `secretstore.yaml` foram removidos, e o
  contrato ficou documentado em `gitops/SECRETS-CONTRATO.md`.

- P-001: encerrada em 2026-07-18. Os guias Markdown anteriores foram rejeitados e apagados; D-005 define o novo padrao HTML por modulo.
- P-002: substituida em 2026-07-18 por P-014, que representava o ultimo modulo pendente.
- P-004: encerrada em 2026-08-27. O codigo dos 5 microsservicos vive neste monorepo em `services/` (D-007).
- P-005: encerrada em 2026-08-27. A area GitOps usa Kustomize (D-008).
- P-008, P-010, P-012, P-014: concluidas em 2026-07-18. Guias HTML dos modulos 2 a 5 criados.
- P-016: encerrada em 2026-07-30. O usuario confirmou entrega em grupo (D-006).
- P-017: encerrada em 2026-07-30. Prazo final confirmado pelo usuario: 2026-09-15 (D-006).
- P-032: encerrada em 2026-08-27 por D-015. Caminho A, com aprovacao do professor.
- P-033: encerrada em 2026-08-27 por D-016. Node group com `c7i-flex.large`.
- P-019: encerrada em 2026-08-27. Bucket de estado criado pelo console: `togglemaster-tfstate-891376952395-us-east-2-an`, regiao `us-east-2`, versionamento ligado, SSE-S3, acesso publico bloqueado, policy TLS-only e lifecycle de 30 dias.
- P-031: cancelada em 2026-08-27 por D-015 - o banco do targeting continua em pod, nao migra para RDS.
- P-020: encerrada em 2026-08-27 por D-010 (modulos hibridos) e D-009 (tags).
- P-027: encerrada em 2026-08-27. `gitops/` criado com 34 arquivos: base com os 5 servicos mais o `postgres-targeting`, e overlay `prod`. Build validado com `kubectl kustomize` nos dois niveis (28 e 29 recursos). O `ingress.yaml` e os `secret.yaml` da Fase 2 nao foram copiados.
- P-026: encerrada em 2026-08-27. Etapa 1 do Terraform escrita, validada (`terraform validate`) e formatada. Ainda nao aplicada na AWS.
- P-021: encerrada em 2026-08-27 por D-014. O esqueleto do Kustomize deixa de ser autoria e vira adaptacao; a execucao virou P-027.
- P-022: encerrada em 2026-08-27. OIDC do GitHub Actions confirmado, sem access key estatica (S-01).
- P-023: encerrada em 2026-08-27 por D-013. Secrets Manager + External Secrets Operator.
- P-025: encerrada em 2026-08-27. O usuario aprovou o plano do Terraform, com duas alteracoes: ambiente unico chamado `prod` (D-011) e remocao do Ingress (D-012).

## Achados

- F-040: o merge hibrido `dev -> main` com `-X theirs` foi feito em
  2026-09-09. Tag de seguranca `backup/main-antes-do-hibrido` criada no
  remoto antes de tudo. Estrategia: prioridade para a dev em TODO arquivo
  conflitante (30 arquivos add/add), preservando o historico e os 6
  commits do colega. Depois foram removidas as estruturas duplicadas
  (`terraform/environments`, `terraform/bootstrap`, `gitops/apps`,
  `gitops/infrastructure`) e dois workflows redundantes
  (`foundation-validation`, `reusable-devsecops`). O `terraform-check`
  foi ADAPTADO para as tres camadas e fechou o item S-08. Mantidos da
  main: `docs/fase-3/`, docker-compose, scripts, SECURITY.md.

  CUSTO DESSA ESTRATEGIA, aprendido na pratica: escolher um lado inteiro
  descarta em silencio o que o outro tinha de exclusivo dentro de arquivo
  conflitante. Aqui sumiu o suporte a SQS_ENDPOINT e DYNAMODB_ENDPOINT,
  do qual o teste de integracao depende. So foi percebido porque o
  `compose-integration` ficou vermelho. Restaurado no commit seguinte.

- F-039: dois defeitos no job de GitOps, expostos so na main, onde os 5
  pipelines rodam o job de verdade. (1) O bloco `concurrency` com grupo
  compartilhado NAO enfileira: o GitHub mantem 1 rodando + 1 pendente e
  CANCELA o pendente anterior a cada novo, entao com 5 servicos houve
  execucao morta por cancelamento. (2) O `git pull --rebase` conflitava
  no kustomization.yaml e deixava o repo no meio do rebase, fazendo toda
  retentativa morrer em "unmerged files". Corrigido trocando a estrategia
  por um laco que RECALCULA a alteracao sobre o remoto atualizado a cada
  tentativa - fetch, reset --hard, kustomize edit, commit, push. Sem
  merge, sem conflito possivel, idempotente.

- F-038: efeito em cadeia da correcao do CVE-2026-56854. Elevar
  golang.org/x/crypto para v0.55.0 subiu a diretiva `go` dos modulos de
  1.21 para 1.25.0, o que quebrou tres coisas em sequencia: o Dockerfile
  (golang:1.22-alpine), o `go-version` fixo do job de SAST (1.23) e o
  golangci-lint v1.61, que recusa analisar modulo com versao maior que a
  usada para compila-lo. Licao: upgrade de dependencia por seguranca
  arrasta a versao do toolchain, e todo lugar que fixa versao de Go
  precisa ser revisado junto.

- F-041: o CVE-2026-56854 (CRITICAL, golang.org/x/crypto v0.20.0)
  existia IGUALMENTE na branch main desde sempre, e o CI de la passava
  verde - porque os passos de Trivy usavam `continue-on-error: true`, que
  faz o job reportar falha e o pipeline seguir. E a evidencia mais forte
  do projeto a favor da regra de bloqueio do O-16: a vulnerabilidade
  estava publicada e invisivel. Material direto para o relatorio (O-38).

- F-037: duvida legitima levantada pelo usuario em 2026-09-09 -
  "nao iriamos usar Kustomize em vez de Helm?". Nao ha contradicao, e a
  distincao vale ficar registrada. D-008 e R-06 tratam de como os
  MANIFESTOS DAS APLICACOES sao estruturados, e ali e Kustomize: e a
  pasta gitops/ que o ArgoCD sincroniza (O-22). O Helm aparece em outro
  lugar - na INSTALACAO do proprio ArgoCD, que e infraestrutura e nao
  aplicacao. O enunciado nomeia Helm justamente ali: "Instale o ArgoCD
  no seu cluster EKS (pode usar Helm ou Terraform com provider
  helm/kubectl)". Instalar o ArgoCD por Kustomize seria possivel, mas
  exigiria remendar o install.yaml oficial com patches para desligar o
  Dex e ajustar replicas - mais fragil que passar values no chart.

- F-036: auditoria de 2026-09-09 encontrou quatro falhas bloqueantes que
  o checklist nao mostrava, porque item marcado como escrito nao e o
  mesmo que item que funciona:
  (a) os 5 Secrets referenciados pelos pods nao eram criados por NADA -
      ao cortar o ESO (D-018) o codigo substituto nunca foi escrito, e
      todos os servicos ficariam em CreateContainerConfigError;
  (b) o ArgoCD nao existia como codigo, so como comentario e um rotulo;
  (c) o volumeClaimTemplates do banco em pod nao declarava
      storageClassName, reintroduzindo o F-025 da Fase 2;
  (d) o ECR estava com 0 imagens nos 5 repositorios.
  (a), (b) e (c) foram corrigidos no mesmo dia. (d) so se resolve quando
  o pipeline rodar verde na main.

- F-035: tratamento dos achados de lint e SAST, em 2026-09-09.
  Go (errcheck): 5 chamadas a json.Encoder.Encode sem verificacao de
  retorno, em auth-service e evaluation-service. CORRIGIDAS no codigo -
  o erro passa a ser registrado no log, que e o unico tratamento
  possivel depois de o cabecalho HTTP ja ter sido enviado.
  Bandit: 2 achados B608 (SQL injection) e 3 B104 (bind em 0.0.0.0).
  Todos analisados e classificados como FALSO POSITIVO com justificativa
  escrita no proprio codigo, via `# nosec` pontual - o B608 porque a
  f-string interpola apenas literais e os dados do usuario vao como
  parametro no psycopg2; o B104 porque ligar em todas as interfaces
  dentro de um container e o comportamento correto.
  Pylint: notas iniciais de 4.84 a 5.66, abaixo do corte de 7.0. Dois
  achados eram REAIS e foram corrigidos (import json morto no
  targeting-service; default de os.getenv com tipo int nos tres) mais
  30 linhas com espaco em branco no fim. O restante era estilo e foi
  desligado num `.pylintrc` na raiz, com justificativa por regra.
  Notas finais: flag 8.26, targeting 8.08, analytics 7.59.
  Nenhuma regra da familia E (erro) foi tocada.

- F-034: em 2026-09-08 descobriu-se que a branch `main` tem uma
  implementacao COMPLETA e PARALELA da Fase 3, feita por outro integrante
  (PR #1 `feature/import-fase-3-joao` e PR #2), com CI verde desde
  2026-09-05. Ela traz `terraform/{bootstrap,environments,modules}` com
  modulos de network, ecr, dynamodb, eks, elasticache, rds e sqs;
  `gitops/apps/` em YAML plano; 9 workflows, incluindo
  `compose-integration.yml` e `terraform-check.yml`. Os 5 arquivos de
  workflow tem os MESMOS nomes dos nossos - um merge `dev` -> `main` vai
  colidir. Tres fatos relevantes: (1) o Terraform da main NUNCA foi
  aplicado - o backend deles e `backend.tf.example` e o bucket estava
  vazio antes do nosso apply; (2) o EKS deles usa `var.lab_role_arn`, ou
  seja, foi escrito para a LabRole do AWS Academy, que nao se aplica a
  conta pessoal; (3) os dois passos de Trivy la tem
  `continue-on-error: true`, o que faz o job reportar falha mas o pipeline
  seguir - conflita com o O-16, que exige "falhar e nao prosseguir".
  Decisao do usuario em 2026-09-08: caminho C, manter a nossa camada base
  (ja aplicada) e trazer os modulos de EKS/ElastiCache/RDS da main
  adaptados para `terraform/cluster/`.

- F-033: achados legitimos na primeira execucao dos pipelines, que exigem
  mexer no codigo dos servicos e ainda estao ABERTOS:
  (a) golangci-lint acusa `errcheck` em `services/auth-service/handlers.go`
      linhas 25, 54 e 98 - retorno de `json.Encoder.Encode` ignorado;
  (b) pylint sai com codigo 22 nos servicos Python, abaixo do corte de 7.0;
  (c) bandit sai com codigo 1, achados de severidade media ou alta.
  Nenhum deles e defeito do pipeline: e o pipeline funcionando.

- F-032: dois defeitos de configuracao nos workflows, corrigidos em
  2026-09-08. (1) `aquasecurity/trivy-action@0.28.0` NAO EXISTE - essa
  versao nunca foi publicada, e os 5 jobs de SCA morriam em "Unable to
  resolve action". Corrigido para o SHA `ed142fd0...` (v0.36.0),
  confirmado pela API do GitHub e ja usado pela main. (2)
  `gosec@v2.21.4` nao compila com o toolchain Go atual, falhando com
  "invalid array length -delta * delta"; corrigido para v2.29.0, e o job
  de SAST passou a fixar Go 1.23 em vez de ler o go.mod (1.21), porque o
  gosec moderno exige toolchain mais novo para COMPILAR.

- F-031: a infraestrutura da Fase 2 ainda estava de pe na conta em
  2026-09-07 e fez o primeiro `terraform apply` falhar pela metade: 19 dos
  33 recursos foram criados e 7 falharam com `RepositoryAlreadyExists`,
  `QueueAlreadyExists` e `ResourceInUseException`. Os recursos eram de
  junho: 5 repositorios ECR com 3 imagens cada e a tabela
  `ToggleMasterAnalytics` com 117.757 itens (13,7 MB). Foram avaliados dois
  caminhos - `terraform import` (nao destrutivo) ou apagar e recriar. O
  usuario optou por apagar, executando os comandos de delecao manualmente,
  e o apply seguinte criou os 14 restantes sem erro. Licao para o relatorio
  (O-38): um apply que falha no meio nao corrompe nada - o estado guarda o
  que deu certo e o comando seguinte mira so no que falta.

- F-001: a pasta de material da Fase 2 contem 6 modulos, 34 PDFs e guias HTML por modulo.
- F-002: a Fase 2 explica a base operacional que a Fase 3 automatiza: containers, Kubernetes, escalabilidade, Ingress, balanceamento e HA.
- F-003: o modulo Welcome possui um PDF introdutorio de 4 paginas e apresenta quatro pilares: CI/CD, IaC, DevSecOps e Seguranca na Cloud.
- F-004: o modulo CI/CD possui 7 PDFs sobre fundamentos, otimizacao, Kubernetes, GitOps, Terraform, serverless e AIOps.
- F-005: o modulo Infraestrutura como Codigo possui 8 PDFs e termina com uma infraestrutura AWS completa automatizada por GitHub Actions.
- F-006: o modulo DevSecOps possui 7 PDFs e cobre pipeline seguro, segredos, SAST/SCA, containers/IaC, DAST, gestao de vulnerabilidades e auditoria.
- F-007: o modulo Seguranca na Cloud possui 5 PDFs e cobre ameacas, responsabilidade compartilhada, IAM/MFA/Zero Trust, criptografia/privacidade e CSPM/CWPP/CASB.
- F-008: os 5 microsservicos usam duas stacks - Go em `auth` e `evaluation`, Python em `flag`, `targeting` e `analytics`. Logo o CI precisa de dois conjuntos de linter/SAST (`golangci-lint`+`gosec` e `pylint`/`flake8`+`bandit`).
- F-009: o enunciado fixa o nome literal da tabela DynamoDB como `ToggleMasterAnalytics` e o padrao de tag de imagem como `v1.0.0-<commit-hash>`.
- F-010: o enunciado marca como opcional/recomendado apenas: modulos Terraform, ECR via Terraform, flag `use_lockfile`, testes unitarios "se houver", IAM via Terraform (conta pessoal), Helm vs YAML, repo GitOps separado vs pasta no monorepo e a escolha da ferramenta de CI.
- F-011: varredura de segredos em `services/` nao encontrou credencial hardcoded. Toda a configuracao vem de variaveis de ambiente: `DATABASE_URL`, `REDIS_URL`, `AWS_REGION`, `AWS_SQS_URL`, `AWS_DYNAMODB_TABLE`, `MASTER_KEY`, `SERVICE_API_KEY`, `PORT`, `AUTH_SERVICE_URL`, `FLAG_SERVICE_URL`, `TARGETING_SERVICE_URL`.
- F-012: a regiao do projeto e `us-east-2` (Ohio). Cuidado: os READMEs copiados em `services/analytics-service/` e `services/evaluation-service/` trazem `us-east-1` nos exemplos; sao herdados da Fase 2 e estao errados (P-024).
- F-013: os marcos M1 (2026-08-08) e M2 (2026-08-22) originais venceram sem conclusao; o cronograma foi rebaseado em `CHECKLIST_REQUISITOS_FASE3.md`.
- F-014: o nome do bucket adotado inclui o numero da conta AWS e vai para o `backend.tf` versionado. Account ID nao e credencial, mas a AWS recomenda nao publicar sem necessidade. Mitigacao adotada: manter o repositorio privado ate a entrega.
- F-015: o `git pull` da Fase 2 em 2026-08-27 foi fast-forward de `0f3abe8` para `3d8a9b2` e trouxe 4 commits, todos de documentacao (35 PDFs de aula, 6 guias HTML, secao do README e log de colaboracao). Nenhuma alteracao em codigo. Diff confirmou que `services/` daqui e identico ao da Fase 2, exceto `__pycache__`.
- F-016: a Fase 2 tinha 2 RDS, nao 3. `auth_db` e `flags_db` em RDS; o `targeting_db` rodava como StatefulSet `postgres-targeting` dentro do cluster. O `GUIA-AWS.md` da Fase 2 confirma: "repita 2 vezes" e "O targeting NAO usa RDS". O terceiro RDS exigido pela Fase 3 e exatamente essa migracao (P-031).
- F-017: na Fase 2, `analytics` e `evaluation` acessam SQS e DynamoDB com `AWS_ACCESS_KEY_ID` e `AWS_SECRET_ACCESS_KEY` estaticas dentro de um Secret do Kubernetes. E literalmente a dor descrita no enunciado e o "antes" ideal para demonstrar IRSA no video e no relatorio (O-38).
- F-018: o enunciado da Fase 3 nao exige Ingress, Load Balancer nem acesso externo. Extracao do PDF em 2026-08-27 com `pdftotext`: as palavras "ingress", "load balancer", "balanceador", "acesso externo", "http", "url", "endpoint", "dominio", "expor", "publico", "nginx" e "alb" aparecem zero vezes nas 7 paginas. Base factual de D-012.
- F-019: nomes canonicos ja em uso na Fase 2, reaproveitados para evitar divergencia entre Terraform, Kustomize e codigo: namespace `togglemaster`; repositorios ECR `<servico>-service`; fila `togglemaster-events`; cache `togglemaster-redis`; tabela `ToggleMasterAnalytics`; bancos `auth_db`, `flags_db`, `targeting_db` com usuario `toggle`; portas auth 8001, flag 8002, targeting 8003, evaluation 8004, analytics 8005.
- F-030: com estado unico, o `terraform destroy` de fim de sessao levaria junto os repositorios ECR e, por causa do `force_delete`, as imagens. O CI teria de reconstruir e reenviar as 5 antes de cada sessao. Resolvido por D-017, separando base permanente de cluster efemero. O furo so apareceu porque o usuario questionou a ordem de aplicar.
- F-028: metade dos itens de video nao precisa do cluster. O pipeline falhando e passando (O-28, O-29) e a atualizacao da tag no GitOps (O-30) rodam inteiramente no GitHub Actions, com custo zero de AWS. So o bloco do ArgoCD (O-31, O-32) exige o EKS no ar. Isso reduz a pressao sobre a janela de gravacao.
- F-029: os nomes e RMs do Grupo 203 estavam no README da Fase 2 desde sempre. A P-018 ficou aberta por 28 dias porque ninguem procurou na fonte obvia.
- F-027: o `kubectl kustomize` renderiza mas nao possui o subcomando `edit`. O passo do CI que atualiza a tag da imagem (O-24) precisa do binario `kustomize` standalone instalado no runner (P-036).
- F-026: em 2026-08-27 restavam US$ 70,33 de credito e 42 dias de plano gratuito (fim por volta de 2026-10-08). O prazo de entrega, 2026-09-15, cabe folgado na janela de dias; o limitante e o CREDITO. Estimativa de consumo com a pilha completa de pe: EKS control plane US$ 0,10/h + 2 x c7i-flex.large US$ 0,17/h + NAT US$ 0,045/h + 2 x db.t3.micro US$ 0,036/h + ElastiCache US$ 0,017/h = aproximadamente **US$ 0,37/h, ou US$ 8,80 por dia**. Ou seja: cerca de **190 horas de uptime** no total, nao 19 dias. Trabalhar 5h por dia ate a entrega consome ~95h e cabe; UM fim de semana esquecido ligado consome 48h, um quarto do orcamento. Destruir ao fim de cada sessao deixa de ser otimizacao e vira requisito.
- F-023: a conta 891376952395 esta no plano gratuito novo da AWS, que impoe DOIS bloqueios rigidos, ambos comprovados na Fase 2. (1) Maximo de 2 instancias RDS simultaneas: a terceira falha com "maximum number of instances available with free plan accounts" (Fase 2, D-001). (2) Somente tipos de instancia elegiveis ao Free Tier podem ser lancados: a `t3.medium` foi recusada com "The specified instance type is not eligible for Free Tier" (Fase 2, D-007). Nao sao limites de custo, e recusa de API.
- F-024: a Fase 2 contornou os dois bloqueios assim: `targeting_db` como StatefulSet no EKS em vez de RDS (solucao aprovada pelo professor), e node group com `c7i-flex.large` (2 vCPU / 4 GB, ~US$ 0,085/h) no lugar da `t3.medium`. Consequencia para a Fase 3: a decisao de usar 2 x `t3.medium` e inviavel como esta, e o `c7i-flex.large` custa cerca do DOBRO por hora.
- F-025: a Fase 2 perdeu tempo com o PVC do banco em pod preso em Pending porque a StorageClass `gp2` nao era default. Na Fase 3 o addon `aws-ebs-csi-driver` e uma StorageClass default precisam nascer do Terraform, nao de correcao manual.
- F-021: o `terraform init` resolveu o modulo `terraform-aws-modules/vpc/aws` 5.21.0 com o provider AWS 6.62.0. Confirma que deixar a restricao do provider em `>= 5.46` sem teto foi correto: fixar `~> 6.0` teria conflitado com a restricao interna do modulo e travado o init.
- F-022: as tags do projeto sao `project` e `phase` em MINUSCULAS, confirmado pelo usuario. Chave de tag na AWS e sensivel a caixa; grafias diferentes viram grupos separados no Cost Explorer.
- F-020: soma dos `requests` reais dos 5 deployments da Fase 2: 450m de CPU e 512Mi de RAM. Com ArgoCD, ESO e kube-system, o total fica em torno de 1,25 vCPU e 1,9 GiB. Confirma que 2 nos `t3.medium` (4 vCPU / 8 GiB) atendem com folga, incluindo espaco para o HPA do `evaluation` escalar.
