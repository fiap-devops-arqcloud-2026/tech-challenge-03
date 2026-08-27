# LOG_DE_TRABALHO

TL;DR: log append-only com entradas novas no topo.

Ultima atualizacao: 2026-08-27 11:12 -03:00, Claude.

## 2026-08-27 11:12 (-03:00) - Claude - Decisoes D-007/D-008 e bootstrap do backend S3

Feito: levantado o estado real do repo e detectado descompasso entre a documentacao (parada em 2026-07-30, afirmando "nenhuma implementacao iniciada") e a working tree de 2026-08-26, que ja continha os 5 microsservicos em `services/`, o `.gitignore`, os esqueletos `terraform/` e `gitops/` e a migracao de `00_COLAB_IA/` para `docs/00_COLAB_IA/`. O usuario confirmou que monorepo e Kustomize foram decisoes dele. Registradas D-007 e D-008; encerradas P-004 e P-005; criado `terraform/BOOTSTRAP-BACKEND-S3.md` com o passo a passo do bucket de estado; toda a documentacao de contexto foi realinhada.

Decisoes/Por que: D-007 fixa o codigo dos 5 microsservicos neste monorepo, porque sem codigo no repo os workflows de CI (O-10) nao teriam onde rodar. D-008 fixa Kustomize na area GitOps: o enunciado aceita YAML ou Helm (R-06), e Kustomize da overlays por ambiente e um `kustomize edit set image` limpo para o passo de CI que atualiza a tag (O-24), sem o peso de manter um chart. O bucket de estado sera criado fora do Terraform por bootstrap, unica excecao documentada a regra "se nao esta no codigo, nao existe", pelo problema do ovo e da galinha.

Arquivos: criado `terraform/BOOTSTRAP-BACKEND-S3.md`; atualizados `docs/00_COLAB_IA/DECISOES.md`, `PENDENCIAS_E_PROXIMOS_PASSOS.md`, `CHECKLIST_REQUISITOS_FASE3.md`, `DOSSIE_CONTEXTO.md`, `LEIA-PRIMEIRO.md`, `ORGANIZACAO_DE_PASTAS.md`, `LOG_DE_TRABALHO.md`, `CLAUDE.md` e `README.md`.

Descobertas: F-011 a F-013 registradas em PENDENCIAS. Varredura de segredos nos 5 servicos nao encontrou credencial, chave ou senha hardcoded; toda a configuracao vem de variaveis de ambiente, o que facilita ConfigMap/Secret no Kustomize. Os marcos M1 (2026-08-08) e M2 (2026-08-22) venceram sem serem concluidos; restam 19 dias ate a entrega e o cronograma foi rebaseado.

Estado p/ o proximo agente: documentacao alinhada ao disco e commitada. O bloqueio agora e operacional, nao de decisao: o usuario precisa executar `terraform/BOOTSTRAP-BACKEND-S3.md` e informar o nome do bucket (P-019). Com o bucket criado, iniciar `terraform/backend.tf` e a VPC (P-003). P-018 (nomes do grupo) continua aberta.

## 2026-07-30 15:38 (-03:00) - Claude - Condicoes de entrega confirmadas e projeto atualizado

Feito: o usuario confirmou que a entrega e em grupo e que o prazo final e 2026-09-15. Registrada a decisao D-006; encerradas P-016 e P-017; aberta P-018 (nomes dos integrantes). Adicionados ao checklist os marcos M1 a M5 ate a data de entrega. Propagada a informacao para `CLAUDE.md`, `README.md`, `DOSSIE_CONTEXTO.md`, `DECISOES.md`, `PENDENCIAS_E_PROXIMOS_PASSOS.md` e `CHECKLIST_REQUISITOS_FASE3.md`.

