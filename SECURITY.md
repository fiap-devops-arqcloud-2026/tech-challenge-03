# Política de segurança

Este projeto foi construído sobre uma premissa: **nenhuma credencial estática
de nuvem**. O pipeline de CI entra na AWS por OIDC e os pods, por IRSA. Não há
chave de acesso da AWS no repositório, nos segredos do GitHub nem dentro do
cluster.

Os segredos de aplicação (`MASTER_KEY` e `SERVICE_API_KEY`) e as senhas dos
bancos existem, mas são gerados pelo Terraform, entregues por Secret do
Kubernetes e ficam guardados no estado do Terraform. Nunca vão para o Git.

## Como as credenciais funcionam aqui

| Quem precisa de acesso | Como obtém | O que NÃO existe |
|---|---|---|
| O pipeline de CI, para publicar no ECR | Federação de identidade OpenID Connect: o GitHub Actions troca um token de execução por credencial temporária da AWS | `AWS_ACCESS_KEY_ID` e `AWS_SECRET_ACCESS_KEY` nos segredos do repositório |
| Os pods, para usar a fila e a tabela | Identidade de conta de serviço (IRSA): cada pod recebe credencial temporária ligada à sua própria conta de serviço | Chave de acesso dentro de um Secret do Kubernetes |
| As aplicações, para falar com os bancos | Senhas geradas pelo Terraform, entregues por Secret do Kubernetes | Senha escrita à mão em arquivo |

A política de confiança da role do CI aceita apenas tokens deste repositório:
um token vindo de qualquer outro repositório do GitHub é recusado. Dentro do
repositório, ela aceita qualquer branch ou pull request. Quem limita a
publicação de imagens à `main` é a condição dos jobs no workflow, não a AWS.

## Nunca versionar

- `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` ou `AWS_SESSION_TOKEN` reais
- Senha ou string de conexão real de RDS ou Redis
- `MASTER_KEY` ou `SERVICE_API_KEY` reais
- `.env`, `terraform.tfstate`, `*.tfvars`, kubeconfig, certificados ou tokens

O arquivo de estado do Terraform merece atenção especial: ele guarda as senhas
dos bancos e os segredos de aplicação **em texto puro**. É por isso que o
estado vive num bucket S3, e nunca no disco de quem aplica. O bucket é
privado, versionado, criptografado e só aceita conexões TLS; a criação está em
[`docs/GUIA_DE_REPRODUCAO.md`](docs/GUIA_DE_REPRODUCAO.md#3-bucket-de-estado-do-terraform).

## Antes de cada push

```bash
# Varre os arquivos versionados atrás de chaves da AWS, chaves privadas e atribuições suspeitas de segredo; sai com erro se encontrar algo
./scripts/security-check.sh
```

```bash
# Mostra o que está prestes a ser enviado; é a verificação mais barata que existe
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
