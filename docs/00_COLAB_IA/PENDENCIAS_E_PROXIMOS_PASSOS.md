# PENDENCIAS_E_PROXIMOS_PASSOS

TL;DR: nada técnico bloqueia a entrega. Seguem abertos a limpeza de duas sobras na AWS, o link do vídeo, a confirmação dos integrantes e ajustes de código adiados porque disparariam CI sem a role da AWS.

Última atualização: 2026-09-15 19:03 -03:00, Claude. O histórico até 2026-09-11 (P-001 a P-053, F-001 a F-051) está em [_ARQUIVO_MORTO/PENDENCIAS_E_PROXIMOS_PASSOS_2026-09-11.md](_ARQUIVO_MORTO/PENDENCIAS_E_PROXIMOS_PASSOS_2026-09-11.md). A numeração nova começa em P-100 para não colidir.

## Do usuário

| ID | Pendência | Dono | Por que não foi feita agora |
|---|---|---|---|
| P-100 | Excluir o bucket de estado `togglemaster-tfstate-891376952395-us-east-2-an` (remover todas as versões e depois o bucket) | usuário | Exclusão permanente; em 2026-09-15 foi bloqueada por permissão. Só fazer quando não houver mais recriação |
| P-101 | Excluir a VPC da Fase 2 que restou em us-east-2 | usuário | Bloqueada por permissão em 2026-09-15 |
| P-102 | Publicar o vídeo e trocar `PREENCHER_URL_DO_VIDEO` no `README.md` e no `docs/RELATORIO_DE_ENTREGA.md` | usuário | URL ainda não informada |
| P-103 | Confirmar a composição do Grupo 203 e retirar o `[INCERTO]` da linha 15 do relatório | usuário | O README não é confirmação independente (Revisões 1 e 2) |
| P-104 | Decidir sobre dados pessoais na pasta pública: nomes de usuário do Discord no relatório preliminar arquivado e o caminho `C:\Users\<nome completo>` em DECISOES D-001 | usuário | Editar arquivado é proibido; D-001 é histórico |
| P-105 | Opcional: limpar "generated using python-pptx" nas propriedades do `.pptx` | usuário | Metadado, não conteúdo; binário fora do escopo |

## Técnicas adiadas por gatilho de CI

Só com o ambiente e a role do CI existindo, porque o merge na `main` roda image e gitops.

| ID | Pendência | Onde | Por que não foi feita agora |
|---|---|---|---|
| P-110 | Comentários desatualizados: "git pull --rebase" (o job faz fetch e reset) e "única permissão de escrita" (jobs sem `permissions` herdam o teto do chamador) | `_ci-python.yml` e `_ci-go.yml` | `.github/workflows/**` dispara os pipelines |
| P-111 | Declarar `permissions` por job em build, lint, sast e sca | `_ci-python.yml` e `_ci-go.yml` | Idem |
| P-112 | Reescrever ou apagar os READMEs herdados da Fase 2 (Go 1.21, Python 3.9, us-east-1, chaves estáticas) | `services/*/README.md` | `services/**` dispara o pipeline do serviço |
| P-113 | Fixar versões de Flask, gunicorn e setuptools | `services/analytics-service/requirements.txt` | Idem |
| P-114 | Decidir se o `PyYAML==6.0.1` que sobrou da demonstração fica (o serviço não usa YAML) | `services/flag-service/requirements.txt` | Idem; também é pré-condição da demonstração |
| P-115 | Comentários que ainda citam ESO ou `externalsecret.yaml` | `gitops/base/*/deployment.yaml` (auth, evaluation, flag) | Não dispara CI, mas `gitops/base/**` ficou fora do escopo de D-024 |

## Código Terraform (fora do escopo da documentação)

| ID | Pendência | Onde | Por que não foi feita agora |
|---|---|---|---|
| P-120 | `enable_nat_gateway = false` no exemplo contradiz o padrão `true` e quebra uma recriação do zero | `terraform/terraform.tfvars.example` | Mudança de código proibida em D-024; o guia recomenda tfvars local |
| P-121 | Comentários sobre EKS 1.31, "repositório privado" e "evita o provider helm"; ordem das camadas sem a k8s | `cluster/main.tf`, `modules/eks/main.tf`, `k8s/variables.tf`, `k8s/argocd.tf`, `cluster/backend.tf` | Idem; D-024 só corrigiu comentários com link quebrado ou comando errado |
| P-122 | Comentário que cita `GUIA-AWS.md` da Fase 2 | `terraform/modules/messaging/main.tf` | Idem |
| P-123 | `ecr_image_tag_mutability = MUTABLE` | `terraform/variables.tf` | Decisão de código, não de documentação |
| P-124 | A exclusão `*.example.*` do verificador não cobre `.env.example` | `scripts/security-check.sh` | Script fora do escopo |

## Datas a vigiar

| ID | Data | O que acontece | O que fazer |
|---|---|---|---|
| P-130 | 2026-10-15 | Revisão marcada das 3 exceções do perl-base | Rodar o Trivy de novo na imagem e manter ou retirar do `.trivyignore` |
| P-131 | 2026-12-01 | EKS 1.34 sai do suporte padrão (control plane de US$ 0,10/h para US$ 0,60/h) | Numa recriação depois disso, conferir `aws eks describe-cluster-versions` e ajustar `kubernetes_version` |
| P-132 | cerca de 30 dias após cada run `[INCERTO]` | O GitHub deixa de aceitar `gh run rerun` dos runs de push na `main` | Usar o caminho padrão do guia (commit na `main` que toque os `_ci-*.yml` ou `services/<svc>/**`) |

## Não repetir

- Não recriar o provedor OIDC do GitHub nesta conta: `create_github_oidc_provider = false` (D-022).
- Não editar `services/**` nem `.github/workflows/**` para "só arrumar um comentário" sem a role existir.
- Não apagar o bucket de estado por um comando do assistente: é exclusão permanente e fica com o usuário.