Decisoes/Por que: D-006 fixa modalidade e prazo, que ate entao eram [INCERTO]. Os marcos M1 a M5 sao proposta minha de cronograma, nao exigencia do enunciado, e foram marcados como tal para nao virarem regra por engano. O item O-36 continua aberto porque o enunciado exige os nomes no relatorio e eles ainda nao foram informados.

Arquivos: `00_COLAB_IA/CHECKLIST_REQUISITOS_FASE3.md`, `00_COLAB_IA/DECISOES.md`, `00_COLAB_IA/DOSSIE_CONTEXTO.md`, `00_COLAB_IA/PENDENCIAS_E_PROXIMOS_PASSOS.md`, `00_COLAB_IA/LOG_DE_TRABALHO.md`, `CLAUDE.md`, `README.md`.

Descobertas: com 2026-09-15 como limite restam cerca de 6 semanas e meia. P-004 (onde vive o codigo dos microsservicos) e P-005 (YAML/Kustomize/Helm) passam de "em espera" a bloqueio de cronograma, porque travam o marco M1.

Estado p/ o proximo agente: documentacao alinhada e publicada no branch `dev`. Nenhuma implementacao iniciada. Proximo passo: fechar P-004 e P-005 e entao atacar P-003 (arquitetura Terraform). Pedir ao usuario os nomes do grupo (P-018).

## 2026-07-30 15:21 (-03:00) - Claude - Checklist de requisitos da Fase 3

Feito: analisado o repositorio e a documentacao de contexto; lido integralmente o enunciado `docs/POSTECH - Tech Challenge - Fase 3.pdf`; inspecionado `tech-challenge-02/services/` para confirmar as linguagens dos 5 microsservicos; criado `00_COLAB_IA/CHECKLIST_REQUISITOS_FASE3.md` separando 39 itens obrigatorios (O-01 a O-39), 9 opcionais/recomendados pelo proprio enunciado (R-01 a R-09) e 9 sugestoes derivadas das aulas (S-01 a S-09).

Decisoes/Por que: nao foi tomada nenhuma decisao nova de arquitetura. O criterio de separacao foi literal ao PDF: obrigatorio e o que esta em "Requisitos Tecnicos" e "Entregaveis"; opcional e o que o PDF marca como "opcional", "recomendado", "preferencialmente", "se houver" ou oferece como alternativa. Sugestoes fora do PDF ficaram em secao propria para nao serem confundidas com exigencia.

Arquivos: criado `00_COLAB_IA/CHECKLIST_REQUISITOS_FASE3.md`; atualizados `00_COLAB_IA/LOG_DE_TRABALHO.md` e `00_COLAB_IA/PENDENCIAS_E_PROXIMOS_PASSOS.md`.

Descobertas: F-008, F-009 e F-010 registradas em PENDENCIAS. [INCERTO] se a entrega e individual ou em grupo (o relatorio pede "nomes dos participantes") e qual o prazo, que nao consta no PDF.

Estado p/ o proximo agente: checklist pronto e nenhuma implementacao iniciada. Antes de codar, resolver P-004 (onde vive o codigo dos microsservicos) e P-005 (YAML/Kustomize/Helm). Proximo passo natural e P-003 (desenho da arquitetura Terraform).

## 2026-07-18 12:46 (-03:00) - Codex - Estudos consolidados e publicados

Feito: validados os cinco guias HTML, seus 28 links locais e os 8 links do `README.md`; executada varredura por credenciais e arquivos sensiveis; criado o commit principal `200cdf5` (`docs: consolidate fase 3 study guides`) e realizado push com sucesso para `origin/dev`.

Decisoes/Por que: manter como historico as exclusoes dos guias Markdown rejeitados e publicar somente os cinco guias HTML vigentes. O `README.md`, `CLAUDE.md` e os arquivos de `00_COLAB_IA/` foram alinhados a D-005.

Arquivos: cinco guias `GUIA-ESTUDO-*.html`, `README.md`, `CLAUDE.md`, arquivos de contexto em `00_COLAB_IA/` e remocao de `docs/guias-de-estudo/fase-2/`.

