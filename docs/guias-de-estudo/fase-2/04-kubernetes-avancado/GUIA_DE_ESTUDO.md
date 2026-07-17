# Guia de Estudo - Kubernetes Avancado

Fonte analisada em 2026-07-17: `tech-challenge-02/docs/Material aulas/4 - Kubernetes Avancado`.

## Resumo para leigos

Kubernetes basico coloca a aplicacao de pe. Kubernetes avancado ensina a deixar a aplicacao resistente: saber se esta saudavel, atualizar sem derrubar, escalar melhor, gastar menos e proteger o cluster.

## Explicacao tecnica

O modulo aprofunda operacao em producao: probes, requests/limits, scheduling, rollouts, Helm, Blue/Green, Canary, Karpenter, KEDA e seguranca com identidade, RBAC e politicas.

## Aulas

### Aula 1 - Saude da Aplicacao e Recursos

Simples: Kubernetes precisa saber se a aplicacao esta viva, pronta e inicializando.

Tecnico: Liveness Probe reinicia container travado; Readiness Probe controla se recebe trafego; Startup Probe protege aplicacoes lentas. Requests e limits definem consumo minimo e maximo de CPU/memoria.

No projeto: todos os microsservicos devem ter probes e recursos definidos para melhorar estabilidade e permitir autoscaling.

### Aula 2 - Agendamento Avancado e Nodes

Simples: nem todo Pod deve rodar em qualquer maquina.

Tecnico: nodeSelector, affinity, anti-affinity, taints, tolerations, eviction e PDB ajudam a posicionar workloads e lidar com falhas/pressao de recursos.

No projeto: workloads criticos podem ser espalhados entre nodes/AZs para reduzir risco.

### Aula 3 - Estrategias de Atualizacao e Rollouts

Simples: atualizar sem apagar a luz.

Tecnico: Deployments usam RollingUpdate, `maxSurge`, `maxUnavailable`, historico e rollback.

No projeto: ArgoCD pode aplicar manifests que usam RollingUpdate como estrategia padrao segura.

### Aula 4 - Helm Charts

Simples: Helm empacota varios YAMLs Kubernetes em um pacote configuravel.

Tecnico: Charts usam templates, `values.yaml`, versionamento e releases para padronizar instalacoes.

No projeto: Helm pode ser usado para padronizar os 5 microsservicos ou instalar ArgoCD/Ingress, mas YAML/Kustomize tambem pode atender se quisermos simplicidade.

### Aula 5 - Blue/Green

Simples: manter versao antiga e nova lado a lado; quando a nova esta boa, vira a chave.

Tecnico: dois ambientes ou conjuntos de Pods recebem trafego via Service/Ingress. Rollback e rapido porque a versao antiga continua disponivel.

No projeto: e otimo para demonstracao, mas pode dobrar custo. Pode ficar como estrategia desejavel.

### Aula 6 - Canary

Simples: liberar a versao nova para pouca gente antes de liberar para todos.

Tecnico: divide trafego por porcentagem, monitora metricas e decide promover ou reverter.

No projeto: combina com `evaluation-service`, que e sensivel a performance, mas exige controle de trafego mais avancado.

### Aula 7 - Karpenter

Simples: Karpenter cria maquinas do cluster de forma mais inteligente.

Tecnico: autoscaler de nodes da AWS que escolhe tipos de instancia, usa Spot quando possivel, faz bin packing e consolida nodes ociosos.

No projeto: pode otimizar custo no EKS, mas para entrega academica talvez seja melhoria futura.

### Aula 8 - KEDA

Simples: KEDA escala aplicacoes com base em eventos, como tamanho de fila.

Tecnico: complementa HPA e permite scale-to-zero com fontes como SQS, Kafka, RabbitMQ e Prometheus.

No projeto: `analytics-service` consome SQS; KEDA com scaler de SQS seria um caso de uso muito forte.

### Aula 9 - Seguranca no Cluster

Simples: cada aplicacao deve ter permissao minima e identidade propria.

Tecnico: ServiceAccounts, RBAC, ABAC, admission controllers, politicas, imagens assinadas e controles de supply chain reduzem risco.

No projeto: usar least privilege para workloads e pipeline. Nao usar credenciais genericas dentro de Pods.

## Glossario

- Probe: verificacao de saude.
- Request: recurso minimo reservado.
- Limit: recurso maximo permitido.
- Affinity: preferencia/regra de agendamento.
- Taint/Toleration: mecanismo para restringir quais Pods rodam em nodes.
- PDB: PodDisruptionBudget, limite de interrupcoes voluntarias.
- Helm: gerenciador de pacotes Kubernetes.
- Blue/Green: deploy com duas versoes paralelas.
- Canary: deploy gradual para parte do trafego.
- Karpenter: autoscaler de nodes para Kubernetes na AWS.
- KEDA: autoscaler baseado em eventos.
- RBAC: controle de acesso baseado em papeis.

## Caso de uso no ToggleMaster

- Probes em todos os Deployments.
- Requests/limits para evitar disputa de recursos.
- HPA para servicos HTTP.
- KEDA para `analytics-service` baseado em SQS.
- Helm ou Kustomize para reduzir repeticao nos manifests.
- RBAC/ServiceAccounts para limitar acesso a AWS/Kubernetes.
- ArgoCD para aplicar rollouts declarativos.

## Checklist de estudo

- [ ] Explicar liveness, readiness e startup probe.
- [ ] Entender requests e limits.
- [ ] Saber quando usar Helm.
- [ ] Diferenciar RollingUpdate, Blue/Green e Canary.
- [ ] Entender Karpenter versus KEDA.
- [ ] Explicar RBAC e ServiceAccount.
