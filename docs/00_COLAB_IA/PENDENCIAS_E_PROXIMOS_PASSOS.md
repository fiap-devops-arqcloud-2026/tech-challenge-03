# PENDENCIAS_E_PROXIMOS_PASSOS

TL;DR: caminho A aprovado pelo professor - 2 RDS + banco do targeting em pod (D-015), node group `c7i-flex.large` (D-016). ATENCAO AO CREDITO: restam US$ 70,33, cerca de 190 horas de uptime da pilha completa (F-026); derrubar ao fim de cada sessao e obrigatorio. Prontos: Etapa 1 do Terraform e `gitops/` completo, ambos validados. Proximo: Etapa 2 do Terraform. Entrega em 2026-09-15.

Ultima atualizacao: 2026-08-27 19:15 -03:00, Claude.

## Alta prioridade

- P-036: no CI, o passo de atualizar a tag precisa do binario `kustomize` standalone. O `kubectl kustomize` renderiza mas nao tem o subcomando `edit`. Usar a action `imranismail/setup-kustomize` ou equivalente.
- P-034: escrever o runbook de subir, semear, gravar e derrubar (`terraform/RUNBOOK-CUSTO.md`). Janela definida pelo usuario: **3 horas de cluster ligado por sessao** (~US$ 1,10). Precisa incluir script de seed, porque o destroy apaga os bancos e sem chave de API nem flag cadastrada a demo fica vazia.
- P-035: no Terraform da Etapa 2, incluir o addon `aws-ebs-csi-driver` e uma StorageClass default. Sem isso o PVC do banco do targeting fica Pending, como ocorreu na Fase 2 (F-025).
- P-018: os nomes do Grupo 203 foram encontrados no README da Fase 2 em 2026-08-27 e ja estao no `README.md` da Fase 3 (Gabriel Pinelli Silva RM373763, Joao Vitor de Jesus Ciardullo RM372155, Douglas Deveza dos Santos RM373827, Joao Carlos da Silva Brito RM371738, Joao Gabriel da Cruz Sales RM372444). **Falta o usuario confirmar** que o grupo continua o mesmo na Fase 3. [INCERTO]
- P-037: decidir se o External Secrets Operator sai do escopo. E item S-02 (sugestao das aulas, nao obrigatorio) e e a unica peca do plano que adiciona operador e CRDs em runtime - justamente o tipo de coisa que pode falhar na janela de gravacao. Alternativa sem ESO descrita na conversa de 2026-08-27.

## Proximos passos

- P-028: Etapa 2 do Terraform - EKS, node group, 3 RDS e ElastiCache. Apply lento, cerca de 25 minutos.
- P-029: Etapa 3 - root `terraform/argocd/` com ArgoCD e External Secrets Operator via provider `helm`.
- P-030: workflows de CI dos 5 servicos (O-10 a O-21), com dois conjuntos de linter/SAST por causa das duas stacks (F-008).
- P-031: migrar o banco do `targeting` do StatefulSet no cluster para o RDS numero 3 (F-016), incluindo o `init.sql` que ja existe em `services/targeting-service/db/`.
- P-024: corrigir os exemplos de `AWS_REGION` nos READMEs de `services/analytics-service/` e `services/evaluation-service/`, que ainda dizem `us-east-1`. Aguarda aval do usuario por serem arquivos copiados da Fase 2.
- P-006: preparar roteiro do video final com evidencias: Terraform plan/apply, pipeline quebrando/passando, ECR, GitOps e ArgoCD.

## Revisoes pendentes do usuario (baixa prioridade agora)

- P-007, P-009, P-011, P-013, P-015: revisar os cinco guias HTML de estudo da Fase 3.

## Encerradas ou substituidas

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
- P-020: encerrada em 2026-08-27 por D-010 (modulos hibridos) e D-009 (tags).
- P-027: encerrada em 2026-08-27. `gitops/` criado com 34 arquivos: base com os 5 servicos mais o `postgres-targeting`, e overlay `prod`. Build validado com `kubectl kustomize` nos dois niveis (28 e 29 recursos). O `ingress.yaml` e os `secret.yaml` da Fase 2 nao foram copiados.
- P-026: encerrada em 2026-08-27. Etapa 1 do Terraform escrita, validada (`terraform validate`) e formatada. Ainda nao aplicada na AWS.
- P-021: encerrada em 2026-08-27 por D-014. O esqueleto do Kustomize deixa de ser autoria e vira adaptacao; a execucao virou P-027.
- P-022: encerrada em 2026-08-27. OIDC do GitHub Actions confirmado, sem access key estatica (S-01).
- P-023: encerrada em 2026-08-27 por D-013. Secrets Manager + External Secrets Operator.
- P-025: encerrada em 2026-08-27. O usuario aprovou o plano do Terraform, com duas alteracoes: ambiente unico chamado `prod` (D-011) e remocao do Ingress (D-012).

## Achados

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
