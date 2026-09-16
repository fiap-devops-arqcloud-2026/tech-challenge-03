# FIAP - Tech Challenge - Fase 3 - Grupo 203

> **Status em 2026-09-15:** versão entregue; revisada em 2026-09-15. Participantes, links do projeto, desafios/decisões, evidências e estimativa de custos estão documentados. O link do vídeo entra no lugar do marcador `PREENCHER_URL_DO_VIDEO`.

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
- **Vídeo de demonstração:** PREENCHER_URL_DO_VIDEO

O repositório é público, então o avaliador não depende de acesso concedido pelo grupo.

## 3. Resumo do projeto

O ToggleMaster é uma plataforma de *feature flags* formada por cinco microsserviços: `auth`, `flag`, `targeting`, `evaluation` e `analytics`. Na Fase 3, a infraestrutura e o processo de publicação foram automatizados com Terraform, GitHub Actions, Amazon ECR, Kubernetes e ArgoCD.

O código de infraestrutura está dividido em três camadas: base AWS, cluster e objetos Kubernetes. Em 2026-09-11, as três camadas foram aplicadas e o grupo registrou EKS ativo, dois bancos RDS, Redis, PostgreSQL do targeting no EKS, PVC com EBS e ArgoCD em estado `Synced/Healthy`. Depois da validação, os recursos com custo e a base foram destruídos de forma controlada. Em 2026-09-15, o ambiente foi recriado do zero pelas três camadas, demonstrado no vídeo e destruído de novo na ordem inversa: camada k8s com 13 recursos (1m04s), camada cluster com 35 recursos e base com 35 recursos (1m40s).

