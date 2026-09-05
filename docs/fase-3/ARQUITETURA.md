# Arquitetura da Fase 3

## Visão geral

```mermaid
flowchart TB
  U[Cliente] --> ALB[Ingress / Load Balancer]
  ALB --> EKS[EKS: 5 microsserviços]
  EKS --> RDS[(3 PostgreSQL RDS)]
  EKS --> REDIS[(ElastiCache Redis)]
  EKS --> SQS[SQS + DLQ]
  SQS --> ANA[Analytics Service]
  ANA --> DDB[(DynamoDB Analytics)]
  GHA[GitHub Actions] --> ECR[5 repositórios ECR]
  GHA --> GIT[Manifests GitOps]
  ARGO[Argo CD] --> GIT
  ARGO --> EKS
```

Tudo é provisionado em `us-east-2`. A VPC possui duas sub-redes públicas e duas privadas em zonas distintas. EKS e bancos ficam nas privadas; o tráfego externo entra pelo Ingress. O Terraform reutiliza a `LabRole` fornecida pela AWS Academy e não cria IAM Roles.

## Mapa mental

```mermaid
mindmap
  root((Fase 3))
    Terraform
      VPC
      EKS
      RDS x3
      Redis
      SQS
      DynamoDB
      ECR x5
    DevSecOps
      Testes
      Lint
      SAST e SCA
      Trivy
      Imagem por SHA
    GitOps
      Argo CD
      Auto sync
      Self-heal
      Cinco aplicações
    Entrega
      Evidências
      Custos
      Vídeo até 20 min
```

## Segurança

- Nenhuma credencial é versionada; somente arquivos `.example`.
- Estado Terraform remoto usa S3 com criptografia, versionamento e bloqueio público.
- RDS e Redis não são públicos.
- Imagens ECR são imutáveis e escaneadas no push.
- Pipelines falham em vulnerabilidade crítica.
- Workloads AWS usam identidade do ambiente, não chaves estáticas em Kubernetes.
