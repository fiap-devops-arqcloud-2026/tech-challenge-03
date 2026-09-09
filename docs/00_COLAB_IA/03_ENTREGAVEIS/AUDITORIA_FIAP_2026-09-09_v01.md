# Parecer de auditoria — Tech Challenge FIAP Fase 3

TL;DR: a arquitetura está alinhada ao núcleo do desafio e possui extras úteis, mas a entrega ainda não pode ser considerada concluída. Há falhas no bootstrap, na preparação dos bancos, no roteiro e na política de bloqueio de vulnerabilidades. A organização de pastas é boa; a documentação contém versões incompatíveis. O fluxo dev -> PR -> main ocorreu, mas correções posteriores foram feitas diretamente na main.

Última atualização: 2026-09-09 13:28 -03:00, Codex.
Escopo: revisão da implementação consolidada em main `0242d33`, da proposta FIAP, da documentação e do histórico remoto. Não é uma certificação de segurança nem um teste de produção. A autoria individual de cada trecho por GPT/Claude não foi presumida.

## 1. Fontes e critérios

- Fonte acadêmica: [enunciado original](../../POSTECH%20-%20Tech%20Challenge%20-%20Fase%203.pdf), leitura integral e inspeção visual das sete páginas em 2026-09-09. Requisitos substantivos nas páginas 2–6.
- Contexto anterior: [decisões](../DECISOES.md), [checklist](../CHECKLIST_REQUISITOS_FASE3.md), [pendências](../PENDENCIAS_E_PROXIMOS_PASSOS.md) e [runbook](../RUNBOOK-SESSAO.md). Esses registros foram confrontados com código e Git, não tratados isoladamente como prova de execução.
- Estado local/remoto: `git fetch origin --prune`, comparação de branches e consultas de PRs/Actions pela API GitHub em 2026-09-09. HEAD main/origin/main: `0242d33c09866dcf1deaac6779ffa99f026fefda`; dev/origin/dev: `cc80c4e30fd2f71cbfe4db35c2bfac781dbe864f`.
- Prazo 2026-09-15: informação do usuário registrada em D-006; não consta no PDF.
- Critério: distinguir **código existente**, **verificação local**, **execução no CI**, **funcionamento na AWS** e **evidência de entrega**. Um não substitui automaticamente o outro.

## 2. Atendimento ao mínimo da FIAP

| Bloco | Exigência / página do PDF | Situação verificada em 2026-09-09 |
|---|---|---|
| IaC | VPC, subnets, IGW, rotas, EKS/nodegroups, 3 RDS, Redis, DynamoDB, SQS e estado S3; p.3 | Código presente e validação local aprovada. Aplicação da base em 2026-09-07 está registrada em P-038; não foi reinspecionada na AWS nesta auditoria. Cluster completo ainda depende de ensaio. |
| Bancos | 3 instâncias RDS PostgreSQL; p.3 | Configuração possui 2 RDS + PostgreSQL targeting em pod. É desvio literal, com exceção já aprovada segundo D-015. Preservar essa decisão e explicá-la no relatório. |
| CI/DevSecOps | Pipeline por serviço, PR/main, build/testes existentes, lint, SAST/SCA, bloqueio de críticas, build/scan/push ECR com hash; p.4 | Cinco pipelines têm execução verde em conteúdos vigentes. A regra de críticas tem exceção indevida: F-042. |
| GitOps | Pasta/repo separado, ArgoCD no EKS, CI atualizando imagem, sincronização automática; pp.4–5 | Atualização de tags pelo bot comprovada. Configuração ArgoCD existe; primeira instalação tem o problema F-043. Sincronização real no EKS não foi comprovada nesta auditoria. |
| Código | Terraform estruturado, workflows e manifests GitOps; p.5 | Presentes. Organização principal adequada; sobras e documentos divergentes precisam de consolidação. |
| Vídeo | Até 20 min; IaC, segurança falhando/passando, atualização GitOps e sync ArgoCD; p.5 | Roteiros existem. Não foi localizado vídeo final/link de entrega no material revisado. |
| Relatório | PDF/TXT com participantes, links, desafios/decisões e print de estimativa AWS; p.6 | Não foi localizado relatório final. A pasta de entregáveis continha somente README antes desta auditoria. Estimativa de custo precisa revisão: F-049. |

