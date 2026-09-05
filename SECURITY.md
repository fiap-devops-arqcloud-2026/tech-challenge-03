# Política de segurança

## Nunca versionar

- `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` ou `AWS_SESSION_TOKEN` reais;
- senha/string de conexão real de RDS ou Redis;
- `MASTER_KEY` ou `SERVICE_API_KEY` reais;
- `.env`, `terraform.tfstate`, `*.tfvars`, kubeconfig, certificados ou tokens.

Credenciais temporárias do AWS Academy devem existir somente na sessão local ou nos GitHub Actions Secrets. Os manifests não contêm access keys; no EKS, os SDKs usam a identidade do Node Group (`LabRole`).

Antes de cada push:

```bash
./scripts/security-check.sh
git diff --cached
```

Se uma credencial real for publicada, revogue-a imediatamente e remova-a de todo o histórico.

