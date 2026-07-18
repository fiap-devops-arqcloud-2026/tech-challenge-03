# Tech Challenge 03 - ToggleMaster

Repositorio da terceira entrega do Tech Challenge da FIAP. O projeto continua o ToggleMaster construido na Fase 2 e sera evoluido com infraestrutura como codigo, CI/CD, DevSecOps e GitOps em uma conta AWS pessoal.

## Estado atual

Em 2026-07-18, a etapa de estudos foi concluida. Os cinco modulos da Fase 3 possuem guias HTML para iniciantes, com glossario, exemplos e aplicacao no ToggleMaster.

A implementacao ainda nao foi iniciada. As proximas decisoes estao registradas em [`00_COLAB_IA/PENDENCIAS_E_PROXIMOS_PASSOS.md`](00_COLAB_IA/PENDENCIAS_E_PROXIMOS_PASSOS.md).

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
- ArgoCD e GitOps para reconciliar as aplicacoes no Amazon EKS.
- OIDC, menor privilegio, criptografia, protecao de segredos e auditoria como controles basicos.

Essas escolhas representam a direcao atual e ainda serao detalhadas durante a implementacao.

## Organizacao

- `docs/`: enunciado, materiais das aulas e guias HTML.
- `00_COLAB_IA/`: contexto, decisoes, pendencias e historico entre agentes.
- `01_ENTRADAS/`: insumos de origem.
- `02_TRABALHO/`: arquivos em desenvolvimento.
- `03_ENTREGAVEIS/`: artefatos finais.
- `04_REFERENCIAS/`: materiais de apoio.
- `_ARQUIVO_MORTO/`: versoes obsoletas preservadas.

## Continuidade

Antes de trabalhar no repositorio, leia [`00_COLAB_IA/LEIA-PRIMEIRO.md`](00_COLAB_IA/LEIA-PRIMEIRO.md). O contexto consolidado esta em [`00_COLAB_IA/DOSSIE_CONTEXTO.md`](00_COLAB_IA/DOSSIE_CONTEXTO.md).

Nao versione credenciais AWS, arquivos `.env`, kubeconfigs sensiveis, senhas ou `terraform.tfstate`.
