# ============================================================
# SAIDAS DO MODULO ECR
# ============================================================
# Output e como um modulo devolve valor para quem o chamou. Sem isto,
# tudo que acontece dentro do modulo fica invisivel para o main.tf.
# ============================================================

output "repository_urls" {
  description = "URL de cada repositorio, no formato <conta>.dkr.ecr.<regiao>.amazonaws.com/<servico>-service. E o valor que o pipeline usa no docker push e que o Kustomize usa no campo images."

  # Expressao "for": percorre o mapa de repositorios e monta um novo mapa.
  # k e a chave ("auth"); r e o objeto do repositorio.
  # Resultado: { "auth" = "891...amazonaws.com/auth-service", ... }
  value = { for k, r in aws_ecr_repository.this : k => r.repository_url }
}

output "repository_arns" {
  description = "ARNs dos repositorios. Usado para restringir a policy do CI apenas a estes 5 recursos, em vez de liberar ecr:* em tudo."

  # Colchetes em vez de chaves: aqui a saida e uma LISTA simples de ARNs,
  # que e o formato esperado pelo campo `resources` de uma policy IAM.
  value = [for r in aws_ecr_repository.this : r.arn]
}

output "repository_names" {
  description = "Nomes dos repositorios, uteis para comandos manuais da AWS CLI."
  value       = { for k, r in aws_ecr_repository.this : k => r.name }
}
