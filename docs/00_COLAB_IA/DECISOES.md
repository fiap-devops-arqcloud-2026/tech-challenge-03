# DECISOES

## D-021 - O robo do CI continua comitando na main; a regra da dev vale para gente

TL;DR: D-020 governa o trabalho HUMANO. O commit automatico de tag do pipeline continua indo direto para a `main`, de proposito. Ultima atualizacao: 2026-09-09, Claude.

Contexto: D-020 determinou "so trabalhar na dev, promover por PR". O ultimo job dos dois workflows reutilizaveis (`_ci-go.yml`, `_ci-python.yml`) roda `kustomize edit set image` e faz `git push origin HEAD:main`. Codex registrou isso como pendencia P-052, por parecer contradizer a regra.

Decisao: **manter o push do robo na `main`** e tratar D-020 como regra de trabalho humano. A `dev` deve ser sincronizada com a `main` no inicio de cada sessao.

Por que: a `main` e a branch que o ArgoCD observa - e o que o enunciado chama de estado desejado. O commit de tag nao e "trabalho": e o resultado mecanico de um build que ja passou por PR, revisao e pelos portoes de seguranca. Fazer o robo abrir PR para si mesmo criaria uma fila de PRs automaticos que alguem teria de aprovar durante a gravacao, e quebraria a demonstracao de O-24/O-25 - justamente o item que precisa aparecer no video sincronizando sozinho. O caminho da mudanca continua sendo `dev -> PR -> main`; o robo so escreve DEPOIS que o merge aconteceu.

Alternativas avaliadas:
- Robo comitando na `dev` e um PR automatico para a `main`: adiciona um passo manual no meio do caminho critico do GitOps, a 6 dias da entrega, e o ArgoCD passaria a ver a tag so depois de intervencao humana. Descartada.
- Branch dedicada so para as tags (`gitops-bot`) com o ArgoCD observando ela: funcionaria, mas separa em duas branches o que o enunciado trata como uma fonte da verdade, e complica a explicacao no video. Descartada.

Consequencia pratica, que precisa estar visivel: **a `main` anda sozinha.** Foi assim que a `dev` ficou 19 commits atras em 2026-09-08. O antidoto esta escrito no `README.md`, no `AGENTS.md` e no runbook: `git switch dev && git fetch origin && git merge --ff-only origin/main` antes de comecar qualquer coisa.

Status: decidida. Encerra P-052 sem alterar workflow.


## D-020 - Trabalho exclusivo na dev e promocao por PR para main

TL;DR: regra explicita do usuario, mais estrita que a preferencia D-019. Ultima atualizacao: 2026-09-09 18:09 -03:00, Codex.

Contexto: em 2026-09-09 o usuario pediu revisar o trabalho do Claude, conferir conteudo exclusivo na main e determinou que, a partir de agora, so se trabalhe na dev, com PR para main seguido de merge.

Decisao: toda alteracao humana parte de dev; main recebe promocao por PR dev -> main e merge. Nao usar branches auxiliares diretamente para main sem nova instrucao. Verificar/sincronizar dev apos cada merge.

Por que: manter uma origem unica de trabalho, revisao e rastreabilidade, reduzindo divergencias e perda de alteracoes. Branch dev nao cria outro ambiente AWS.

