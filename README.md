# Tech Challenge 03 - ToggleMaster

Repositorio da terceira entrega do Tech Challenge da FIAP. O projeto continua o ToggleMaster construido na Fase 2 e sera evoluido com infraestrutura como codigo, CI/CD, DevSecOps e GitOps em uma conta AWS pessoal.

## Entrega

- Modalidade: trabalho em grupo.
- Prazo final: **2026-09-15**.
- Escopo item a item: [`docs/00_COLAB_IA/CHECKLIST_REQUISITOS_FASE3.md`](docs/00_COLAB_IA/CHECKLIST_REQUISITOS_FASE3.md).

## Estado atual

Em 2026-07-18, a etapa de estudos foi concluida. Os cinco modulos da Fase 3 possuem guias HTML para iniciantes, com glossario, exemplos e aplicacao no ToggleMaster.

Em 2026-07-30, o enunciado foi mapeado em um checklist com 39 requisitos obrigatorios, 9 itens que o proprio enunciado marca como opcionais ou recomendados e 9 sugestoes extras derivadas das aulas.

Em 2026-08-27, as decisoes estruturais foram fechadas: o projeto e um **monorepo**, com o codigo dos 5 microsservicos em `services/` (D-007), e a area GitOps usa **Kustomize** (D-008). O codigo da Fase 2 ja foi copiado; `terraform/`, `gitops/` e `.github/workflows/` ainda estao vazios.

O proximo passo e uma acao manual, feita uma unica vez: criar o bucket S3 que vai guardar o estado do Terraform, seguindo [`terraform/BOOTSTRAP-BACKEND-S3.md`](terraform/BOOTSTRAP-BACKEND-S3.md). Sem esse bucket nenhum `terraform init` funciona.

As pendencias e o cronograma estao em [`docs/00_COLAB_IA/PENDENCIAS_E_PROXIMOS_PASSOS.md`](docs/00_COLAB_IA/PENDENCIAS_E_PROXIMOS_PASSOS.md).

## Guias de estudo

| Modulo | Guia |
|---|---|
| 01 - Automacao e Seguranca na Cloud | [`GUIA-ESTUDO-Automacao-e-Seguranca-na-Cloud.html`](docs/01_Welcome%20to%20Automa%C3%A7%C3%A3o%20e%20Seguran%C3%A7a%20na%20Cloud/GUIA-ESTUDO-Automacao-e-Seguranca-na-Cloud.html) |
| 02 - CI/CD | [`GUIA-ESTUDO-CI-CD.html`](docs/02_CI-CD/GUIA-ESTUDO-CI-CD.html) |
| 03 - Infraestrutura como Codigo | [`GUIA-ESTUDO-Infraestrutura-como-Codigo.html`](docs/03_Infraestrutura%20como%20c%C3%B3digo/GUIA-ESTUDO-Infraestrutura-como-Codigo.html) |
| 04 - Seguranca em DevOps | [`GUIA-ESTUDO-Seguranca-em-DevOps-DevSecOps.html`](docs/04_Seguran%C3%A7a%20em%20DevOps%20%28DevSecOps%29/GUIA-ESTUDO-Seguranca-em-DevOps-DevSecOps.html) |
| 05 - Seguranca na Cloud | [`GUIA-ESTUDO-Seguranca-na-Cloud.html`](docs/05_Seguran%C3%A7a%20na%20Cloud/GUIA-ESTUDO-Seguranca-na-Cloud.html) |

## Direcao tecnica

- Terraform modular para VPC, EKS, bancos, cache, filas, ECR, IAM e backend remoto.
- GitHub Actions para testes, analises de seguranca e publicacao de imagens.
- Amazon ECR como registro de imagens Docker.
- ArgoCD e GitOps com Kustomize para reconciliar as aplicacoes no Amazon EKS.
- OIDC, menor privilegio, criptografia, protecao de segredos e auditoria como controles basicos.

Monorepo e Kustomize ja estao decididos (D-007 e D-008). As demais escolhas representam a direcao atual e serao detalhadas durante a implementacao.

## Organizacao

- `services/`: codigo dos 5 microsservicos, copiado da Fase 2.
- `terraform/`: infraestrutura como codigo (VPC, EKS, RDS, Redis, DynamoDB, SQS, ECR, IAM) e o bootstrap do backend de estado.
- `gitops/`: manifestos Kubernetes em Kustomize, monitorados pelo ArgoCD.
- `.github/workflows/`: pipelines de CI e DevSecOps dos 5 servicos.
- `docs/`: enunciado, materiais das aulas e guias HTML.
- `docs/00_COLAB_IA/`: contexto, decisoes, pendencias, checklist de requisitos e historico entre agentes.
- `docs/00_COLAB_IA/01_ENTRADAS/`: insumos de origem.
- `docs/00_COLAB_IA/02_TRABALHO/`: arquivos em desenvolvimento.
- `docs/00_COLAB_IA/03_ENTREGAVEIS/`: artefatos finais.
- `docs/00_COLAB_IA/04_REFERENCIAS/`: materiais de apoio.
- `docs/00_COLAB_IA/_ARQUIVO_MORTO/`: versoes obsoletas preservadas.

## Continuidade

Antes de trabalhar no repositorio, leia [`docs/00_COLAB_IA/LEIA-PRIMEIRO.md`](docs/00_COLAB_IA/LEIA-PRIMEIRO.md). O contexto consolidado esta em [`docs/00_COLAB_IA/DOSSIE_CONTEXTO.md`](docs/00_COLAB_IA/DOSSIE_CONTEXTO.md).

Nao versione credenciais AWS, arquivos `.env`, kubeconfigs sensiveis, senhas ou `terraform.tfstate`.
