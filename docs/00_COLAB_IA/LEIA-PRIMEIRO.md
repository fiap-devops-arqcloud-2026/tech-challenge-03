# LEIA-PRIMEIRO

TL;DR: esta pasta é a memória de trabalho do projeto, usada por pessoas e assistentes de IA. Leia este arquivo antes de qualquer ação no repositório.

Última atualização: 2026-09-15 19:03 -03:00, Claude.

## Estado

Projeto entregue. O ambiente AWS foi recriado do zero, demonstrado e destruído em 2026-09-15. A documentação pública foi consolidada no mesmo dia. O que segue aberto está em [PENDENCIAS_E_PROXIMOS_PASSOS.md](PENDENCIAS_E_PROXIMOS_PASSOS.md).

## Ordem de leitura

1. [INSTRUCOES_ASSISTENTES.md](INSTRUCOES_ASSISTENTES.md): estado, regras permanentes, gatilhos de CI e mapa da documentação.
2. [PENDENCIAS_E_PROXIMOS_PASSOS.md](PENDENCIAS_E_PROXIMOS_PASSOS.md): o que falta e quem decide.
3. [DECISOES.md](DECISOES.md): decisões numeradas, a mais nova no topo (última: D-024).
4. Topo de [LOG_DE_TRABALHO.md](LOG_DE_TRABALHO.md): o que foi feito, a entrada mais nova primeiro.
5. [ORGANIZACAO_DE_PASTAS.md](ORGANIZACAO_DE_PASTAS.md): só quando for criar, mover ou arquivar arquivos.

## Documentos públicos centrais

| Documento | Responde |
|---|---|
| [README.md](../../README.md) | O quê e por quê: intuito, arquitetura, decisões, dificuldades, escopo, custo e integrantes |
| [docs/GUIA_DE_REPRODUCAO.md](../GUIA_DE_REPRODUCAO.md) | Como: comandos, tempos medidos, valores a trocar em outra conta e armadilhas |
| [docs/ARQUITETURA.md](../ARQUITETURA.md) | Referência técnica: serviços, recursos, pipeline, identidade e segredos |
| [docs/RELATORIO_DE_ENTREGA.md](../RELATORIO_DE_ENTREGA.md) | Relatório exigido pela FIAP (só se alinha, não se reescreve) |

Documento público nunca cita IA, assistentes, esta pasta nem códigos internos (D-0xx, P-0xx, F-0xx).

## Arquivo morto

[_ARQUIVO_MORTO/](_ARQUIVO_MORTO/) guarda versões substituídas, com a data no nome. O conteúdo arquivado é só leitura: não se edita, nem para consertar link quebrado. Para mudar algo, crie um documento novo fora dele e registre o de-para no LOG.

## Ritual de sessão

- Conferir data e hora antes de registrar fato temporal; todo número medido leva data.
- Conferir `git status --short` e a branch antes de editar; sincronizar a `dev` com a `main`.
- Se dois arquivos se contradizem, não sobrescrever: registrar `CONFLITO` e perguntar ao usuário.
- Ao terminar, atualizar LOG, PENDENCIAS e, se houver decisão nova, DECISOES.
