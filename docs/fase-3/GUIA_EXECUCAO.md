# Guia de execucao

> **Reescrito em 2026-09-09.** A versao anterior deste arquivo era do
> plano inicial da fase e **nenhum dos comandos dela funcionava mais**:
> apontava para `terraform/bootstrap` e `terraform/environments/dev`
> (pastas removidas na consolidacao das tres camadas, D-017), mandava
> instalar o ArgoCD por `kubectl apply` de um manifesto remoto (hoje e
> Helm via Terraform, O-23) e - o ponto mais grave - mandava guardar
> `AWS_ACCESS_KEY_ID` e `AWS_SECRET_ACCESS_KEY` nos Secrets do GitHub.
> **O projeto nao usa chave estatica em lugar nenhum:** o CI autentica
> por OIDC (S-01). Seguir aquele guia criaria exatamente o risco que a
> Fase 3 pede para eliminar. O historico do Git preserva a versao
> original.

Este arquivo agora e so um indice. O passo a passo real vive em tres
documentos, cada um com um proposito diferente — manter um so texto por
assunto e o que evita que eles voltem a divergir:

| Voce quer... | Leia |
|---|---|
| Entender o projeto e subir a infraestrutura do zero | [`README.md`](../../README.md), secao **Como reproduzir** |
| Conduzir uma sessao completa: ligar o NAT, subir o cluster, criar as tabelas, semear os dados, gravar e derrubar | [`RUNBOOK-SESSAO.md`](../00_COLAB_IA/RUNBOOK-SESSAO.md) |
| Entender a divisao em tres camadas do Terraform e o custo de cada uma | [`terraform/README.md`](../../terraform/README.md) |
| Saber quais Secrets existem e quais valores precisam coincidir | [`gitops/SECRETS-CONTRATO.md`](../../gitops/SECRETS-CONTRATO.md) |
| Rodar os cinco servicos na sua maquina, sem AWS | [`TESTE_COMPOSE.md`](TESTE_COMPOSE.md) |

## O minimo para nao errar

Tres pontos que valem repetir aqui, porque sao os que mais custam caro
quando esquecidos:

1. **Nenhuma credencial da AWS vai para o GitHub.** A role
   `togglemaster-github-actions` confia no provedor OIDC do GitHub e so
   aceita token vindo deste repositorio. Nao ha o que vazar.
2. **A ordem das camadas nao e negociavel:** `terraform/` primeiro,
   depois `terraform/cluster/`, depois `terraform/k8s/` — esta ultima em
   dois comandos, por causa do CRD do ArgoCD (F-043). Cada camada le o
   estado da anterior; fora de ordem, o `plan` falha.
3. **O que custa dinheiro e a camada do meio.** Ao terminar, rode
   `terraform -chdir=terraform/cluster destroy` e **desligue o NAT
   Gateway** (passo 4.3 do runbook). O NAT sozinho e ~US$ 33/mes se
   ficar esquecido ligado.
