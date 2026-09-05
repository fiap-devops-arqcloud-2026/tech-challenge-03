# Teste integrado dos cinco serviços

O workflow **Compose Integration** constrói e inicia o Docker Compose em um runner
Linux do GitHub Actions. Também pode ser executado em Linux/WSL com Docker Compose
v2 e Python 3:

```bash
bash scripts/test-compose.sh
```

O teste usa `.env.example`, portas 8000–8005, 5433, 5434 e 6379, e o projeto
separado `tc03-integration`. Execute em um ambiente de teste com essas portas livres.
Não são necessárias credenciais reais nem uma sessão AWS Academy.

O arquivo `docker-compose.integration.yaml` acrescenta o Moto, simulador local de
SQS e DynamoDB. Um container inicializador cria a fila e a tabela antes das
aplicações. Os endpoints alternativos são opcionais no código; sem eles os SDKs
continuam usando os endpoints normais da AWS.

O teste confirma:

- Health dos cinco serviços.
- Rejeição de credenciais inválidas e criação/validação de uma chave local.
- Persistência de flags e regras nos bancos PostgreSQL.
- Avaliação de flags ligadas, desligadas, inexistentes e regras de 0%/100%.
- Cache Redis com TTL e atualização da decisão após a expiração.
- Publicação dos eventos pelo evaluation, consumo pelo analytics, gravação no
  DynamoDB simulado e remoção das mensagens da fila.

A chave local gerada é entregue ao container de evaluation apenas por variável de
ambiente; não é impressa nem gravada em arquivo. O Compose padrão continua com SQS
desativado. Seu script de inicialização agora cria os dois bancos da aplicação e
carrega os schemas, em volumes novos.

O workflow remove automaticamente seus containers e volumes de teste. Em execução
manual, para encerrar e descartar **somente os dados desse projeto de teste**:

```bash
docker compose --env-file .env.example -p tc03-integration \
  -f docker-compose.yaml -f docker-compose.integration.yaml down -v
```

Essa validação cobre a integração local. IAM, EKS, ECR, rede e comportamento dos
serviços reais da AWS precisam de validação posterior no Academy.
