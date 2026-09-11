"""
============================================================
GERADOR DO PDF DO RELATORIO DE ENTREGA - FASE 3
============================================================
Converte docs/fase-3/RELATORIO_DE_ENTREGA.md no PDF que vai ser
entregue, acrescentando uma capa no mesmo formato do relatorio da
Fase 2 - que foi aprovado com nota maxima.

COMO RODAR

    py scripts/gerar-relatorio-pdf.py

DEPENDENCIAS

    pip install markdown weasyprint

O weasyprint renderiza HTML + CSS de impressao em PDF. Foi escolhido
por ja estar disponivel na maquina e por aceitar CSS de paginacao
(@page), que e o que permite numerar paginas e evitar que uma tabela
seja cortada ao meio.

POR QUE GERAR DE UM MARKDOWN, E NAO ESCREVER O PDF DIRETO

O texto do relatorio vive em Markdown, versionado no Git. Assim o
conteudo entra em diff de Pull Request como qualquer outro arquivo, e
o PDF passa a ser um artefato reproduzivel: qualquer integrante roda
este script e obtem exatamente o mesmo documento.
============================================================
"""

import pathlib
import re

import markdown                       # converte Markdown em HTML
from weasyprint import HTML, CSS      # renderiza HTML em PDF

# ------------------------------------------------------------
# CAMINHOS
# ------------------------------------------------------------
# parents[1] sobe de scripts/ para a raiz do repositorio, entao o
# script funciona chamado de qualquer pasta.
RAIZ = pathlib.Path(__file__).resolve().parents[1]
PASTA = RAIZ / "docs" / "fase-3"
ORIGEM = PASTA / "RELATORIO_DE_ENTREGA.md"
DESTINO = PASTA / "Relatorio de Entrega - Tech Challenge Fase 3 - Grupo 203.pdf"

texto = ORIGEM.read_text(encoding="utf-8")

# ------------------------------------------------------------
# LIMPEZA DO QUE E NOTA INTERNA
# ------------------------------------------------------------
# O bloco de citacao do topo lembra ao grupo quais sao as exigencias do
# enunciado. E util no Markdown e ruido no documento entregue.
texto = re.sub(
    r"^> \*\*Exigências do enunciado.*?nota máxima\.\n",
    "",
    texto,
    flags=re.S | re.M,
)

# As primeiras linhas (titulo e metadados) viram a capa, entao saem do
# corpo. O corte e feito no primeiro cabecalho numerado.
linhas = texto.splitlines()
inicio = next(i for i, linha in enumerate(linhas) if linha.startswith("## 1."))
corpo_md = "\n".join(linhas[inicio:])

# tables -> habilita tabelas (o Markdown padrao nao as suporta)
# extra  -> listas aninhadas, blocos de codigo cercados, etc.
corpo_html = markdown.markdown(corpo_md, extensions=["tables", "extra"])

# ------------------------------------------------------------
# CAPA - mesmo formato do relatorio da Fase 2
# ------------------------------------------------------------
CAPA = """
<section class="capa">
  <p class="inst">FIAP — FACULDADE DE INFORMÁTICA E ADMINISTRAÇÃO PAULISTA</p>
  <p class="inst">PROGRAMA DE PÓS-GRADUAÇÃO EM DEVOPS &amp; ARQUITETURA CLOUD</p>

  <div class="capa-meio">
    <h1>TECH CHALLENGE — FASE 3</h1>
    <h2>AUTOMAÇÃO DE INFRAESTRUTURA E CICLO DE VIDA<br>COM IaC, CI/CD, DEVSECOPS E GITOPS — TOGGLEMASTER</h2>
  </div>

  <div class="capa-nomes">
    <p>GABRIEL PINELLI SILVA</p>
    <p>JOÃO VITOR DE JESUS CIARDULLO</p>
    <p>DOUGLAS DEVEZA DOS SANTOS</p>
    <p>JOÃO CARLOS DA SILVA BRITO</p>
    <p>JOÃO GABRIEL DA CRUZ SALES</p>
  </div>

  <p class="capa-rodape">Cuiabá — MT<br>2026</p>
</section>

<section class="corpo">
  <h1 class="titulo-corpo">Relatório de Entrega: Tech Challenge — Fase 3</h1>
  <p class="sub-corpo">
    <strong>Curso:</strong> Pós-Graduação em DevOps &amp; Arquitetura Cloud (FIAP)<br>
    <strong>Projeto:</strong> Automação de Infraestrutura e Ciclo de Vida — ToggleMaster<br>
    <strong>Grupo:</strong> 203
  </p>
"""

