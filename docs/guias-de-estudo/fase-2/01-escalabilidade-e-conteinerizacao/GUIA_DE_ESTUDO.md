# Guia de Estudo - Escalabilidade e Conteinerizacao

Fonte analisada em 2026-07-17: `tech-challenge-02/docs/Material aulas/1 - Escalabilidade e Conteinerizacao/POSTECH - Capitulo de projeto - Fase 2.pdf`.

## Resumo para leigos

Este modulo e a porta de entrada da Fase 2. Ele explica que aplicacoes modernas nao podem depender de uma unica maquina configurada manualmente. Elas precisam ser empacotadas em containers, rodar em Kubernetes e crescer conforme a demanda.

Pense em um restaurante: se so existe um cozinheiro e aparecem muitos clientes, tudo trava. A escalabilidade e a capacidade de colocar mais cozinheiros, organizar pedidos, distribuir trabalho e manter a qualidade sem o cliente perceber a complexidade.

## Explicacao tecnica

A Fase 2 prepara a base operacional do ToggleMaster:

- Docker empacota cada servico com suas dependencias.
- Kubernetes orquestra os containers em um cluster.
- Estrategias de escalabilidade mantem disponibilidade em picos de acesso.
- Balanceadores e proxies distribuem trafego.
- Health checks e failover reduzem impacto de falhas.

Na Fase 3, nao vamos abandonar isso. Vamos automatizar essa base com Terraform, CI/CD, DevSecOps e GitOps.

## O que o modulo cobre

- Introducao a containers e Docker.
- Kubernetes como orquestrador.
- Estrategias de deploy e escalabilidade.
- Balanceamento de carga e servidores web.
- Preparacao de uma aplicacao para cenario real de producao.

## Siglas e termos

- Container: pacote executavel da aplicacao com dependencias.
- Kubernetes: plataforma que gerencia containers em escala.
- Escalabilidade: capacidade de crescer para atender mais demanda.
- Load balancer: componente que distribui acessos entre instancias.
- Failover: troca automatica para outro recurso quando um falha.
- Health check: verificacao automatica de saude de um servico.

## Caso de uso no ToggleMaster

O ToggleMaster possui 5 microsservicos. A Fase 2 ensinou a empacotar e rodar esses servicos em containers e Kubernetes. A Fase 3 usa essa mesma base, mas troca operacoes manuais por automacao:

- Dockerfiles viram parte do pipeline.
- Imagens vao para o ECR.
- Kubernetes roda no EKS.
- Manifests passam a ser controlados por GitOps com ArgoCD.
- Infraestrutura nasce via Terraform.

## Checklist de estudo

- [ ] Entender por que containerizar uma aplicacao.
- [ ] Entender por que Kubernetes e usado em microsservicos.
- [ ] Diferenciar escalabilidade, alta disponibilidade e performance.
- [ ] Saber explicar por que a Fase 3 automatiza o que a Fase 2 construiu.