O bucket S3 usado como backend remoto é o único *bootstrap* criado fora do Terraform, porque precisa existir antes do primeiro `terraform init`. Esse procedimento está documentado em [`docs/GUIA_DE_REPRODUCAO.md`](GUIA_DE_REPRODUCAO.md#3-bucket-de-estado-do-terraform).

## 4. Atendimento ao enunciado

| Bloco | Implementação e evidência | Situação |
|---|---|---|
| Infraestrutura como código | Terraform para rede, EKS, nós, bancos, Redis, DynamoDB, SQS, ECR e estado remoto. Pilha aplicada em 2026-09-11 e destruída para controlar custos; recriada do zero e destruída de novo em 2026-09-15. | Comprovado (2026-09-11 e 2026-09-15) |
| Três bancos PostgreSQL | Dois bancos no RDS e o banco do targeting em StatefulSet PostgreSQL com EBS. É um desvio literal do enunciado, combinado com o professor em 2026-08-27; comprovante escrito não localizado. | Parcial, com justificativa |
| CI e DevSecOps | Pipeline por microsserviço com build/testes disponíveis, lint, SAST, SCA, bloqueio crítico, build e scan da imagem, ECR e tag baseada no commit. | Comprovado |
| GitOps | Manifestos em `gitops/`, CI atualizando a tag e ArgoCD com sincronização automática. Em 2026-09-15: PR #16 → run 34997028995 → commit do robô a0c7b8e (flag-service `v1.0.0-a509d67`) → sincronização automática e prova de selfHeal; sem captura de tela no repositório. | Comprovado (2026-09-15) |
| Relatório | Participantes, links, desafios/decisões e captura de custos estão neste documento. | Atendido; o link do vídeo entra no marcador |
| Vídeo de até 20 minutos | Mostra IaC, falha e correção de segurança, atualização da tag, sincronização automática e os cinco serviços no ArgoCD. Gravado em 2026-09-15. | Gravado; link em `PREENCHER_URL_DO_VIDEO` |

## 5. Principais desafios e decisões

1. **Limite de duas instâncias RDS.** A conta utilizada recusou a terceira instância. Foram mantidos dois bancos no RDS e o PostgreSQL do targeting no EKS com armazenamento persistente. A decisão foi combinada com o professor em 2026-08-27; comprovante escrito não localizado.
2. **Controle de custos.** A infraestrutura foi separada em três estados Terraform para permitir ciclos controlados de criação e destruição. Após o ensaio de 2026-09-11, a AWS foi desmontada. Em 2026-09-15, o ambiente foi recriado do zero e destruído de novo (camada k8s com 13 recursos em 1m04s; cluster com 35 recursos; base com 35 recursos em 1m40s).
3. **Credenciais fora do código.** O CI usou OIDC para autenticação temporária na AWS, os pods usaram IRSA e as senhas foram geradas pelo Terraform (as dos bancos RDS também ficam no Secrets Manager). Nenhuma chave AWS foi versionada.
4. **Segurança como bloqueio real.** As esteiras executam lint, SAST, SCA e scan da imagem. Uma dependência crítica provocou falha e impediu os passos posteriores; depois da correção, a esteira passou. A demonstração foi feita em 2026-09-11 e repetida em 2026-09-15: a `PyYAML==5.3.1` fez o SCA falhar com `CVE-2020-14343` CRITICAL ([run 34985289399](https://github.com/fiap-devops-arqcloud-2026/tech-challenge-03/actions/runs/34985289399)) e a troca para 6.0.1 deixou as verificações verdes ([run 34985477955](https://github.com/fiap-devops-arqcloud-2026/tech-challenge-03/actions/runs/34985477955)).
5. **Inicialização do ArgoCD.** Como o tipo `Application` só existe depois da instalação do CRD, a camada Kubernetes foi aplicada em duas etapas: instalação do chart e, em seguida, criação da aplicação.

## 6. Evidências verificáveis

- **Falha de segurança e bloqueio dos passos posteriores (2026-09-11):** [GitHub Actions 34596859079](https://github.com/fiap-devops-arqcloud-2026/tech-challenge-03/actions/runs/34596859079)
- **Correção e verificações aprovadas (2026-09-11):** [GitHub Actions 34597106311](https://github.com/fiap-devops-arqcloud-2026/tech-challenge-03/actions/runs/34597106311)
- **Falha de segurança na demonstração de 2026-09-15:** [GitHub Actions 34985289399](https://github.com/fiap-devops-arqcloud-2026/tech-challenge-03/actions/runs/34985289399)
- **Correção na demonstração de 2026-09-15:** [GitHub Actions 34985477955](https://github.com/fiap-devops-arqcloud-2026/tech-challenge-03/actions/runs/34985477955)
- **Imagem publicada e tag GitOps atualizada (2026-09-09):** [GitHub Actions 34367909857](https://github.com/fiap-devops-arqcloud-2026/tech-challenge-03/actions/runs/34367909857)
- **Imagem publicada e tag GitOps atualizada no merge do PR #16 (2026-09-15):** [PR #16](https://github.com/fiap-devops-arqcloud-2026/tech-challenge-03/pull/16), [GitHub Actions 34997028995](https://github.com/fiap-devops-arqcloud-2026/tech-challenge-03/actions/runs/34997028995) e [commit do robô a0c7b8e](https://github.com/fiap-devops-arqcloud-2026/tech-challenge-03/commit/a0c7b8e06f9e12da5bc838d64ead841e1f91072f)
- **Integração local dos cinco serviços no merge do PR #16 (2026-09-15):** [GitHub Actions 34997028499](https://github.com/fiap-devops-arqcloud-2026/tech-challenge-03/actions/runs/34997028499)
- **Validação do Terraform no merge do PR #16 (2026-09-15):** [GitHub Actions 34997028451](https://github.com/fiap-devops-arqcloud-2026/tech-challenge-03/actions/runs/34997028451)

Em 2026-09-15, o merge do PR #16 na `main` executou o pipeline completo do `flag-service` (run 34997028995): verificações, build e scan da imagem, push no ECR com a tag `v1.0.0-a509d67` e commit do robô a0c7b8e no overlay GitOps.

O ArgoCD sincronizou essa tag sozinho e desfez um `kubectl scale` manual (selfHeal) na mesma sessão. Essa parte aparece no vídeo; não há captura de tela no repositório.

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
- [x] Gravar o vídeo de até 20 minutos com todas as cenas pedidas pela FIAP (gravado em 2026-09-15).
- [ ] Inserir a URL do vídeo neste relatório e no `README.md` (marcador `PREENCHER_URL_DO_VIDEO`).
- [x] Demonstrar no vídeo uma nova tag sendo detectada e sincronizada pelo ArgoCD (commit a0c7b8e, 2026-09-15).
- [x] Garantir acesso do avaliador ao repositório (repositório público).

---

**Base editorial:** relatório da Fase 2, entregue e aprovado. **Fonte dos requisitos:** `docs/POSTECH - Tech Challenge - Fase 3.pdf`, páginas 5 e 6. **Última revisão:** 2026-09-15.
