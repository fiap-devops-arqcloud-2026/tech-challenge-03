# DECISOES

TL;DR: decisoes cobrem guias e documentacao, condicoes de entrega (grupo, 2026-09-15), estrutura de implementacao (monorepo, Kustomize, tags), e o desenho tecnico da Fase 3: modulos hibridos, ambiente unico prod, sem Ingress, segredos via Secrets Manager + ESO e reaproveitamento dos manifestos da Fase 2.

Ultima atualizacao: 2026-08-27 14:05 -03:00, Claude.

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

Decisao: todo recurso AWS do projeto leva `Project = fiap` e `Phase = 3`. No Terraform isso sera aplicado uma unica vez, via `default_tags` no bloco `provider "aws"`, em vez de repetir tag por recurso. O bucket de estado ja foi criado com essas tags manualmente.

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
