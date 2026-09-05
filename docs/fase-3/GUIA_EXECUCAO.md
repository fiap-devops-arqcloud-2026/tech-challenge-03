# Guia de execução

## 1. Configurar GitHub

Crie os Secrets `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` e, se a sessão exigir, `AWS_SESSION_TOKEN`. Eles ficam apenas no cofre do GitHub. Proteja `main` exigindo PR e aprovação dos checks.

## 2. Criar backend do Terraform

```bash
cd terraform/bootstrap
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
```

Copie o nome do bucket gerado para `terraform/environments/dev/backend.tf`, usando `backend.tf.example` como base.

## 3. Provisionar a infraestrutura

Preencha `terraform/environments/dev/terraform.tfvars` sem commitá-lo. Informe a ARN da LabRole da AWS Academy.

```bash
cd terraform/environments/dev
terraform init -backend-config=backend.tf
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

## 4. Preparar Kubernetes e Argo CD

```bash
aws eks update-kubeconfig --region us-east-2 --name togglemaster-dev
kubectl apply -f gitops/infrastructure/namespace.yaml
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl apply -f gitops/infrastructure/argocd/project.yaml
kubectl apply -f gitops/infrastructure/argocd/applications.yaml
```

Crie os cinco Secrets Kubernetes diretamente com `kubectl create secret generic`; nunca copie credenciais para o Git. Use os arquivos `secret.example.yaml` somente como lista de campos.

## 5. Entregar aplicações

Abra PR. Cada workflow executa testes, lint, SAST/SCA e Trivy. No merge em `main`, publica a imagem ECR com o SHA do commit e atualiza o manifesto GitOps; o Argo CD sincroniza o cluster.

## 6. Encerrar custos

Depois das evidências, execute `terraform destroy` no ambiente e, por último, remova o backend somente após confirmar que não precisa mais do estado. NAT Gateway, EKS, RDS e Redis geram cobrança enquanto ativos.
