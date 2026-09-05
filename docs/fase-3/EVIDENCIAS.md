# Checklist de evidências

- [ ] `terraform plan` e `apply` concluídos
- [ ] VPC, quatro sub-redes e rotas no console AWS
- [ ] EKS e node group ativos
- [ ] Três instâncias RDS privadas
- [ ] Redis, SQS/DLQ, DynamoDB e cinco ECR
- [ ] PR com os cinco pipelines verdes
- [ ] Imagens ECR usando SHA, nunca somente `latest`
- [ ] Argo CD mostrando cinco aplicações `Healthy` e `Synced`
- [ ] Teste funcional de criação e avaliação de feature flag
- [ ] Evidência de evento no DynamoDB
- [ ] Estimativa de custos e prova de `terraform destroy`

Não inclua senhas, tokens, conteúdo de Secrets, kubeconfig ou valores do state nas capturas.
