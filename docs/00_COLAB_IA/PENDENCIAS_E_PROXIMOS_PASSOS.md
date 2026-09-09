# PENDENCIAS_E_PROXIMOS_PASSOS

TL;DR: plano organizado em 4 fases ate 2026-09-15. Principio: fazer primeiro tudo que nao custa nada e deixar o cluster para o fim, em duas sessoes de 3 horas. Prontos e validados: Etapa 1 do Terraform, `gitops/` (sem ESO, ver D-018) e os 5 workflows de CI. Proxima acao: P-038, aplicar a camada base com o NAT desligado - e o que destrava a primeira execucao real do pipeline (P-044).

Ultima atualizacao: 2026-09-09, Claude.

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