Descobertas: todos os guias usam UTF-8 valido, nao possuem dados pessoais dos PDFs e apontam para materiais locais existentes. Nenhum padrao de credencial, `.env`, chave privada, kubeconfig ou `terraform.tfstate` foi encontrado.

Estado p/ o proximo agente: estudos da Fase 3 consolidados no branch `dev`. A implementacao permanece aguardando pedido explicito; proximas pendencias tecnicas sao P-003 a P-006.

## 2026-07-18 12:41 (-03:00) - Codex - Inicio da consolidacao dos estudos

Feito: iniciada a revisao integral das mudancas locais para atualizar projeto, contexto, Git e remoto conforme solicitacao do usuario.

Decisoes/Por que: preservar as exclusoes dos guias Markdown feitas pelo usuario; consolidar os cinco guias HTML, corrigir ponteiros desatualizados e validar o conjunto antes do commit.

Arquivos: revisados `CLAUDE.md`, `00_COLAB_IA/*`, estrutura de `docs/`, estado do branch `dev` e remoto `origin`.

Descobertas: `CLAUDE.md` e `00_COLAB_IA/ORGANIZACAO_DE_PASTAS.md` ainda apontavam para a estrutura antiga de guias Markdown; ambos precisam refletir D-005.

Estado p/ o proximo agente: concluir atualizacao dos ponteiros, validar guias e segredos, criar commit principal, fazer push e registrar o resultado.

## 2026-07-18 11:29 (-03:00) - Codex - Guia HTML do modulo Seguranca na Cloud

Feito: analisados os 5 PDFs de `docs/05_Seguranca na Cloud`; mapeadas as aulas de ameacas cloud, responsabilidade compartilhada, IAM/MFA/Zero Trust, criptografia/privacidade e CSPM/CWPP/CASB; criado guia HTML com explicacoes para leigos, 124 termos, exemplos e arquitetura de seguranca para o ToggleMaster.

Decisoes/Por que: mantido D-005. MFA, OIDC, menor privilegio, rede restrita, criptografia, segredos e auditoria foram tratados como controles essenciais. CSPM com Prowler foi classificado como muito util; CWPP com Falco como diferencial; CASB ficou fora do nucleo do projeto por atender principalmente governanca corporativa de SaaS.

Arquivos: criado `docs/05_Seguranca na Cloud/GUIA-ESTUDO-Seguranca-na-Cloud.html`; atualizados `00_COLAB_IA/LOG_DE_TRABALHO.md`, `00_COLAB_IA/PENDENCIAS_E_PROXIMOS_PASSOS.md` e `00_COLAB_IA/DOSSIE_CONTEXTO.md`.

Descobertas: F-007 confirma que o modulo possui 5 aulas e fecha a trilha de estudos da Fase 3. O guia passou por validacao estrutural, UTF-8, cinco links locais, cinco fichas de aula, 124 termos, responsividade em desktop/mobile e ausencia dos dados pessoais presentes nos PDFs.

Estado p/ o proximo agente: os cinco modulos da Fase 3 possuem guias HTML. Aguardar revisao do modulo 5 (P-015) e pedido explicito antes de iniciar implementacao (P-003 a P-006).

## 2026-07-18 11:18 (-03:00) - Codex - Inicio do estudo de Seguranca na Cloud

Feito: iniciada a analise dos 5 PDFs de `docs/05_Seguranca na Cloud`, conforme P-014.

Decisoes/Por que: mantido D-005; o guia sera criado em HTML dentro da pasta do modulo, seguindo o padrao didatico e visual dos modulos anteriores.

Arquivos: atualizado `00_COLAB_IA/LOG_DE_TRABALHO.md`.

Descobertas: a pasta contem 5 aulas. O conteudo detalhado ainda esta em analise.

