# BOOTSTRAP-BACKEND-S3

TL;DR: passo a passo para criar, uma unica vez e fora do Terraform, o bucket S3 que vai guardar o `terraform.tfstate` do ToggleMaster. Atende O-09 e R-03 do `docs/00_COLAB_IA/CHECKLIST_REQUISITOS_FASE3.md`. Depois deste passo, todo o resto da infraestrutura sera criado por Terraform.

Ultima atualizacao: 2026-08-27 11:12 -03:00, Claude.

Executar UMA VEZ, por UMA pessoa do grupo. Os demais integrantes so precisam da secao 8.

---

## 1. Para que serve isso (explicacao simples)

O Terraform guarda um "caderno de anotacoes" chamado **estado** (`terraform.tfstate`). Nele fica o mapa de tudo que ele criou na AWS: ids de VPC, nome do cluster EKS, endpoints do RDS e, importante, **senhas em texto puro**.

Se esse caderno ficar no computador de uma pessoa:

- ninguem mais do grupo consegue rodar `terraform apply` sem conflito;
- se o notebook morrer, o Terraform "esquece" o que criou e a infra vira lixo orfao cobrando na fatura;
- se alguem commitar o arquivo por engano, as senhas do RDS vazam no GitHub.

Por isso o enunciado exige (O-09) que o estado fique num **bucket S3 remoto**, compartilhado pelo grupo, e que o `terraform.tfstate` nunca fique local.

## 2. Por que este bucket NAO e criado por Terraform

Problema do ovo e da galinha: o Terraform precisa do bucket para gravar o estado, mas o bucket seria criado pelo proprio Terraform - e onde ele gravaria o estado dessa criacao?

A solucao padrao chama-se **bootstrap**: cria-se o bucket uma unica vez fora do Terraform e documenta-se o procedimento. Isso nao contraria a frase-guia da fase ("se nao esta no codigo, nao existe"), porque o procedimento esta versionado neste arquivo. E a unica excecao documentada do projeto.

Quem quiser zero cliques, ver o Apendice A (criar com Terraform usando estado local e depois migrar).

## 3. Decisoes ja tomadas

| Item | Valor | Motivo |
|---|---|---|
| Regiao | `us-east-1` | Mesma regiao da Fase 2 (`services/analytics-service/README.md`) e a mais barata para EKS/RDS. |
| Nome do bucket | `togglemaster-tfstate-<sufixo>` | Nome de bucket e unico no mundo inteiro. O sufixo aleatorio evita colisao e nao expoe o numero da conta AWS num repo publico. |
| Versionamento | Ligado | Permite voltar um estado corrompido. Nao vem ligado por padrao. |
| Criptografia | SSE-S3 (`AES256`) | O estado tem senha em texto puro. SSE-S3 ja e padrao desde 2023; confirmamos mesmo assim. |
| Bloqueio publico | Todos os 4 ligados | Padrao desde 2023; confirmamos mesmo assim. |
| Lock de estado | `use_lockfile = true` | R-03 do enunciado. Lock nativo do S3, dispensa tabela DynamoDB. Exige **Terraform >= 1.11**. |

## 4. Pre-requisitos

1. Conta AWS pessoal (nao AWS Academy).
2. **MFA habilitado no usuario root** e root usado apenas para emergencia.
3. Um usuario IAM proprio para o dia a dia. Nao usar chaves do root: a AWS desaconselha e nao ha como limitar o estrago.
4. AWS CLI v2 instalado: `aws --version`.
5. Terraform >= 1.11 instalado: `terraform version`.

### 4.1 Criar o usuario IAM de trabalho (se ainda nao existir)

1. Console AWS -> **IAM** -> **Users** -> **Create user**.
2. Nome: `togglemaster-admin`.
3. Marque **Provide user access to the AWS Management Console** apenas se quiser login pelo navegador.
4. **Set permissions** -> **Attach policies directly** -> `AdministratorAccess`.
   - E permissao ampla, aceitavel para o bootstrap de uma conta de estudo. O menor privilegio real do projeto entra depois, nas roles criadas por Terraform (R-05 / S-06).
5. Criado o usuario, abra-o -> aba **Security credentials** -> **Create access key** -> caso de uso **Command Line Interface (CLI)**.
6. Guarde `Access key ID` e `Secret access key` num gerenciador de senhas. **Nunca** coloque esses valores em arquivo do repositorio.
7. Ative MFA tambem nesse usuario.

### 4.2 Configurar a CLI

```bash
aws configure --profile togglemaster
# AWS Access Key ID:     <cole aqui>
# AWS Secret Access Key: <cole aqui>
# Default region name:   us-east-1
# Default output format: json
```

Valide:

```bash
aws sts get-caller-identity --profile togglemaster
```

Deve responder com `Account`, `Arn` e `UserId`. Se der erro de credencial, refaca o passo 4.2.

---

## 5. Caminho A - criar pelo Console (recomendado para ver o que esta acontecendo)

### Passo 1 - Escolher o nome

O nome precisa ser unico no mundo inteiro. Gere um sufixo de 6 caracteres:

