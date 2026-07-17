# Guia de Estudo - Escalabilidade nos Servidores

Fonte analisada em 2026-07-17: `tech-challenge-02/docs/Material aulas/5 - Escalabilidade nos servidores`.

## Resumo para leigos

Escalabilidade e a capacidade de o sistema continuar funcionando quando muita gente usa ao mesmo tempo. Para isso, nao basta "colocar uma maquina maior". Muitas vezes e melhor distribuir trabalho, usar cache, filas, copias e monitoramento.

## Explicacao tecnica

O modulo apresenta fundamentos de escala vertical/horizontal, load balancers, arquitetura stateless, filas/workers, CDN, escalabilidade de banco de dados, resiliencia, observabilidade e trade-offs entre custo, performance e complexidade.

## Aulas

### Aula 1 - Fundamentos de Escalabilidade Moderna

Simples: escalar e fazer o sistema aguentar mais demanda.

Tecnico: diferencia escalabilidade, performance e otimizacao. Apresenta escala vertical, escala horizontal e elasticidade.

No projeto: EKS e HPA representam escala horizontal; escolha de instancias e RDS representam capacidade/custo.

### Aula 2 - Load Balancers na Pratica

Simples: load balancer distribui acessos para varios servidores.

Tecnico: diferencia camada 4 e camada 7, algoritmos de balanceamento e health checks.

No projeto: AWS Load Balancer/Ingress distribui trafego para os Services do Kubernetes.

### Aula 3 - Padroes de Escala Horizontal em Cloud

Simples: aplicacao precisa ser facil de copiar.

Tecnico: reforca arquitetura stateless, workers e filas, ReplicaSets, Auto Scaling Groups, Sidecar, Ambassador e Sharding.

No projeto: `analytics-service` com SQS e worker e exemplo direto de desacoplamento por fila.

### Aula 4 - CDN e Performance Global

Simples: CDN aproxima conteudo do usuario para reduzir demora.

Tecnico: CDNs usam PoPs, edge locations, cache hit, BGP, peering e podem integrar WAF.

No projeto: nao e requisito essencial, mas pode entrar como melhoria para frontend/documentacao ou APIs publicas se houver necessidade global.

### Aula 5 - Escalabilidade de Banco de Dados

Simples: banco costuma virar gargalo porque todo mundo precisa ler ou gravar nele.

Tecnico: aborda caching, read replicas, sharding, Teorema CAP, consistencia eventual, failover, RPO e RTO.

No projeto: Redis acelera `evaluation-service`; RDS guarda auth/flags/targeting; DynamoDB recebe analytics; SQS desacopla escrita analitica.

### Aula 6 - Arquiteturas Escalaveis no Mundo Real

Simples: junta as pecas para transformar arquitetura fragil em resiliente.

Tecnico: compara serverless, microsservicos e monolitos escalaveis; reforca observabilidade por metricas, logs e traces.

No projeto: ToggleMaster ja e microsservicos; a Fase 3 deve adicionar automacao, monitoramento basico e evidencias de confiabilidade.

## Glossario

- Escala vertical: aumentar recursos da mesma maquina.
- Escala horizontal: adicionar mais instancias.
- Elasticidade: crescer e reduzir automaticamente.
- Load balancer: distribuidor de trafego.
- Stateless: aplicacao sem estado local obrigatorio.
- Worker: processo que consome tarefas em segundo plano.
- CDN: Content Delivery Network.
- Cache: armazenamento temporario para acelerar leitura.
- Read replica: copia de banco para leitura.
- Sharding: divisao de dados em particoes.
- CAP: teorema sobre consistencia, disponibilidade e tolerancia a particao.
- RPO: Recovery Point Objective, perda maxima aceitavel de dados.
- RTO: Recovery Time Objective, tempo maximo aceitavel para recuperar.

## Caso de uso no ToggleMaster

- `evaluation-service` deve ser stateless e rapido.
- Redis funciona como cache de baixa latencia.
- SQS protege `analytics-service` de picos.
- DynamoDB e adequado para eventos analiticos.
- RDS atende dados transacionais dos servicos.
- HPA e KEDA podem escalar servicos conforme trafego e fila.

## Checklist de estudo

- [ ] Diferenciar escala vertical e horizontal.
- [ ] Explicar por que stateless facilita escala.
- [ ] Entender load balancer, cache e fila.
- [ ] Explicar por que banco vira gargalo.
- [ ] Relacionar Redis, SQS, DynamoDB e RDS com o ToggleMaster.