Estado p/ o proximo agente: extrair e sintetizar as 5 aulas, criar o guia HTML, validar e concluir P-014. Nao iniciar implementacao.

## 2026-07-18 10:25 (-03:00) - Codex - Guia HTML do modulo DevSecOps

Feito: analisados os 7 PDFs de `docs/04_Seguranca em DevOps (DevSecOps)`; mapeadas as aulas de pipeline seguro, segredos, SAST/SCA, containers/IaC, DAST, gestao de vulnerabilidades e observabilidade; criado guia HTML com explicacoes para leigos, 109 termos, casos de uso e pipeline DevSecOps para o ToggleMaster.

Decisoes/Por que: mantido D-005. Gitleaks, SAST, SCA, scan de imagem e scan de IaC foram tratados como gates essenciais. DAST foi classificado como muito util; DefectDojo e dashboards como diferenciais de maturidade e evidencia.

Arquivos: criado `docs/04_Seguranca em DevOps (DevSecOps)/GUIA-ESTUDO-Seguranca-em-DevOps-DevSecOps.html`; atualizados `00_COLAB_IA/LOG_DE_TRABALHO.md`, `00_COLAB_IA/PENDENCIAS_E_PROXIMOS_PASSOS.md` e `00_COLAB_IA/DOSSIE_CONTEXTO.md`.

Descobertas: F-006 confirma que o modulo possui 7 aulas e cobre o ciclo completo, do commit e credenciais ate runtime, priorizacao de risco e auditoria. O guia passou por validacao de estrutura HTML, UTF-8, sete links locais, sete fichas de aula, CSS responsivo e ausencia dos dados pessoais presentes nos PDFs.

Estado p/ o proximo agente: aguardar revisao do guia do modulo 4 (P-013). Quando solicitado, continuar pelo modulo 5 no mesmo padrao (P-014). Nao iniciar implementacao.

## 2026-07-18 09:35 (-03:00) - Codex - Guia HTML do modulo Infraestrutura como Codigo

Feito: analisados os 8 PDFs de `docs/03_Infraestrutura como codigo`; mapeadas as aulas de fundamentos, state, modulos, automacao, Terragrunt, Kubernetes, seguranca e infraestrutura AWS completa; criado guia HTML com explicacoes para leigos, 80 termos, casos de uso e roteiro Terraform para o ToggleMaster.

Decisoes/Por que: mantido D-005. Terragrunt foi classificado como opcional para a primeira entrega. Para Kubernetes, o guia segue a abordagem hibrida do material: Terraform gerencia cluster e componentes fixos, enquanto ArgoCD gerencia aplicacoes dinamicas.

Arquivos: criado `docs/03_Infraestrutura como codigo/GUIA-ESTUDO-Infraestrutura-como-Codigo.html`; atualizados `00_COLAB_IA/LOG_DE_TRABALHO.md`, `00_COLAB_IA/PENDENCIAS_E_PROXIMOS_PASSOS.md` e `00_COLAB_IA/DOSSIE_CONTEXTO.md`.

Descobertas: F-005 confirma que o modulo possui 8 aulas e termina com um exercicio AWS muito proximo da entrega. O guia passou por validacao de estrutura HTML, UTF-8, oito links locais, oito fichas de aula, CSS responsivo e ausencia dos dados pessoais presentes nos PDFs.

Estado p/ o proximo agente: aguardar revisao do guia do modulo 3 (P-011). Quando solicitado, continuar pelo modulo 4 no mesmo padrao (P-012). Nao iniciar implementacao.

## 2026-07-18 09:16 (-03:00) - Codex - Guia HTML do modulo CI/CD

Feito: analisados os 7 PDFs de `docs/02_CI-CD`; mapeadas as aulas de fundamentos, otimizacao, Kubernetes, GitOps, Terraform, serverless e AIOps; criado guia HTML com explicacoes para leigos, 54 termos, exemplos, casos de uso e pipeline recomendado para o ToggleMaster.

