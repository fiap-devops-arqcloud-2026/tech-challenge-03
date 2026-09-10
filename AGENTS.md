# Instrucoes de trabalho dos agentes

TL;DR: trabalhar somente na branch dev; promover para main apenas por PR dev -> main e merge.
Ultima atualizacao: 2026-09-09 18:09 -03:00, Codex.
Fonte: instrucao explicita do usuario em 2026-09-09; D-020 em docs/00_COLAB_IA/DECISOES.md.

- Ler docs/00_COLAB_IA/LEIA-PRIMEIRO.md, topo de PENDENCIAS_E_PROXIMOS_PASSOS.md e LOG_DE_TRABALHO.md antes de trabalhar.
- Antes de editar, conferir git status e a branch atual. Usar dev, preservando alteracoes locais; nao criar commits nem fazer push direto na main.
- Promocao para main: validar dev, abrir PR dev -> main, revisar e fazer merge. Nao promover branches auxiliares diretamente para main sem nova instrucao do usuario.
- A regra de fluxo nao e, por si so, uma ordem para publicar ou fazer merge nesta sessao.
- Depois de um merge, conferir main/dev e sincronizar dev sem descartar trabalho.
- CI GitOps ainda possui pushes diretos na main; isso esta pendente de adaptacao em P-052. Nao afirmar que a politica ja esta imposta pela configuracao remota.
- A branch dev nao implica criar outro ambiente AWS: o ambiente de infraestrutura continua prod.
- Preservar fontes, segredos fora do Git e registros anteriores. Documentar trabalho e verificar antes de encerrar.

