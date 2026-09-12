# Checklist de evidencias

> Atualizado em 2026-09-09 para bater com a arquitetura entregue: sao
> **2 RDS + 1 banco em pod** (D-015) e **uma Application do ArgoCD**
> gerenciando os 5 servicos, nao cinco Applications.
>
> O acompanhamento item a item do enunciado esta em
> [`CHECKLIST_REQUISITOS_FASE3.md`](../CHECKLIST_REQUISITOS_FASE3.md).
> Esta lista e mais curta de proposito: e o que precisa aparecer **na
> tela**, durante a gravacao.

## Ja comprovado, sem precisar do cluster

- [x] Os 5 pipelines verdes no GitHub Actions
- [x] Pipeline **falhando** em vulnerabilidade CRITICAL e o job de imagem ficando `skipped`
- [x] Imagens no ECR com tag `v1.0.0-<commit>`, nunca so `latest`
- [x] Commit `chore(gitops)` feito pelo proprio pipeline, atualizando a tag
- [x] Estado do Terraform no S3, nada local
- [x] VPC, sub-redes, ECR, SQS + DLQ e DynamoDB no console

## Depende do cluster no ar

- [ ] `terraform apply` das camadas cluster e k8s concluidos
- [ ] EKS e node group ativos no console
- [ ] As 2 instancias RDS privadas + o pod `postgres-targeting` rodando
- [ ] ElastiCache Redis ativo
- [ ] Argo CD com a Application `togglemaster` em `Healthy` e `Synced`
- [ ] Interface do Argo CD mostrando os 5 microsservicos
- [ ] Mudanca de tag no Git sendo sincronizada sozinha pelo Argo CD
- [ ] Teste funcional: criar uma flag e avalia-la ponta a ponta
- [ ] Evento gravado na tabela DynamoDB

## Entregaveis finais

- [ ] Video de ate 20 minutos
- [ ] Relatorio com integrantes, links, desafios/decisoes e print de custo