Decisoes/Por que: mantido D-005. O guia foi salvo ao lado dos PDFs e segue o mesmo padrao visual e didatico do modulo 1. Serverless e AIOps foram classificados como complementares, pois o nucleo atual do desafio esta em EKS, GitOps e Terraform.

Arquivos: criado `docs/02_CI-CD/GUIA-ESTUDO-CI-CD.html`; atualizados `00_COLAB_IA/LOG_DE_TRABALHO.md`, `00_COLAB_IA/PENDENCIAS_E_PROXIMOS_PASSOS.md` e `00_COLAB_IA/DOSSIE_CONTEXTO.md`.

Descobertas: F-004 confirma que o modulo possui 7 aulas e progride de CI/CD basico ate automacao inteligente. O guia passou por validacao de estrutura HTML, UTF-8, sete links locais, sete fichas de aula e CSS responsivo. Nao houve validacao visual automatizada porque a abertura local por `file://` ja havia sido bloqueada pela politica do navegador.

Estado p/ o proximo agente: aguardar revisao do guia do modulo 2 (P-009). Quando solicitado, continuar pelo modulo 3 no mesmo padrao (P-010). Nao iniciar implementacao.

## 2026-07-18 08:44 (-03:00) - Codex - Guia HTML do modulo Welcome

Feito: relido o PDF do modulo `01_Welcome to Automacao e Seguranca na Cloud`; inspecionado como referencia o guia HTML de Introducao a Containers da Fase 2; criado um novo guia HTML no mesmo padrao, com explicacoes para leigos, glossario, casos de uso e exemplo aplicado ao ToggleMaster.

Decisoes/Por que: D-005 substitui a estrategia anterior de guias Markdown agrupados. O estudo agora sera feito modulo por modulo, com o guia HTML salvo ao lado do material correspondente.

Arquivos: criado `docs/01_Welcome to Automacao e Seguranca na Cloud/GUIA-ESTUDO-Automacao-e-Seguranca-na-Cloud.html`; atualizados os registros de handoff em `00_COLAB_IA/`.

Descobertas: F-003 confirma que o modulo Welcome e introdutorio, possui 4 paginas e organiza a Fase 3 em CI/CD, IaC, DevSecOps e Seguranca na Cloud. O guia foi validado quanto a estrutura HTML, UTF-8, link local, conteudo e regras CSS responsivas. A politica do navegador bloqueou a abertura direta de `file://`, portanto nao houve validacao visual automatizada.

Estado p/ o proximo agente: aguardar a revisao do usuario sobre o guia (P-007). So depois continuar para o modulo 2, seguindo o mesmo processo (P-008).

## 2026-07-17 16:31 (-03:00) - Codex - Guias de estudo da Fase 2 no repo da Fase 3

Feito: inventariados os materiais em `C:\Users\Gabriel Silva\Documents\GitHub\tech-challenge-02\docs\Material aulas`; analisados 6 modulos da Fase 2; criados guias de estudo em `docs/guias-de-estudo/fase-2/`; criada estrutura `00_COLAB_IA`; criado `CLAUDE.md`.

Decisoes/Por que: D-001 define o repo da Fase 3 como destino; D-002 separa guias por modulo; D-004 evita copiar PDFs da Fase 2 para nao duplicar insumos.

Arquivos: `CLAUDE.md`; `00_COLAB_IA/*`; `docs/guias-de-estudo/fase-2/**`; READMEs das pastas padrao do projeto.

Descobertas: F-001 a fonte da Fase 2 tem 6 modulos, 34 PDFs e guias HTML; F-002 a Fase 2 e a base conceitual para a automacao da Fase 3.

Estado p/ o proximo agente: guias prontos para revisao (P-001). Proximos passos recomendados: estudar DevSecOps/Seguranca na Cloud (P-002) e iniciar desenho Terraform/GitOps (P-003).