**D-015:** o registro diz que o usuário consultou o professor e recebeu aprovação em 2026-08-27. Não se pede nova aprovação. Não foi localizado anexo, print ou link da mensagem original do professor; se disponível, vinculá-lo ao relatório para rastreabilidade.

O número de “39 obrigatórios” é a decomposição interna do checklist. Ele cobre os grandes requisitos, mas não é uma contagem oficial de pontos nem permite calcular uma porcentagem confiável de conclusão.

## 3. Achados prioritários

### F-042 — Críticas sem correção disponível são ignoradas — P-045

**Evidência:** `.github/workflows/_ci-go.yml:294,391` e `_ci-python.yml:323,418` combinam `severity: CRITICAL`, `exit-code: "1"` e `ignore-unfixed: true`.

O PDF p.4 exige que uma vulnerabilidade crítica faça o pipeline falhar, sem essa exceção. A opção oculta vulnerabilidades sem correção publicada, conforme a [documentação oficial do Trivy](https://trivy.dev/docs/latest/configuration/filtering/) consultada em 2026-09-09. Isso comprova lacuna de configuração; não comprova que uma vulnerabilidade específica tenha passado.

**Ajuste mínimo:** retirar a exceção nos quatro scans, executar novamente os pipelines e tratar os achados reais. Evidenciar falha por segurança e sucesso após correção; não usar apenas falha de sintaxe/lint para demonstrar O-28.

### F-043 — Bootstrap da Application ArgoCD depende de CRD ainda inexistente — P-046

**Evidência:** `terraform/k8s/argocd.tf:196` cria `kubernetes_manifest.app_togglemaster`; `:278` usa `depends_on = [helm_release.argocd]`. O [runbook](../RUNBOOK-SESSAO.md) manda um único apply da camada k8s.

Em cluster novo, o provider precisa consultar o schema de Application no plan, antes de o Helm instalar o CRD. `depends_on` não resolve essa consulta antecipada. A [HashiCorp documenta a separação em duas etapas](https://developer.hashicorp.com/terraform/tutorials/kubernetes/kubernetes-provider), consultada em 2026-09-09.

**Ajuste mínimo:** separar a instalação do ArgoCD/CRDs da criação da Application, ou usar mecanismo que não exija o CRD no plan. Validar a partir de cluster novo. Achado estático com suporte documental; não foi reproduzido contra EKS nesta auditoria.

### F-044 — Caminho AWS não inicializa as tabelas de auth e flag — P-047

**Evidência:** `terraform/modules/rds/main.tf:123` cria os bancos. Os schemas estão em `services/auth-service/db/init.sql:1` e `services/flag-service/db/init.sql:1`, mas não há execução deles no Terraform/GitOps/runbook revisado. O targeting tem SQL no ConfigMap e o Compose monta os SQLs, portanto os ambientes se comportam de forma diferente.

Auth apenas conecta ao banco antes de servir; `handlers.go:95` faz INSERT em `api_keys`. Flag abre pool e faz INSERT em `flags` (`app.py:32,92`). RDS recém-criado não terá essas tabelas. Health verde não prova operação funcional.

**Ajuste mínimo:** executar os schemas de forma idempotente antes do seed e testar criação de chave/flag nos RDS reais.

### F-045 — Roteiro funcional usa parâmetros e regra incompatíveis — P-048

**Evidência:** `RUNBOOK-SESSAO.md:250` usa `/evaluate?flag=...&user=...`, mas `services/evaluation-service/handlers.go:36` exige `user_id` e `flag_name`; a chamada retorna 400. A regra do runbook `:244` usa `user_ids`, enquanto `evaluator.go:251` implementa somente `PERCENTAGE`.

**Ajuste mínimo:** usar `/evaluate?flag_name=novo-painel&user_id=user-123` e regras `{"type":"PERCENTAGE","value":100}` / `0` para resultados determinísticos, considerando o TTL do cache. Aproveitar os casos já verificados em `scripts/integration/test-flow.py`; não criar outro mecanismo de targeting só para acomodar o roteiro.

### F-046 — Seed e Terraform disputam o valor de SERVICE_API_KEY — P-048

**Evidência:** `terraform/k8s/secrets.tf:223` gerencia chave aleatória provisória. `RUNBOOK-SESSAO.md:230` substitui o Secret por uma chave real criada no auth.

Um apply posterior pode restaurar o valor provisório; após reinício, evaluation perde autenticação nos outros serviços. A limitação está parcialmente comentada, mas o ciclo reaplicar/reiniciar não está resolvido.

**Ajuste mínimo:** definir um único responsável pelo valor válido e provar que novo apply/restart não desfaz o seed. Seed de dados e o bootstrap não devem ser confundidos com a proibição específica de `kubectl apply` pelo CI.

### F-047 — Configuração Redis ainda incompleta — P-040

**Evidência:** `gitops/overlays/prod/patches/endpoints.yaml:28` conserva `PREENCHER`; o placeholder aparece também na renderização Kustomize. Impede conexão do evaluation.

**Ajuste mínimo:** preencher endpoint e conferir ARNs depois do apply, promovendo a alteração por dev -> PR -> main. As cinco tags de imagem já têm hashes reais; a afirmação de que todas ainda são placeholders está obsoleta.

### F-048 — Documentação e scripts preservam duas arquiteturas incompatíveis — P-049

**CONFLITO documental**, preservado sem apagar registros anteriores:

| Fonte | Divergência em relação ao código verificado |
|---|---|
| `README.md:281–285`, `CLAUDE.md`, `DOSSIE_CONTEXTO.md` | Descrevem infraestrutura/CI “a escrever” ou mandam reconfirmar bucket já registrado. README também afirma serviços sem alteração, apesar dos commits de correção. |
| `docs/fase-3/GUIA_EXECUCAO.md:5–24` | Orienta chaves estáticas, AWS Academy/LabRole e pastas removidas `terraform/bootstrap` e `terraform/environments/dev`. |
| `docs/fase-3/ARQUITETURA.md`, `EVIDENCIAS.md` e `ROTEIRO_VIDEO.md` | Descrevem Ingress, três RDS e cinco Applications; vigente é sem Ingress, 2 RDS + pod e uma Application gerenciando cinco serviços. |
| `terraform/README.md:3` | Descreve duas camadas; há três roots: base, cluster e k8s. |
| `gitops/README.md:62`, `SECRETS-CONTRATO.md:4` | Mandam instalar ESO já removido ou atribuem Secrets à camada errada. |
| `scripts/security-check.sh:19`, `SECURITY.md:10` | Script reprova o ID da própria conta como “legado”; política ainda descreve LabRole. |
| `scripts/validate-all.sh:10–11` | Valida diretórios que não existem; antes disso chama o security-check que também falha. |
| `PENDENCIAS_E_PROXIMOS_PASSOS.md` | O mesmo item aparece aberto e encerrado; o TL;DR ainda manda aplicar a base. |
| `CHECKLIST_REQUISITOS_FASE3.md` | Mistura “escrito”, “pendente execução” e “PROVADO” no mesmo item. ArgoCD aparece concluído com apply pendente. |
| `ORGANIZACAO_DE_PASTAS.md` e topo histórico do LOG | Informações antigas não foram substituídas por uma síntese vigente de handoff. |

**Ajuste mínimo:** um README atual, um guia operacional validado, checklist com estados distintos e contexto curto coerente. Arquivar guias substituídos com de-para, preservando `TESTE_COMPOSE.md` e seus testes úteis. Não remover `docs/fase-3/` inteira: contém trabalho válido.

Os módulos `terraform/modules/network`, `sqs` e `dynamodb` não são chamados pelos roots ativos; rede usa módulo comunitário, SQS/DynamoDB usam `messaging`. Conferir e arquivar sobras na consolidação.

### F-049 — Custo projetado não corresponde à versão EKS padrão — P-050

**Evidência:** `terraform/cluster/variables.tf:37` define Kubernetes 1.31. O [calendário AWS](https://docs.aws.amazon.com/eks/latest/userguide/kubernetes-versions.html), consultado em 2026-09-09, informa fim do suporte padrão em 2025-11-26. O [preço AWS](https://aws.amazon.com/eks/pricing/) é US$ 0,60/h no suporte estendido, contra US$ 0,10/h usado no orçamento.

Se esse default for usado, apenas essa diferença acrescenta US$ 0,50/h. O total antigo não é uma estimativa atual validada. Não foi consultada a configuração viva de um cluster nem a fatura.

**Ajuste mínimo:** selecionar versão em suporte padrão e compatível com módulos/addons, ou corrigir os custos; gerar o print de estimativa exigido no relatório. Não acrescentar novos componentes.

## 4. Organização e qualidade do trabalho existente

**Acertos:** monorepo com `services/`, `terraform/`, `gitops/`, `.github/workflows/` e `docs/`; módulos reutilizáveis; cinco serviços reaproveitados; dois workflows reutilizáveis e cinco chamadores; estado separado por ciclo de vida; locks versionados; OIDC/IRSA; scans efetivamente bloqueantes dentro dos filtros configurados; imagens rastreáveis; teste integrado que exercita persistência, autenticação, cache e eventos.

**Limitação da documentação:** há muitos comentários, mas quantidade de comentários não garante correção. O comentário que diz que `depends_on` resolve o CRD é um exemplo. Respeitar a preferência didática do usuário por comentários, priorizando sua exatidão.

**Testes:** não há testes unitários nos serviços examinados. O PDF p.4 manda rodar os existentes, “se houver”; criar uma suíte nova não é requisito para a entrega. O Compose integrado já dá cobertura funcional útil, mas não testa RDS gerenciado, IAM/IRSA, EKS ou ArgoCD.

**Pequeno ajuste adicional:** mudanças isoladas em `.pylintrc` não disparam os workflows Python pelos filtros `paths`, apesar de usarem esse arquivo. Incluir o caminho quando ajustar CI; não é motivo para reformular pipelines.

## 5. Estamos usando dev -> PR -> main?

**Parcialmente. Esse fluxo é organizado e suficiente para o grupo.**

- [PR #3 dev -> main](https://github.com/fiap-devops-arqcloud-2026/tech-challenge-03/pull/3): aberto em 2026-09-09 10:59:55 -03:00; reconhecido como integrado às 11:54:26 -03:00, merge `595b5f8`. Não há reviews registrados. A API não prova uso do botão de merge.
- O histórico e F-040 registram merge com `-X theirs`; houve perda de suporte aos endpoints de teste e posterior restauração. Não repetir escolha automática de um lado para todos os conflitos.
- Depois do merge há 12 commits em main: 4 humanos e 8 do bot. Correções `122174a`, `364556a` e documentação `0242d33` não têm PR associado na API.
- Main contém toda a dev e está 19 commits à frente; dev não possui commits exclusivos. Não são 19 commits pendentes de entrega: são mudanças que a dev ainda não recebeu.
- `RUNBOOK-SESSAO.md:158` ainda recomenda push direto na main, em desacordo com a preferência informada nesta sessão.
- Consultas de proteção de main e rulesets retornaram HTTP 403 com exigência de mudança de plano/visibilidade. Repositório privado; proteção efetiva **não comprovada**, com indisponibilidade informada pela API. Não alteramos plano, visibilidade ou configurações.

**Fluxo recomendado, sem adicionar ambientes AWS:** sincronizar dev com main; trabalhar em dev; verificar; abrir PR dev -> main; revisar; integrar; sincronizar dev novamente. Branch dev é organização do código, não exige ambiente de infraestrutura dev. Para colaboração simultânea, branches curtas por tarefa podem convergir para dev, se necessário.

Os commits automáticos que atualizam tags GitOps são parte do CD e devem ter política explícita. Proteger main exigindo PR também para eles pode bloquear o pipeline atual. Antes de habilitar regras, compatibilizar o bot com a política, por exemplo usando PR de promoção. A [documentação GitHub de proteção](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches) descreve PRs e checks obrigatórios; [workflows omitidos por filtros podem deixar checks pendentes](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/skip-workflow-runs). Fontes consultadas em 2026-09-09. Nenhuma configuração remota foi alterada.

## 6. Evidência de verificação

Verificações locais de 2026-09-09, sem init/apply/plan remoto:

| Verificação | Resultado / limite |
|---|---|
| Terraform fmt recursivo | Passou. |
| Terraform validate em base, cluster e k8s | Passou nas três camadas; não garante CRDs/bancos/recursos em execução. |
| Kustomize overlay prod | 23 recursos renderizados; Redis permanece com placeholder. |
| Python AST | 6 arquivos de aplicação/integração analisados sem erro de sintaxe; não executa dependências nem APIs. |
| Testes unitários nos serviços | 0 arquivos Go e 0 arquivos Python encontrados; não confundir go test sem testes com cobertura funcional. |
| Schemas e scripts locais | Conferência estática; scripts obsoletos não foram apresentados como testes aprovados. |

Evidências GitHub consultadas em 2026-09-09:

| Workflow | Commit | Execução |
|---|---|---|
| auth | 122174a | [Sucesso](https://github.com/fiap-devops-arqcloud-2026/tech-challenge-03/actions/runs/34367909857) |
| flag | 122174a | [Sucesso](https://github.com/fiap-devops-arqcloud-2026/tech-challenge-03/actions/runs/34367909835) |
| targeting | 122174a | [Sucesso](https://github.com/fiap-devops-arqcloud-2026/tech-challenge-03/actions/runs/34367909855) |
| analytics | 364556a | [Sucesso](https://github.com/fiap-devops-arqcloud-2026/tech-challenge-03/actions/runs/34368797421) |
| evaluation | 364556a | [Sucesso](https://github.com/fiap-devops-arqcloud-2026/tech-challenge-03/actions/runs/34368797231) |
| Terraform Check | 22bb199 | [Sucesso](https://github.com/fiap-devops-arqcloud-2026/tech-challenge-03/actions/runs/34366712994) |
| Compose Integration | HEAD 0242d33 | [Sucesso](https://github.com/fiap-devops-arqcloud-2026/tech-challenge-03/actions/runs/34370338206) |

Comparações de arquivos confirmaram que os conteúdos relevantes desses runs permanecem no HEAD. Não se afirma que todos executaram no mesmo commit. Jobs de imagem/ECR/GitOps foram confirmados nos runs inspecionados; o teste Compose confirmou sete eventos persistidos com SQS/DynamoDB emulados. Não houve novo ensaio Docker ou AWS nesta auditoria.

## 7. Apenas o básico necessário?

**Não estritamente:** existem extras, mas a maior parte ajuda a concluir o básico com segurança e repetibilidade.

| Manter | Justificativa |
|---|---|
| OIDC e IRSA | Evitam distribuição de chaves AWS estáticas. |
| DLQ | Trata mensagens que falham repetidamente; pequena complexidade. |
| Separação dos estados | Permite controlar ciclo de vida e preservar imagens/base. |
| Kustomize e workflows reutilizáveis | Evitam duplicação e já estão implementados. |
| Compose integrado | Evidenciou regressão real do merge; economiza ensaios na AWS. |

Secrets Manager atualmente recebe cópias das credenciais RDS; os Secrets Kubernetes são alimentados pelo remote state. Não apresentar os pods como consumidores diretos de Secrets Manager. Esse extra pode ser explicado, sem acrescentar ESO.

Monorepo é expressamente permitido; ambiente único e ausência de Ingress não contrariam requisito expresso. Helm instala ArgoCD; Kustomize organiza aplicações. A [documentação oficial ArgoCD](https://argo-cd.readthedocs.io/en/stable/user-guide/kustomize/) confirma suporte nativo. O PDF menciona alteração de deployment.yaml; explicar na demonstração que a tag no kustomization.yaml produz esse Deployment atualizado.

Não há necessidade de introduzir múltiplos ambientes, Ingress, Helm charts próprios, ESO, KEDA, DAST ou plataformas de observabilidade para resolver os achados. Evitar afirmar que algum extra “não vale nota”: não temos a rubrica detalhada de avaliação.

## 8. Ordem mínima para fechar a entrega

1. **P-051:** sincronizar dev com main e retomar mudanças humanas via PR; preparar política do bot.
2. **P-045:** ajustar bloqueio CRITICAL e capturar falha/sucesso reais.
3. **P-046/P-047/P-048:** corrigir bootstrap ArgoCD, schemas e seed; testar reaplicação.
4. **P-050/P-040:** rever versão/custo e completar endpoints após apply.
5. **P-049:** consolidar documentos e scripts com evidência de execução; preservar histórico e arquivar somente materiais substituídos.
6. **P-041/P-042:** ensaio no EKS, cinco serviços funcionais, ArgoCD Synced/Healthy e mudança de imagem sincronizada automaticamente; gravar e encerrar recursos conforme procedimento validado.
7. **P-006/P-043:** vídeo até 20 min e relatório PDF/TXT com links, participantes, desafios, exceção D-015 e estimativa AWS.

A auditoria gerou apenas documentos locais. Não corrige os achados, não publica commits e não demonstra uma entrega já concluída. O próximo agente deve ler o topo atualizado de LOG/PENDENCIAS antes dos resumos históricos.