```bash
# Git Bash / Linux / macOS
openssl rand -hex 3
```

```powershell
# PowerShell
-join ((48..57) + (97..102) | Get-Random -Count 6 | ForEach-Object {[char]$_})
```

Resultado, por exemplo, `9f3c2a` -> nome final: `togglemaster-tfstate-9f3c2a`.

**Anote esse nome.** Ele sera escrito no bloco `backend` do Terraform e usado por todo o grupo.

### Passo 2 - Criar o bucket

1. Console AWS -> confira no canto superior direito se a regiao e **N. Virginia (us-east-1)**.
2. Servico **S3** -> **Create bucket**.
3. **Bucket type**: General purpose.
4. **Bucket name**: `togglemaster-tfstate-<seu-sufixo>`.
5. **Object Ownership**: `ACLs disabled (recommended)` - ja e o padrao.
6. **Block Public Access settings**: mantenha **Block all public access** marcado. Os quatro subitens ficam ligados.
7. **Bucket Versioning**: mude para **Enable**. Este e o unico item que **nao** vem correto por padrao.
8. **Default encryption**: `Server-side encryption with Amazon S3 managed keys (SSE-S3)`. Deixe **Bucket Key** habilitado.
9. **Create bucket**.

### Passo 3 - Exigir HTTPS (bucket policy)

Sem isso, o estado poderia trafegar sem TLS. E um achado classico de scanner de seguranca (S-03).

1. Abra o bucket -> aba **Permissions** -> **Bucket policy** -> **Edit**.
2. Cole o JSON abaixo trocando `SEU-BUCKET` pelo nome real, nos **dois** lugares:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyInsecureTransport",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::SEU-BUCKET",
        "arn:aws:s3:::SEU-BUCKET/*"
      ],
      "Condition": {
        "Bool": { "aws:SecureTransport": "false" }
      }
    }
  ]
}
```

3. **Save changes**.

### Passo 4 - Limpeza de versoes antigas (opcional, controla custo)

1. Aba **Management** -> **Create lifecycle rule**.
2. Nome: `expira-versoes-antigas`; escopo: **Apply to all objects in the bucket** (confirme o aviso).
3. Marque **Permanently delete noncurrent versions of objects** -> `90` dias.
4. **Create rule**.

---

## 6. Caminho B - criar pela CLI (mais rapido e reproduzivel)

### Bash (Git Bash, Linux, macOS)

```bash
export AWS_PROFILE=togglemaster
export AWS_REGION=us-east-1
export BUCKET="togglemaster-tfstate-$(openssl rand -hex 3)"
echo "Bucket: $BUCKET"   # ANOTE ESTE NOME

# 1) criar (us-east-1 nao usa LocationConstraint)
aws s3api create-bucket --bucket "$BUCKET" --region "$AWS_REGION"

# 2) versionamento
aws s3api put-bucket-versioning --bucket "$BUCKET" \
  --versioning-configuration Status=Enabled

# 3) criptografia em repouso
aws s3api put-bucket-encryption --bucket "$BUCKET" \
  --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"},"BucketKeyEnabled":true}]}'

# 4) bloqueio de acesso publico
aws s3api put-public-access-block --bucket "$BUCKET" \
  --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

# 5) exigir HTTPS
aws s3api put-bucket-policy --bucket "$BUCKET" --policy "$(cat <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [{
    "Sid": "DenyInsecureTransport",
    "Effect": "Deny",
    "Principal": "*",
    "Action": "s3:*",
    "Resource": ["arn:aws:s3:::$BUCKET", "arn:aws:s3:::$BUCKET/*"],
    "Condition": { "Bool": { "aws:SecureTransport": "false" } }
  }]
}
POLICY
)"
```

### PowerShell

```powershell
$env:AWS_PROFILE = "togglemaster"
$env:AWS_REGION  = "us-east-1"
$sufixo = -join ((48..57) + (97..102) | Get-Random -Count 6 | ForEach-Object {[char]$_})
$BUCKET = "togglemaster-tfstate-$sufixo"
$BUCKET   # ANOTE ESTE NOME

aws s3api create-bucket --bucket $BUCKET --region $env:AWS_REGION
aws s3api put-bucket-versioning --bucket $BUCKET --versioning-configuration Status=Enabled
aws s3api put-bucket-encryption --bucket $BUCKET --server-side-encryption-configuration '{\"Rules\":[{\"ApplyServerSideEncryptionByDefault\":{\"SSEAlgorithm\":\"AES256\"},\"BucketKeyEnabled\":true}]}'
aws s3api put-public-access-block --bucket $BUCKET --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