Alternativas: PRs de branches auxiliares diretamente para main (usados nos PRs #4/#5, deixam de ser o fluxo combinado); push humano direto main (vedado pela regra).

Estado confirmado: git fetch e comparacoes em 2026-09-09 retornaram 0/0 e diff vazio; main/dev/origin/main/origin/dev apontam a 5b8cd86. Checkout mudado para dev preservando os arquivos locais. AGENTS.md criado para tornar a regra visivel ao proximo agente.

Status: regra definida pelo usuario e adotada no checkout local. Publicacao e merge nao solicitados nesta analise. CI ainda faz pushes GitOps diretos main; adaptar em P-052 antes de declarar cumprimento integral pela automacao. Nao alteramos plano, visibilidade, protecoes ou workflows remotos. Esta decisao substitui as alternativas de fluxo humano em D-019, sem reescrever seu historico.


## D-019 - Fluxo de trabalho do usuario: dev -> PR -> main

TL;DR: alteracoes humanas devem partir de dev e ser promovidas por PR; sincronizar dev com main antes de retomar. Ultima atualizacao: 2026-09-09 13:31 -03:00, Codex.

Contexto: nesta sessao o usuario informou o costume de trabalhar na dev, abrir PR quando validado e integrar na main. Auditoria confirmou PR #3, mas encontrou commits posteriores diretamente na main e dev 19 commits atras. Fonte: conversa de 2026-09-09 e [parecer](03_ENTREGAVEIS/AUDITORIA_FIAP_2026-09-09_v01.md).

Decisao: registrar essa preferencia como diretriz de trabalho. Branch dev nao implica criar outro ambiente AWS. Atualizacoes automaticas de tag pelo CI precisam de politica explicita, compativel com eventual protecao de main.

Por que: mantem revisao, rastreabilidade e integracao verificavel sem mudar a arquitetura.

Alternativas: branches curtas por tarefa convergindo para dev quando houver trabalho simultaneo; commits humanos diretos em main, que nao seguem a preferencia declarada.

Status: preferencia do usuario registrada; sincronizacao e regras remotas NAO executadas nesta auditoria (P-051). Nao se presume aprovacao para mudar plano, visibilidade ou politica do repositorio.

## Registros anteriores preservados


TL;DR: decisoes cobrem guias e documentacao, condicoes de entrega (grupo, 2026-09-15), estrutura de implementacao (monorepo, Kustomize, tags), o desenho tecnico da Fase 3 e a separacao do Terraform em duas camadas com estados independentes.

Ultima atualizacao: 2026-08-27 20:40 -03:00, Claude.

## D-018 - Sem External Secrets Operator: Terraform cria os Secrets

Contexto: D-013 escolheu AWS Secrets Manager + External Secrets Operator (ESO) para os segredos. A P-037 deixou em aberto se o ESO valia a pena. Ao revisar o plano com 14 dias de prazo, a conta nao fechou: o ESO e o item S-02, sugestao das aulas, NAO requisito do enunciado - nao vale ponto sozinho.

Decisao: cortar o ESO. O Terraform da camada cluster gera as senhas com `random_password`, grava no AWS Secrets Manager e aplica os Secrets no cluster pelo provider `kubernetes`. Os 5 `externalsecret.yaml` e o `secretstore.yaml` foram removidos de `gitops/`.

Por que: o ESO e uma peca nova em runtime no caminho critico da gravacao. Se o Helm chart, a role IRSA ou o ClusterSecretStore falharem durante a sessao de 3 horas, os 5 servicos nao recebem segredo e nada sobe. Trocar isso por um recurso do Terraform - que ja roda antes de tudo e ja tem as senhas em maos - elimina o modo de falha sem perder o que interessa.

O que NAO se perde: nenhuma senha entra no Git, que e a dor citada no enunciado ("credenciais em arquivos de texto sem seguranca") e o argumento do relatorio (O-38). O Secrets Manager continua no desenho.

O que se perde: o Secret passa a nascer fora do GitOps, o que e menos "GitOps puro", e a rotacao automatica de senha deixa de ser sincronizada sozinha. Nenhum dos dois e item avaliado.

Alternativas: manter o ESO (rejeitada pelo risco em runtime); Secret versionado no Git (rejeitada - e exatamente o que o enunciado critica); preencher o Secret a mao apos o apply (rejeitada pelo mesmo motivo).

Consequencia operacional: o acoplamento entre Terraform e GitOps ficou invisivel - o Deployment referencia um Secret que nao esta versionado. Mitigacao: `gitops/SECRETS-CONTRATO.md` documenta nome e chave de cada Secret que o Terraform precisa criar.

Status: aceita em 2026-09-01, aprovada pelo usuario. Encerra P-037 e altera D-013.

## D-017 - Dois estados Terraform: base permanente e cluster efemero

Contexto: o plano previa uma unica raiz Terraform com tudo dentro. Ao explicar o ciclo de subir e derrubar, o usuario perguntou se nao seria melhor deixar tudo pronto antes de aplicar. A pergunta expos um furo: com um estado unico, o `terraform destroy` feito ao fim de cada sessao para parar de gastar credito levaria junto os repositorios ECR. Como eles usam `force_delete = true`, as imagens iriam junto, e o CI teria de reconstruir e reenviar as 5 antes de cada sessao.

Decisao: separar em duas raizes com estados independentes no mesmo bucket.
- `terraform/` - camada base: VPC, subnets, IGW, 5 repositorios ECR, SQS, DynamoDB e OIDC do CI. Estado `prod/base.tfstate`. Custo praticamente zero parada; aplicada uma vez e nunca destruida.
- `terraform/cluster/` - camada efemera: EKS, node group, 2 RDS, ElastiCache, roles IRSA e segredos. Estado `prod/cluster.tfstate`. Custo ~US$ 0,37/h; sobe e desce a cada sessao.

A camada `cluster/` le as saidas da base por `terraform_remote_state`, somente leitura. Consequencia: `cluster/` nao roda antes de a base ter sido aplicada, e o `plan` falha explicitamente nesse caso - comportamento correto.

Por que: preserva ECR, imagens, fila e tabela entre sessoes, e torna o `destroy` seguro de executar sem pensar. Sem essa separacao, a estrategia de custo definida em F-026 nao se sustenta na pratica.

Alternativas: estado unico com `terraform destroy -target` (fragil e desaconselhado pela propria HashiCorp); estado unico aceitando recriar o ECR toda vez (perderia as imagens e gastaria tempo de CI antes de cada sessao); workspaces do Terraform (resolvem separacao de ambientes, nao de ciclo de vida).

Status: aceita em 2026-08-27, aprovada pelo usuario. Implementada e validada no mesmo dia.

## D-016 - Node group com c7i-flex.large

Contexto: em 2026-08-27 o usuario confirmou 2 x `t3.medium`, dimensionados pelos requests reais da Fase 2 (F-020). Horas depois, a verificacao no repo da Fase 2 mostrou que a `t3.medium` e recusada nesta conta: "The specified instance type is not eligible for Free Tier" (F-023).

Decisao: node group com 2 x `c7i-flex.large` (2 vCPU / 4 GB), mesmo tipo usado na Fase 2. Min 1, Desejado 2, Maximo 4.

Por que: e o equivalente direto da `t3.medium` em CPU e memoria, e foi comprovadamente aceito pelo plano gratuito desta conta em 2026-07-06. As alternativas foram descartadas na Fase 2 por motivos que continuam validos: `t3.micro` tem limite de ~4 pods por no e 1 GB de RAM; a familia `t4g` e ARM e as imagens do projeto sao x86; `m7i-flex.large` custa mais sem necessidade.

Custo: cerca de US$ 0,085/h por no, aproximadamente o dobro da `t3.medium`. Nao ha escolha mais barata que funcione nesta conta.

Alternativas: sair do plano gratuito e usar `t3.medium` (descartada junto com D-015).

Status: aceita em 2026-08-27. Substitui a confirmacao de `t3.medium` dada mais cedo no mesmo dia, invalidada por bloqueio da AWS e nao por mudanca de opiniao do usuario.

## D-015 - Dois RDS mais banco do targeting em pod (caminho A)

Contexto: o enunciado exige 3 instancias RDS (O-05). A conta esta no plano gratuito novo da AWS, que recusa a terceira instancia com "maximum number of instances available with free plan accounts" (F-023). Foram avaliados tres caminhos: repetir a solucao da Fase 2, sair do plano gratuito, ou consultar o professor.

Decisao: caminho A. `auth_db` e `flags_db` em RDS; `targeting_db` como StatefulSet PostgreSQL dentro do EKS, reaproveitando os manifestos de `infra/k8s/postgres-targeting/` da Fase 2.

Por que: o professor foi consultado em 2026-08-27 e confirmou que o arranjo continua aceito na Fase 3, como ja havia sido na Fase 2. Isso remove o unico risco real da opcao. Sair do plano gratuito sairia cerca de US$ 48/mes mais barato na conta de EC2, mas exigiria metodo de pagamento e eliminaria a protecao contra gasto acidental - protecao que importa com apenas US$ 70,33 de credito restante (F-026).

Consequencias: (1) reverte parte de D-014 - os 4 arquivos de `postgres-targeting/` passam a ser COPIADOS para `gitops/base/`, nao descartados; (2) o addon `aws-ebs-csi-driver` e uma StorageClass default passam a ser obrigatorios no Terraform, senao o PVC do banco fica Pending como aconteceu na Fase 2 (F-025); (3) o desvio precisa constar do relatorio final (O-38), com o registro da aprovacao do professor.

Alternativas: sair do plano gratuito (B); 1 RDS com tres bancos dentro (nao atende "3 instancias" e a conta permite 2 de qualquer forma).

Status: aceita em 2026-08-27, escolhida pelo usuario e aprovada pelo professor. Encerra P-032 e P-033.

## D-014 - Reaproveitar os manifestos da Fase 2 como base do GitOps

Contexto: a re-analise do repo da Fase 2 em 2026-08-27 revelou `infra/k8s/`, com 28 manifestos Kubernetes completos e comentados, que nao haviam sido copiados junto com `services/` em 2026-08-26.

Decisao: `gitops/base/` sera derivado de `infra/k8s/` da Fase 2, nao escrito do zero. Aproveitados quase intactos: `00-namespaces.yaml`, os 5 `service.yaml` e os 2 `hpa.yaml`. Adaptados: os 5 `deployment.yaml`, `secret.yaml` e `configmap.yaml`. Descartados: os 4 arquivos de `postgres-targeting/` e o `ingress.yaml` (ver D-012).

Por que: probes, resources, selectors e portas ja estao definidos e testados em producao real na Fase 2. Reescrever seria reintroduzir risco sem ganho de nota. Encerra a maior parte do esforco previsto em P-021.

Alternativas: escrever os manifestos do zero.

Status: aceita em 2026-08-27.

## D-013 - Segredos via Secrets Manager + External Secrets Operator

Contexto: o enunciado descreve a dor como "as credenciais do banco de dados estao sendo passadas em arquivos de texto sem seguranca". Na Fase 2 isso e literal: `analytics` e `evaluation` recebem `AWS_ACCESS_KEY_ID` e `AWS_SECRET_ACCESS_KEY` estaticas dentro de um Secret do Kubernetes (F-017).

Decisao: o Terraform gera as senhas com `random_password` e grava no AWS Secrets Manager. O External Secrets Operator (ESO), instalado no cluster, sincroniza esses valores para Secrets do Kubernetes. As chaves estaticas da AWS somem por completo, substituidas por IRSA.

Por que: ataca diretamente a dor citada no enunciado e rende evidencia forte para o relatorio (O-38). A alternativa manual - preencher o Secret uma vez a partir do output do Terraform - e justamente o procedimento que o enunciado critica.

Alternativas: Secret do Kubernetes preenchido manualmente (opcao B, descartada); SSM Parameter Store no lugar do Secrets Manager.

Status: aceita em 2026-08-27, escolhida pelo usuario. Encerra P-023. Ressalva registrada: e o unico item do plano que pode ser cortado se o prazo apertar.

## D-012 - Sem Ingress e sem Load Balancer

Contexto: a Fase 2 tem um `ingress.yaml` funcional com nginx e 5 rotas. Manter exigiria o Nginx Ingress Controller e um Load Balancer na AWS, a ~US$ 16-20/mes. O usuario autorizou remover desde que a entrega continue atendendo a FIAP.

Decisao: nao havera Ingress nem Load Balancer. Os Services continuam `ClusterIP`. No video, o acesso a interface do ArgoCD e a qualquer verificacao nos servicos sera por `kubectl port-forward`.

Por que: o enunciado da Fase 3 foi extraido e varrido em 2026-08-27. As palavras "ingress", "load balancer", "balanceador", "acesso externo", "http", "url", "endpoint", "expor", "publico", "nginx" e "alb" aparecem **zero vezes** (F-018). Os entregaveis de video sao Terraform plan/apply, pipeline falhando e passando, atualizacao da tag no GitOps e ArgoCD sincronizando - nenhum deles depende de acesso externo. Os pods ainda precisam subir saudaveis para o ArgoCD mostra-los verdes, o que continua garantido pelos probes.

Alternativas: manter o Ingress da Fase 2 (melhor demo, ~US$ 16-20/mes a mais).

Status: aceita em 2026-08-27, autorizada pelo usuario mediante confirmacao de que atende ao enunciado.

## D-011 - Ambiente unico chamado prod

Contexto: P-005 definiu Kustomize com `base/` e `overlays/`. Faltava decidir quantos ambientes.

Decisao: um unico ambiente, `gitops/overlays/prod/`. Nao havera overlay de `dev` ou `hml`.

Por que: o enunciado nao pede multiplos ambientes e cada ambiente extra multiplicaria o custo de EKS, RDS e ElastiCache. A estrutura base+overlay fica pronta para expandir depois sem retrabalho.

Alternativas: `dev` + `prod`; overlay unico chamado `dev`.

Status: aceita em 2026-08-27, escolhida pelo usuario.

## D-010 - Modulos Terraform hibridos

Contexto: R-01 recomenda organizar o Terraform em modulos. Havia a escolha entre usar modulos da comunidade, escrever tudo a mao ou combinar.

Decisao: usar `terraform-aws-modules/vpc/aws` e `terraform-aws-modules/eks/aws` para rede e cluster; escrever modulos proprios para RDS, ElastiCache, SQS/DynamoDB, ECR e IAM.

Por que: EKS escrito do zero (OIDC provider, addons, access entries, node group) e onde projetos perdem dias, e restam poucos dias ate 2026-09-15. Os demais recursos sao simples o bastante para modulo proprio, o que preserva a autoria exigida em O-33.

Alternativas: tudo com modulos da comunidade; tudo escrito a mao.

Status: aceita em 2026-08-27, escolhida pelo usuario.

## D-009 - Padrao de tags dos recursos AWS

Contexto: recursos sem tag padronizada impedem rastrear custo por projeto no Cost Explorer, o que atrapalha o print de estimativa de custos exigido no relatorio (O-39), e dificultam saber o que pode ser destruido com seguranca.

Decisao: todo recurso AWS do projeto leva `project = fiap` e `phase = 3`, em minusculas. Chave de tag na AWS e sensivel a maiuscula/minuscula: se o Terraform usasse `Project` e o bucket `project`, o Cost Explorer mostraria dois grupos separados e a soma de custo do projeto sairia errada. Grafia confirmada pelo usuario em 2026-08-27. No Terraform isso sera aplicado uma unica vez, via `default_tags` no bloco `provider "aws"`, em vez de repetir tag por recurso. O bucket de estado ja foi criado com essas tags manualmente.

Alternativas: tags por recurso (repetitivo e facil de esquecer); nenhum padrao de tag.

Status: aceita em 2026-08-27, informada pelo usuario.

## D-008 - Kustomize na area GitOps

Contexto: P-005 perguntava se os manifestos do Kubernetes seriam YAML puro, Kustomize ou Helm. O enunciado aceita YAML ou Helm Charts (R-06) e nao exige nenhum dos dois.

Decisao: usar **Kustomize** em `gitops/`, com `base/` por microsservico e `overlays/` por ambiente. Confirmada pelo usuario em 2026-08-27; ja refletida no `README.md` desde 2026-08-26.

Por que: Kustomize e nativo do `kubectl` e do ArgoCD, nao exige templating nem manter um chart. O passo final do CI que atualiza a tag da imagem (O-24) vira um `kustomize edit set image`, que altera um unico campo de um `kustomization.yaml` - mais simples de automatizar e de auditar em diff do que reescrever `values.yaml` de Helm.

Alternativas: YAML puro (duplicaria manifesto por ambiente); Helm Charts (R-06, mais poder de templating, mais complexidade para 5 servicos parecidos).

Status: aceita em 2026-08-27, informada pelo usuario. Encerra P-005.

## D-007 - Codigo dos microsservicos neste monorepo

Contexto: P-004 perguntava se o codigo dos 5 microsservicos viria da Fase 2 para este repo ou ficaria como referencia externa. O enunciado tambem aceita repo GitOps separado ou pasta no monorepo (R-07).

Decisao: o codigo dos 5 microsservicos vive neste repositorio em `services/`, e a area GitOps e a pasta `gitops/` do mesmo monorepo. Confirmada pelo usuario em 2026-08-27; a copia ja havia sido feita em 2026-08-26.

Por que: os workflows de CI (O-10 a O-21) precisam do codigo no mesmo repo para disparar em Pull Request e push na `main`. Monorepo tambem simplifica o passo de CI que atualiza a tag no GitOps (O-24), que passa a ser um commit no proprio repositorio, sem precisar de token cruzado entre repos.

Alternativas: manter o codigo em `tech-challenge-02` como referencia externa; criar um repositorio GitOps separado (R-07).

Status: aceita em 2026-08-27, informada pelo usuario. Encerra P-004.

## D-006 - Modalidade e prazo da entrega

Contexto: o enunciado diz que o Tech Challenge "em principio" deve ser desenvolvido em grupo e pede os nomes dos participantes no relatorio, mas nao traz prazo. Os itens ficaram como [INCERTO] em P-016 e P-017.

Decisao: o usuario confirmou em 2026-07-30 que a entrega e em grupo e que o prazo final e 2026-09-15. Todo planejamento e cronograma passam a usar essa data como limite.

Alternativas: tratar como entrega individual; seguir sem data definida.

Status: aceita em 2026-07-30, informada pelo usuario. Os nomes dos integrantes ainda nao foram informados (P-018).

## D-001 - Repo destino da Fase 3

Contexto: o usuario pediu para trabalhar a terceira entrega a partir do repo `tech-challenge-03`.

Decisao: usar `C:\Users\Gabriel Silva\Documents\GitHub\tech-challenge-03` como destino de contexto, guias e proximas implementacoes.

Alternativas: editar `tech-challenge-02` diretamente.

Status: aceita em 2026-07-17.

## D-002 - Local dos guias de estudo

Contexto: materiais de origem estao em `tech-challenge-02\docs\Material aulas`, mas o projeto atual e a Fase 3.

Decisao: criar guias derivados em `docs/guias-de-estudo/fase-2/`, separados por modulo.

Alternativas: copiar os PDFs; salvar tudo em uma pasta unica; editar o repo da Fase 2.

Status: substituida por D-005 em 2026-07-18. Os guias Markdown foram removidos por decisao do usuario.

## D-005 - Guias HTML por modulo

Contexto: os guias Markdown agrupados em `docs/guias-de-estudo/fase-2/` nao atenderam ao usuario e foram apagados. O usuario decidiu estudar os materiais da Fase 3 por partes e indicou `GUIA-ESTUDO-Introducao-a-Containers.html` como padrao visual e didatico.

Decisao: criar um guia HTML por vez, salvo dentro da pasta do proprio modulo, seguindo a estrutura: introducao para leigos, glossario, fichas com finalidade/caso de uso/aplicacao no ToggleMaster e resumo.

Alternativas: manter os guias Markdown anteriores; agrupar todos os guias em uma pasta separada; gerar todos os modulos de uma vez.

Status: implementada em 2026-07-18 para os cinco modulos da Fase 3. Substitui D-002.

## D-003 - Direcao tecnica da Fase 3

Contexto: enunciado pede IaC, CI/CD, DevSecOps e GitOps para o ToggleMaster.

Decisao: preferir Terraform modular, GitHub Actions, ECR, ArgoCD e EKS. Usar conta pessoal AWS para criar IAM roles/policies via Terraform.

Alternativas: Jenkins; FluxCD; AWS Academy/LabRole; `kubectl apply` direto no CI.

Status: direcao atual.

## D-004 - Tratamento dos materiais da Fase 2

Contexto: materiais da Fase 2 ajudam a entender containers, Kubernetes, escalabilidade e balanceamento.

Decisao: usar PDFs e guias HTML existentes como fonte, mas nao copiar os PDFs para o repo da Fase 3. Registrar apenas sinteses proprias no formato vigente definido pelo usuario.

Alternativas: versionar todo o material da Fase 2 no repo da Fase 3.

Status: tratamento da fonte mantido. O formato Markdown foi substituido pelo HTML de D-005 em 2026-07-18.
