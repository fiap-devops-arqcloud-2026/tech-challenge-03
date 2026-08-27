output "repository_urls" {
  description = "URL de cada repositorio, no formato <conta>.dkr.ecr.<regiao>.amazonaws.com/<servico>-service. E o valor que o pipeline usa no docker push e que o Kustomize usa no campo images."
  value       = { for k, r in aws_ecr_repository.this : k => r.repository_url }
}

output "repository_arns" {
  description = "ARNs dos repositorios. Usado para restringir a policy do CI apenas a estes 5 recursos, em vez de liberar ecr:* em tudo."
  value       = [for r in aws_ecr_repository.this : r.arn]
}

output "repository_names" {
  description = "Nomes dos repositorios."
  value       = { for k, r in aws_ecr_repository.this : k => r.name }
}
