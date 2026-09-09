# ============================================================
# SAIDAS - camada k8s
# ============================================================
# O que a pessoa precisa saber logo depois do apply, para operar o
# cluster e gravar o video.
# ============================================================

output "argocd_namespace" {
  description = "Namespace onde o ArgoCD foi instalado."
  value       = kubernetes_namespace_v1.argocd.metadata[0].name
}

output "argocd_port_forward" {
  description = <<-EOT
    Comando para abrir a interface do ArgoCD.

    Nao ha Ingress nem Load Balancer no projeto (D-012), entao o acesso
    e por tunel local. Rode o comando e abra http://localhost:8080.

    E esta tela que precisa aparecer no video mostrando os 5
    microsservicos sincronizados (O-32).
  EOT
  value       = "kubectl port-forward svc/argocd-server -n ${var.argocd_namespace} 8080:80"
}

output "argocd_senha_inicial" {
  description = <<-EOT
    Comando que revela a senha do usuario admin do ArgoCD.

    O chart gera a senha e a guarda num Secret. NAO imprimimos o valor
    aqui de proposito: o output ficaria gravado em texto no estado e
    poderia vazar num screenshot durante a gravacao.

    Usuario: admin
  EOT
  value       = "kubectl -n ${var.argocd_namespace} get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
}

output "secrets_criados" {
  description = <<-EOT
    Lista dos Secrets criados por esta camada no namespace das
    aplicacoes. Confira contra gitops/SECRETS-CONTRATO.md se algum pod
    ficar em CreateContainerConfigError.
  EOT
  value = [
    kubernetes_secret_v1.auth.metadata[0].name,
    kubernetes_secret_v1.flag.metadata[0].name,
    kubernetes_secret_v1.targeting.metadata[0].name,
    kubernetes_secret_v1.evaluation.metadata[0].name,
    kubernetes_secret_v1.postgres_targeting.metadata[0].name,
  ]
}

output "storage_class" {
  description = "StorageClass padrao criada. Precisa bater com o storageClassName do StatefulSet do banco."
  value       = kubernetes_storage_class_v1.gp3.metadata[0].name
}

output "credencial_do_repo_criada" {
  description = <<-EOT
    Indica se a credencial de leitura do repositorio foi criada.

    false com repositorio PRIVADO significa que o ArgoCD nao vai
    conseguir clonar, e a Application ficara em estado Unknown com
    "authentication required". Nesse caso, informe o token:

      $env:TF_VAR_github_token = "ghp_xxxx"   (PowerShell)
      export TF_VAR_github_token=ghp_xxxx     (bash)

    e rode o apply de novo.
  EOT
  value       = length(kubernetes_secret_v1.argocd_repo) > 0
}