$policy = @"
{
  "Version": "2012-10-17",
  "Statement": [{
    "Sid": "DenyInsecureTransport",
    "Effect": "Deny",
    "Principal": "*",
    "Action": "s3:*",
    "Resource": ["arn:aws:s3:::$BUCKET", "arn:aws:s3:::$BUCKET/*"],
    "Condition": { "Bool": { "aws:SecureTransport": "false" } }
  }]
}
"@
$policy | Out-File -FilePath tls-only.json -Encoding utf8
aws s3api put-bucket-policy --bucket $BUCKET --policy file://tls-only.json
Remove-Item tls-only.json
```

> Se algum dia o grupo usar regiao diferente de `us-east-1`, o `create-bucket` precisa tambem de
> `--create-bucket-configuration LocationConstraint=<regiao>`.

---

## 7. Conferencia (vale como evidencia para o video, O-27)

```bash
export BUCKET=togglemaster-tfstate-<seu-sufixo>

aws s3api get-bucket-versioning   --bucket "$BUCKET"   # Status: Enabled
aws s3api get-bucket-encryption   --bucket "$BUCKET"   # SSEAlgorithm: AES256
aws s3api get-public-access-block --bucket "$BUCKET"   # os 4 campos true
aws s3api get-bucket-policy       --bucket "$BUCKET"   # DenyInsecureTransport
aws s3api get-bucket-location     --bucket "$BUCKET"   # null significa us-east-1
```

Checklist final:

- [ ] Bucket existe em `us-east-1`.
- [ ] Versionamento `Enabled`.
- [ ] Criptografia padrao `AES256`.
- [ ] Os 4 bloqueios de acesso publico em `true`.
- [ ] Bucket policy negando trafego sem TLS.
- [ ] Nome do bucket anotado na secao 8 e compartilhado com o grupo.

## 8. O que o resto do grupo precisa saber

- **Nome do bucket**: `togglemaster-tfstate-________` (preencher depois de criar).
- **Regiao**: `us-east-1`.
- Cada integrante cria o proprio usuario IAM (secao 4.1) e roda `aws configure --profile togglemaster`.
- Ninguem compartilha access key com ninguem. Chave e pessoal e nao vai para o repositorio.

## 9. Como isso entra no Terraform (proximo passo)

Assim que o bucket existir, o primeiro arquivo do projeto sera `terraform/backend.tf`:

```hcl
terraform {
  required_version = ">= 1.11.0"

  backend "s3" {
    bucket       = "togglemaster-tfstate-<seu-sufixo>"
    key          = "global/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
```

- `key` e o caminho do arquivo dentro do bucket. Se depois separarmos ambientes, viram `envs/dev/terraform.tfstate` e `envs/prod/terraform.tfstate` no mesmo bucket.
- `use_lockfile = true` cria um `terraform.tfstate.tflock` ao lado do estado durante o `apply`, impedindo que duas pessoas apliquem ao mesmo tempo. Atende R-03 e dispensa a tabela DynamoDB de lock, que esta depreciada.
- `encrypt = true` garante criptografia mesmo se o padrao do bucket mudar.

Depois disso, `terraform init` e o primeiro `terraform plan`.

## 10. Custo

Praticamente zero. O estado tem poucas centenas de KB; o S3 fica na casa de centavos de dolar por mes, mesmo com versionamento ligado. O que pesa na fatura e o EKS, os 3 RDS e o ElastiCache - ver S-09 sobre estrategia de `destroy` entre sessoes de trabalho.

## 11. Erros comuns

| Sintoma | Causa provavel | Correcao |
|---|---|---|
| `BucketAlreadyExists` | O nome ja existe em outra conta AWS do mundo | Gere outro sufixo. |
| `BucketAlreadyOwnedByYou` | Voce ja criou esse bucket | Pule para a secao 7 e apenas confira as configuracoes. |
| `IllegalLocationConstraintException` | Regiao da CLI diferente da do comando | Fixe `--region us-east-1` e confira `AWS_REGION`. |
| `AccessDenied` no `put-bucket-policy` | Usuario sem permissao de S3 | Confirme que o usuario IAM tem `AdministratorAccess`. |
| `Error acquiring the state lock` | Alguem esta aplicando, ou um apply travou | Espere; se travou de vez, `terraform force-unlock <ID>`, e so com certeza de que ninguem esta rodando. |
| Terraform reclama de `use_lockfile` | Versao anterior a 1.11 | Atualize o Terraform. |

---

## Apendice A - alternativa sem cliques (bootstrap por Terraform)

Para quem prefere que ate o bucket nasca de codigo:

1. Criar `terraform/bootstrap/main.tf` declarando `aws_s3_bucket`, `aws_s3_bucket_versioning`, `aws_s3_bucket_server_side_encryption_configuration`, `aws_s3_bucket_public_access_block` e `aws_s3_bucket_policy`, **sem** bloco `backend` (estado local).
2. `terraform init && terraform apply` - o bucket nasce e o estado fica local.
3. Adicionar o bloco `backend "s3"` apontando para o bucket recem-criado.
4. `terraform init -migrate-state` - o Terraform copia o estado local para o bucket.
5. Apagar o `terraform.tfstate` local. O `.gitignore` do repo ja impede o commit acidental.

Da mais trabalho e adiciona um passo de migracao, mas gera evidencia de IaC ainda mais forte para o video. A escolha e do grupo; o caminho principal deste documento continua sendo o recomendado.
