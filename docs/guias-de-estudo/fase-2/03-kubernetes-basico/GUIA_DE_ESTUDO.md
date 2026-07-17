# Guia de Estudo - Kubernetes Basico

Fonte analisada em 2026-07-17: `tech-challenge-02/docs/Material aulas/3 - Kubernetes basico`.

## Resumo para leigos

Kubernetes e o "gerente" dos containers. Se um container cai, ele sobe outro. Se precisa de mais copias, ele cria. Se uma aplicacao precisa ser acessada, ele organiza a rede. Em vez de cuidar de container por container, voce declara o estado desejado.

## Explicacao tecnica

Um cluster Kubernetes possui Control Plane e Worker Nodes. O Control Plane decide e registra o estado do cluster; os Worker Nodes executam os Pods. Aplicacoes sao normalmente gerenciadas por Deployments, expostas por Services e Ingress, configuradas com ConfigMaps e Secrets, e escaladas por mecanismos como HPA.

## Aulas

### Aula 1 - Introducao e Arquitetura do Kubernetes

Simples: apresenta Kubernetes como plataforma para rodar containers com controle, escala e recuperacao automatica.

Tecnico: cobre API Server, etcd, Scheduler, Controller Manager, kubelet, Pods, Services, ReplicaSets e Ingress.

No projeto: o EKS sera o cluster Kubernetes gerenciado onde os 5 microsservicos vao rodar.

### Aula 2 - Control Plane e Worker Nodes

Simples: Control Plane e o "cerebro"; Worker Nodes sao os "bracos" que executam os containers.

Tecnico: Control Plane inclui API Server, etcd, Scheduler e Controller Manager. Worker Nodes usam kubelet, kube-proxy e container runtime.

No projeto: a AWS gerencia parte do Control Plane no EKS, e nossos Node Groups executam os Pods.

### Aula 3 - Preparando o Ambiente e Primeiro Contato

Simples: ensina a criar ambiente local e usar `kubectl`.

Tecnico: compara Minikube, Kind e Docker Desktop. `kubectl` e a CLI principal para interagir com o cluster.

No projeto: `kubectl` ajuda a diagnosticar, mas o deploy final deve ser GitOps via ArgoCD, nao comandos manuais.

### Aula 4 - Pods e Deployments

Simples: Pod e a menor unidade que roda; Deployment garante que existam copias saudaveis.

Tecnico: Deployments controlam ReplicaSets, atualizacoes, rollback e autorrecuperacao.

No projeto: cada microsservico deve ter um Deployment com replicas, probes e imagem vinda do ECR.

### Aula 5 - Services, Ingress, ConfigMaps e Secrets

Simples: Service da nome e endereco interno; Ingress e porta de entrada; ConfigMap guarda configuracao; Secret guarda dado sensivel.

Tecnico: diferencia ClusterIP, NodePort e LoadBalancer; Ingress faz roteamento HTTP; ConfigMaps e Secrets desacoplam configuracao da imagem.

No projeto: Ingress pode expor rotas como `/flags`, `/evaluate` e `/rules`; Secrets devem evitar credenciais em texto no repo.

### Aula 6 - Volumes Persistentes

Simples: containers sao temporarios; dados importantes precisam sobreviver.

Tecnico: cobre PV, PVC, StorageClass e modos de acesso como RWO, RWX e ROX.

No projeto: bancos principais devem ser RDS/DynamoDB/Redis/SQS. Volumes Kubernetes podem servir para componentes internos, mas dados criticos devem preferir servicos gerenciados.

### Aula 7 - Escalabilidade Automatica

Simples: Kubernetes pode aumentar ou reduzir copias automaticamente conforme demanda.

Tecnico: HPA escala Pods por metricas; VPA ajusta recursos; Cluster Autoscaler ajusta quantidade de nodes.

No projeto: HPA faz sentido para `evaluation-service`, que e caminho quente de avaliacao de feature flags.

## Glossario

- Cluster: conjunto de maquinas Kubernetes.
- Node: maquina que participa do cluster.
- Pod: menor unidade executavel.
- Deployment: controlador de replicas e atualizacoes.
- Service: acesso estavel para Pods.
- Ingress: roteamento HTTP/HTTPS de entrada.
- ConfigMap: configuracao nao sensivel.
- Secret: configuracao sensivel.
- PV/PVC: volume persistente e pedido de volume.
- HPA: Horizontal Pod Autoscaler.
- VPA: Vertical Pod Autoscaler.

## Caso de uso no ToggleMaster

- `auth-service`, `flag-service`, `targeting-service`, `evaluation-service` e `analytics-service` viram Deployments.
- Services internos permitem comunicacao entre microsservicos.
- Ingress concentra entrada publica.
- ConfigMaps guardam URLs e nomes de recursos.
- Secrets devem vir de mecanismo seguro, evitando arquivo sensivel no Git.
- HPA pode proteger servicos com maior carga.

## Checklist de estudo

- [ ] Explicar Control Plane versus Worker Node.
- [ ] Explicar Pod, Deployment, Service e Ingress.
- [ ] Entender ConfigMap versus Secret.
- [ ] Saber por que dados criticos nao devem depender de container efemero.
- [ ] Saber como HPA ajuda em picos.
