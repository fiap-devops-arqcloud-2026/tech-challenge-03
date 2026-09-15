# FIAP - Tech Challenge - Fase 3 - Grupo 203

> **Status em 2026-09-14:** relatório **preliminar**. Participantes, links do projeto, desafios/decisões e estimativa de custos estão documentados. O link do vídeo obrigatório ainda não foi localizado no projeto e permanece pendente. Não enviar este arquivo como versão final antes de concluir o checklist da seção 8.

## 1. Participantes

| Nome | RM | GitHub |
|---|---|---|
| Douglas Deveza dos Santos | RM373827 | [Douglasdeveza](https://github.com/Douglasdeveza) |
| Gabriel Pinelli Silva | RM373763 | [Tocaccelli](https://github.com/Tocaccelli) |
| João Carlos da Silva Brito | RM371738 | [Durmiand](https://github.com/Durmiand) |
| João Gabriel da Cruz Sales | RM372444 | [jgabrieldev1](https://github.com/jgabrieldev1) |
| João Vitor de Jesus Ciardullo | RM372155 | [joaociardullo](https://github.com/joaociardullo) |

> A relação foi conferida na entrega aprovada da Fase 2. A permanência dos cinco integrantes na Fase 3 deve ser confirmada pelo grupo antes do envio `[INCERTO]`.

## 2. Links da entrega

- **Repositório:** <https://github.com/fiap-devops-arqcloud-2026/tech-challenge-03>
- **Documentação principal:** <https://github.com/fiap-devops-arqcloud-2026/tech-challenge-03/blob/main/README.md>
- **Estimativa AWS:** <https://calculator.aws/#/estimate?id=1717508852ab38c3aefc4acf0aa7f3de4a797ff9>
- **Vídeo de demonstração:** **PENDENTE - inserir a URL final e testar o acesso sem login.**

Em 2026-09-14, o repositório estava privado. Antes da entrega, é necessário conceder acesso ao avaliador ou alterar a visibilidade conforme a orientação da FIAP.

## 3. Resumo do projeto

O ToggleMaster é uma plataforma de *feature flags* formada por cinco microsserviços: `auth`, `flag`, `targeting`, `evaluation` e `analytics`. Na Fase 3, a infraestrutura e o processo de publicação foram automatizados com Terraform, GitHub Actions, Amazon ECR, Kubernetes e ArgoCD.

O código de infraestrutura está dividido em três camadas: base AWS, cluster e objetos Kubernetes. Em 2026-09-11, as três camadas foram aplicadas e o grupo registrou EKS ativo, dois bancos RDS, Redis, PostgreSQL do targeting no EKS, PVC com EBS e ArgoCD em estado `Synced/Healthy`. Depois da validação, os recursos com custo e a base foram destruídos de forma controlada. Em 2026-09-14, os três estados Terraform estavam vazios e não havia EKS, RDS, Redis, ECR, EC2, NAT ou EBS ativo.

O bucket S3 usado como backend remoto é o único *bootstrap* criado fora do Terraform, porque precisa existir antes do primeiro `terraform init`. Esse procedimento está documentado em [`terraform/BOOTSTRAP-BACKEND-S3.md`](../terraform/BOOTSTRAP-BACKEND-S3.md).

## 4. Atendimento ao enunciado

| Bloco | Implementação e evidência | Situação |
|---|---|---|
| Infraestrutura como código | Terraform para rede, EKS, nós, bancos, Redis, DynamoDB, SQS, ECR e estado remoto. Pilha aplicada em 2026-09-11 e depois destruída para controlar custos. | Comprovado historicamente |
| Três bancos PostgreSQL | Dois bancos no RDS e o banco do targeting em StatefulSet PostgreSQL com EBS. É um desvio literal do enunciado, adotado segundo o registro D-015 da consulta ao professor em 2026-08-27. O comprovante original não foi localizado nesta revisão. | Parcial, com justificativa |
| CI e DevSecOps | Pipeline por microsserviço com build/testes disponíveis, lint, SAST, SCA, bloqueio crítico, build e scan da imagem, ECR e tag baseada no commit. | Comprovado |
| GitOps | Manifestos em `gitops/`, CI atualizando a tag e ArgoCD configurado com sincronização automática. Há registro histórico `Synced/Healthy`. | Comprovado; demonstração no vídeo pendente |
| Relatório | Participantes, links, desafios/decisões e captura de custos estão neste documento. | Atendido, exceto link do vídeo |
| Vídeo de até 20 minutos | Deve mostrar IaC, falha e correção de segurança, atualização da tag, sincronização automática e os cinco serviços no ArgoCD. | Pendente |

## 5. Principais desafios e decisões

1. **Limite de duas instâncias RDS.** A conta utilizada recusou a terceira instância. Foram mantidos dois bancos no RDS e o PostgreSQL do targeting no EKS com armazenamento persistente. A decisão segue o registro D-015; o comprovante primário da concordância do professor ainda deve ser anexado, se disponível.
2. **Controle de custos.** A infraestrutura foi separada em três estados Terraform para permitir ciclos controlados de criação e destruição. Após o ensaio de 2026-09-11, a AWS foi desmontada e revalidada em 2026-09-14.
3. **Credenciais fora do código.** O CI usou OIDC para autenticação temporária na AWS, os pods usaram IRSA e as senhas foram geradas pelo Terraform e mantidas no Secrets Manager. Nenhuma chave AWS foi versionada.
4. **Segurança como bloqueio real.** As esteiras executam lint, SAST, SCA e scan da imagem. Uma dependência crítica provocou falha e impediu os passos posteriores; depois da correção, a esteira passou.
5. **Inicialização do ArgoCD.** Como o tipo `Application` só existe depois da instalação do CRD, a camada Kubernetes foi aplicada em duas etapas: instalação do chart e, em seguida, criação da aplicação.

## 6. Evidências verificáveis

- **Falha de segurança e bloqueio dos passos posteriores:** [GitHub Actions 34596859079](https://github.com/fiap-devops-arqcloud-2026/tech-challenge-03/actions/runs/34596859079)
- **Correção e verificações aprovadas:** [GitHub Actions 34597106311](https://github.com/fiap-devops-arqcloud-2026/tech-challenge-03/actions/runs/34597106311)
- **Imagem publicada e tag GitOps atualizada:** [GitHub Actions 34367909857](https://github.com/fiap-devops-arqcloud-2026/tech-challenge-03/actions/runs/34367909857)
- **Integração local dos cinco serviços no conteúdo atual:** [GitHub Actions 34782394523](https://github.com/fiap-devops-arqcloud-2026/tech-challenge-03/actions/runs/34782394523)
- **Validação atual do Terraform:** [GitHub Actions 34667081714](https://github.com/fiap-devops-arqcloud-2026/tech-challenge-03/actions/runs/34667081714)

A última execução do `flag-service` em 2026-09-12 passou pelas verificações locais e falhou somente ao tentar assumir a identidade OIDC já removida no encerramento da AWS. Isso é coerente com o ambiente desmontado, mas não substitui uma nova demonstração do ciclo completo.

Não foi localizada uma captura durável do ArgoCD nem evidência preservada de que uma nova tag específica foi sincronizada no cluster. Essa parte deve aparecer no vídeo final.

## 7. Estimativa de custos AWS

Estimativa criada no AWS Pricing Calculator em **2026-09-11**, região **us-east-2 (Ohio)**, considerando 730 horas por mês:

| Serviço | Configuração | Custo mensal |
|---|---|---:|
| Amazon EKS | 1 cluster Kubernetes 1.34 | US$ 73,00 |
| Amazon EC2 | 2 instâncias `c7i-flex.large`, 20 GB cada | US$ 126,99 |
| Amazon RDS PostgreSQL | 2 instâncias `db.t3.micro`, Single-AZ, 20 GB gp3 | US$ 30,88 |
| Amazon ElastiCache | 1 Redis `cache.t3.micro` | US$ 12,41 |
| Amazon VPC | 1 NAT Gateway, 1 IPv4 e 1 GB processado | US$ 36,54 |
| Amazon EBS | 1 volume gp3 de 5 GB | US$ 0,40 |
| AWS Secrets Manager | 2 segredos e 1.000 chamadas/mês | US$ 0,81 |
| **Total mensal** | **730 horas** | **US$ 281,03** |
| **Total em 12 meses** | **sem desconto** | **US$ 3.372,36** |

![Captura da estimativa oficial](./evidencias/estimativa-custos-aws-2026-09-11.png)

O valor é uma estimativa, não uma fatura. O projeto reduz o gasto real mantendo o NAT desligado quando não é necessário e destruindo a infraestrutura após as sessões.

## 8. Checklist antes do envio

- [ ] Confirmar que os cinco participantes permanecem no grupo.
- [ ] Gravar ou localizar o vídeo de até 20 minutos com todas as cenas pedidas pela FIAP.
- [ ] Inserir a URL do vídeo neste relatório e no `README.md`.
- [ ] Demonstrar no vídeo uma nova tag sendo detectada e sincronizada pelo ArgoCD.
- [ ] Garantir acesso do avaliador ao repositório privado ou ajustar a visibilidade.
- [ ] Gerar o PDF final sem a palavra `PRELIMINAR` e testar todos os links.

---

**Base editorial:** relatório da Fase 2, entregue e aprovado. **Fonte dos requisitos:** `docs/POSTECH - Tech Challenge - Fase 3.pdf`, páginas 5 e 6. **Última revisão:** 2026-09-14, Codex.