# ------------------------------------------------------------
# ESTILO DE IMPRESSAO
# ------------------------------------------------------------
ESTILO = """
@page {
  size: A4;
  margin: 2.2cm 2cm 2cm;
  /* Numero de pagina no rodape, centralizado. */
  @bottom-center {
    content: counter(page);
    font-family: Calibri, Carlito, sans-serif;
    font-size: 9pt;
    color: #777;
  }
}
/* A capa nao leva numero de pagina. */
@page :first { @bottom-center { content: ""; } }

body {
  font-family: Calibri, Carlito, "Segoe UI", sans-serif;
  font-size: 11pt;
  line-height: 1.5;
  color: #1a1a1a;
}

/* ---------- CAPA ---------- */
.capa {
  page-break-after: always;
  text-align: center;
  height: 24cm;
  display: flex;
  flex-direction: column;
}
.capa .inst { font-size: 11pt; font-weight: bold; margin: 0 0 2pt; letter-spacing: .2pt; }
.capa-meio { margin-top: 5.5cm; }
.capa h1 { font-size: 15pt; font-weight: bold; margin: 0 0 10pt; letter-spacing: .3pt; }
.capa h2 { font-size: 12.5pt; font-weight: bold; margin: 0; line-height: 1.45; }
.capa-nomes { margin-top: 4.5cm; }
.capa-nomes p { font-size: 11.5pt; margin: 0 0 3pt; }
.capa-rodape { margin-top: auto; font-size: 11pt; }

/* ---------- CORPO ---------- */
.titulo-corpo { font-size: 16pt; margin: 0 0 10pt; }
.sub-corpo { font-size: 10.5pt; margin: 0 0 18pt; color: #333; }

/* page-break-after: avoid impede titulo orfao no pe da pagina. */
h2 {
  font-size: 13pt; margin: 20pt 0 7pt;
  padding-bottom: 3pt; border-bottom: 1px solid #c8c8c8;
  page-break-after: avoid;
}
h3 { font-size: 11.5pt; margin: 14pt 0 5pt; page-break-after: avoid; }
p { margin: 0 0 8pt; text-align: justify; }
ul, ol { margin: 0 0 8pt; padding-left: 18pt; }
li { margin-bottom: 3pt; }

/* page-break-inside: avoid mantem a tabela inteira na mesma pagina. */
table {
  width: 100%; border-collapse: collapse;
  margin: 0 0 12pt; font-size: 9.5pt;
  page-break-inside: avoid;
}
th {
  background: #eceff2; text-align: left; font-weight: bold;
  padding: 5pt 7pt; border: 1px solid #c3c9d0;
}
td { padding: 5pt 7pt; border: 1px solid #d6dade; vertical-align: top; }

/* A captura da estimativa de custos (O-39) entra por aqui. */
img {
  max-width: 100%;
  border: 1px solid #c3c9d0;
  margin: 4pt 0 12pt;
  page-break-inside: avoid;
}

code {
  font-family: Consolas, "DejaVu Sans Mono", monospace;
  font-size: 9pt; background: #f1f3f5;
  padding: 0 2pt; border: 1px solid #e2e5e9;
}
pre { background: #f1f3f5; border: 1px solid #e2e5e9; padding: 7pt; font-size: 9pt; }
pre code { border: none; background: none; padding: 0; }

blockquote {
  margin: 0 0 10pt; padding: 7pt 11pt;
  border-left: 3px solid #9c6b16; background: #faf5ec;
  font-size: 10pt;
}
blockquote p { margin: 0; }

hr { border: none; border-top: 1px solid #dcdfe3; margin: 16pt 0; }
a { color: #1f4e79; word-break: break-all; }
strong { font-weight: bold; }
"""

html = CAPA + corpo_html + "</section>"

# base_url aponta para a pasta do Markdown: e isso que faz o caminho
# relativo da imagem (evidencias/...) ser resolvido corretamente.
HTML(string=html, base_url=str(PASTA)).write_pdf(
    str(DESTINO),
    stylesheets=[CSS(string=ESTILO)],
)

print("PDF gerado:", DESTINO)
print("tamanho:", f"{DESTINO.stat().st_size / 1024:.0f} KB")
