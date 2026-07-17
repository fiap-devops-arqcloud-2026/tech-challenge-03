# Guia de Estudo - Servidores Web e Balanceamento de Carga

Fonte analisada em 2026-07-17: `tech-challenge-02/docs/Material aulas/6 - Servidores Web e Balanceamento de Carga`.

## Resumo para leigos

Servidores web e balanceadores ficam na porta de entrada do sistema. Eles recebem pedidos dos usuarios, encaminham para a aplicacao certa, evitam sobrecarga e ajudam a manter tudo online mesmo quando partes falham.

## Explicacao tecnica

O modulo cobre Nginx, Apache, proxy reverso, balanceamento de carga, health checks, failover, Ingress no Kubernetes, TLS, cert-manager, Service Mesh com Istio, mTLS, observabilidade, alta disponibilidade e WAF.

## Aulas

### Aula 1 - Servidores Web com Nginx e Apache

Simples: Apache e Nginx entregam conteudo web e podem encaminhar requisicoes.

Tecnico: compara arquiteturas, forward proxy, reverse proxy, conexoes, headers como `X-Forwarded-For` e otimizacoes como keepalive.

No projeto: Nginx aparece principalmente como Ingress Controller ou proxy reverso de entrada.

### Aula 2 - Balanceamento de Carga na Pratica

Simples: divide acessos entre varios servidores para nenhum ficar sobrecarregado.

Tecnico: algoritmos Round Robin, Least Connections e IP Hash; health checks; failover; `stub_status`; testes com Apache Bench.

No projeto: Kubernetes Services e AWS Load Balancer fazem esse papel para os Pods.

### Aula 3 - Gerenciamento de Trafego no Kubernetes

Simples: Ingress e a porta de entrada inteligente do cluster.

Tecnico: Nginx Ingress Controller interpreta regras de host/path, faz rewrite de URL e pode automatizar TLS com cert-manager.

No projeto: podemos usar Ingress para expor rotas dos microsservicos sem abrir cada Service publicamente.

### Aula 4 - Service Mesh com Istio

Simples: Service Mesh controla comunicacao entre servicos sem colocar toda logica no codigo.

Tecnico: Istio usa sidecars, roteamento avancado, Canary, A/B testing, mTLS, AuthorizationPolicy e observabilidade.

No projeto: Istio e poderoso, mas talvez seja excesso para a entrega minima. Pode ficar como melhoria futura ou referencia para Canary/mTLS.

### Aula 5 - Alta Disponibilidade e Seguranca

Simples: sistema bom precisa continuar no ar e bloquear ataques comuns.

Tecnico: aborda HA, SLA, SLO, SPOF, ativo-ativo, ativo-passivo, Keepalived, WAF, ModSecurity e OWASP Core Rule Set.

No projeto: HA vem de EKS com multiplas AZs, replicas, health checks e servicos gerenciados. WAF pode ser desejavel se houver exposicao publica relevante.

## Glossario

- Nginx: servidor web/proxy muito usado em alta performance.
- Apache: servidor web tradicional e extensivel.
- Proxy reverso: recebe requisicoes e encaminha para servicos internos.
- Load balancing: distribuicao de carga.
- Round Robin: alterna entre servidores.
- Least Connections: envia para quem tem menos conexoes.
- IP Hash: tenta manter mesmo cliente no mesmo backend.
- Ingress: regra de entrada HTTP/HTTPS no Kubernetes.
- TLS: criptografia de trafego HTTPS.
- cert-manager: automacao de certificados no Kubernetes.
- Service Mesh: camada de controle de comunicacao entre servicos.
- mTLS: TLS mutuo, ambos os lados se autenticam.
- WAF: Web Application Firewall.
- SLA/SLO: metas de disponibilidade e qualidade.
- SPOF: ponto unico de falha.

## Caso de uso no ToggleMaster

- Entrada publica pode passar por Load Balancer AWS e Ingress.
- Rotas podem ser separadas por path: `/flags`, `/evaluate`, `/rules`, etc.
- Health checks garantem que trafego so chegue a Pods saudaveis.
- TLS protege trafego externo.
- WAF/ModSecurity e Istio sao desejaveis, mas nao essenciais para cumprir o enunciado.

## Checklist de estudo

- [ ] Explicar proxy reverso.
- [ ] Diferenciar algoritmos de balanceamento.
- [ ] Entender Ingress no Kubernetes.
- [ ] Saber o papel de TLS/cert-manager.
- [ ] Entender HA, SLA, SLO e SPOF.
- [ ] Saber quando Service Mesh e util e quando e excesso.
