# Política de segurança

Este projeto foi construído sobre uma premissa: **nenhuma credencial estática
existe em lugar nenhum** — nem no repositório, nem nos segredos do GitHub, nem
dentro do cluster.

## Como as credenciais funcionam aqui

| Quem precisa de acesso | Como obtém | O que NÃO existe |
|---|---|---|
| O pipeline de CI, para publicar no ECR | Federação de identidade OpenID Connect: o GitHub Actions troca um token de execução por credencial temporária da AWS | `AWS_ACCESS_KEY_ID` e `AWS_SECRET_ACCESS_KEY` nos segredos do repositório |
| Os pods, para usar a fila e a tabela | Identidade de conta de serviço (IRSA): cada pod recebe credencial temporária ligada à sua própria conta de serviço | Chave de acesso dentro de um Secret do Kubernetes |
| As aplicações, para falar com os bancos | Senhas geradas pelo Terraform, entregues por Secret do Kubernetes | Senha escrita à mão em arquivo |

A política de confiança da role do CI é restrita a este repositório: um token
vindo de qualquer outro repositório do GitHub é recusado.

## Nunca versionar

- `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` ou `AWS_SESSION_TOKEN` reais
- Senha ou string de conexão real de RDS ou Redis
- `MASTER_KEY` ou `SERVICE_API_KEY` reais
- `.env`, `terraform.tfstate`, `*.tfvars`, kubeconfig, certificados ou tokens

O arquivo de estado do Terraform merece atenção especial: ele guarda as senhas
dos bancos **em texto puro**. É por isso que o estado vive num bucket S3 com
criptografia e versionamento, e nunca no disco de quem aplica.

## Antes de cada push

```bash
# Varre os arquivos versionados atrás de chaves da AWS, chaves privadas e
# atribuições suspeitas de segredo. Sai com erro se encontrar algo.
./scripts/security-check.sh
```

```bash
# Leia o que você está prestes a enviar. É a verificação mais barata que existe.
git diff --cached
```

A verificação completa — que inclui a varredura acima, mais formatação e
validação do Terraform, renderização dos manifestos e compilação dos serviços —
está em `scripts/validate-all.sh`.

## Se uma credencial vazar

1. **Revogue imediatamente** na AWS ou no GitHub. Trocar o arquivo não basta:
   a credencial continua válida até ser revogada.
2. Remova do histórico do Git. Apagar do arquivo e commitar por cima **não**
   remove — o valor continua acessível em qualquer commit anterior.
3. Gere uma credencial nova e confirme que a antiga não funciona mais.
