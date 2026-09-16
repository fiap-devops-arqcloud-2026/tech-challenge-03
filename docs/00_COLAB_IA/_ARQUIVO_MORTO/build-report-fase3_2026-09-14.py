"""Gera o PDF preliminar de entrega do Tech Challenge FIAP - Fase 3.

Este e o gerador canonico desde 2026-09-14. A estrutura segue a entrega
aprovada da Fase 2 e acrescenta os dois itens pedidos na Fase 3: um resumo
dos desafios/decisoes e a captura do AWS Pricing Calculator.

Enquanto o video e a confirmacao final do grupo estiverem pendentes, o
arquivo de saida permanece identificado como PRELIMINAR. O texto editavel
equivalente fica em docs/RELATORIO_DE_ENTREGA.md.
"""

from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (
    Image,
    PageBreak,
    Paragraph,
    SimpleDocTemplate,
    Spacer,
    Table,
    TableStyle,
)


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "output" / "pdf" / "RELATORIO_ENTREGA_FIAP_FASE3_GRUPO203_2026-09-14_v01_PRELIMINAR.pdf"
COST_IMAGE = ROOT / "docs" / "evidencias" / "estimativa-custos-aws-2026-09-11.png"

TEAL_DARK = colors.HexColor("#07333A")
TEAL = colors.HexColor("#028090")
MINT = colors.HexColor("#02C39A")
PALE = colors.HexColor("#F4FBF9")
GRAY = colors.HexColor("#5D6870")
LIGHT_GRAY = colors.HexColor("#E7ECEF")
ORANGE = colors.HexColor("#D97706")
PALE_ORANGE = colors.HexColor("#FFF6E8")


def register_fonts() -> None:
    normal = Path(r"C:\Windows\Fonts\segoeui.ttf")
    bold = Path(r"C:\Windows\Fonts\segoeuib.ttf")
    italic = Path(r"C:\Windows\Fonts\segoeuii.ttf")
    if normal.exists() and bold.exists():
        pdfmetrics.registerFont(TTFont("SegoeUI", str(normal)))
        pdfmetrics.registerFont(TTFont("SegoeUI-Bold", str(bold)))
        if italic.exists():
            pdfmetrics.registerFont(TTFont("SegoeUI-Italic", str(italic)))
    else:
        raise FileNotFoundError("Fontes Segoe UI não encontradas em C:\\Windows\\Fonts")


def clean_text(text: str) -> str:
    """Troca travessoes tipograficos por hifens ASCII no PDF final."""

    return text.translate(str.maketrans({"–": "-", "—": "-", "‑": "-"}))


def paragraph(text: str, style: ParagraphStyle) -> Paragraph:
    return Paragraph(clean_text(text), style)


def table(data, widths, header=True, font_size=8.5, paddings=5):
    normalized = [
        [clean_text(cell) if isinstance(cell, str) else cell for cell in row]
        for row in data
    ]
    result = Table(normalized, colWidths=widths, repeatRows=1 if header else 0, hAlign="LEFT")
    commands = [
        ("FONTNAME", (0, 0), (-1, -1), "SegoeUI"),
        ("FONTSIZE", (0, 0), (-1, -1), font_size),
        ("TEXTCOLOR", (0, 0), (-1, -1), TEAL_DARK),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("LEFTPADDING", (0, 0), (-1, -1), paddings),
        ("RIGHTPADDING", (0, 0), (-1, -1), paddings),
        ("TOPPADDING", (0, 0), (-1, -1), paddings),
        ("BOTTOMPADDING", (0, 0), (-1, -1), paddings),
        ("GRID", (0, 0), (-1, -1), 0.35, colors.HexColor("#B9C7CB")),
        ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, PALE]),
    ]
    if header:
        commands.extend(
            [
                ("BACKGROUND", (0, 0), (-1, 0), TEAL_DARK),
                ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
                ("FONTNAME", (0, 0), (-1, 0), "SegoeUI-Bold"),
            ]
        )
    result.setStyle(TableStyle(commands))
    return result


def page_footer(canvas, doc):
    canvas.saveState()
    canvas.setTitle("FIAP - Tech Challenge - Fase 3 - Grupo 203")
    canvas.setAuthor("Grupo 203 - ToggleMaster")
    canvas.setSubject("Relatório preliminar de entrega do Tech Challenge da Fase 3")
    canvas.setCreator("Grupo 203")

    width, _ = A4
    canvas.setStrokeColor(MINT)
    canvas.setLineWidth(1.2)
    canvas.line(18 * mm, 15 * mm, width - 18 * mm, 15 * mm)
    canvas.setFont("SegoeUI", 7.5)
    canvas.setFillColor(GRAY)
    canvas.drawString(18 * mm, 9.5 * mm, "ToggleMaster | Grupo 203 | Relatório preliminar | 2026-09-14")
    canvas.drawRightString(width - 18 * mm, 9.5 * mm, f"Página {doc.page}")
    canvas.restoreState()


def build() -> None:
    register_fonts()
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    if not COST_IMAGE.exists():
        raise FileNotFoundError(f"Captura de custos não encontrada: {COST_IMAGE}")

    sample = getSampleStyleSheet()
    body = ParagraphStyle(
        "Body",
        parent=sample["BodyText"],
        fontName="SegoeUI",
        fontSize=9.2,
        leading=13.2,
        textColor=TEAL_DARK,
        spaceAfter=6,
    )
    small = ParagraphStyle(
        "Small",
        parent=body,
        fontSize=7.8,
        leading=10.4,
        textColor=GRAY,
    )
    h1 = ParagraphStyle(
        "H1",
        parent=sample["Heading1"],
        fontName="SegoeUI-Bold",
        fontSize=20,
        leading=24,
        textColor=TEAL_DARK,
        spaceAfter=9,
    )
    h2 = ParagraphStyle(
        "H2",
        parent=sample["Heading2"],
        fontName="SegoeUI-Bold",
        fontSize=12.5,
        leading=16,
        textColor=TEAL,
        spaceBefore=5,
        spaceAfter=6,
    )
    cover_title = ParagraphStyle(
        "CoverTitle",
        parent=h1,
        fontSize=31,
        leading=36,
        alignment=TA_LEFT,
        spaceAfter=10,
    )
    cover_subtitle = ParagraphStyle(
        "CoverSubtitle",
        parent=body,
        fontName="SegoeUI-Bold",
        fontSize=15,
        leading=20,
        textColor=TEAL,
    )
    badge = ParagraphStyle(
        "Badge",
        parent=body,
        fontName="SegoeUI-Bold",
        fontSize=9,
        leading=12,
        textColor=ORANGE,
        alignment=TA_CENTER,
    )
    link_style = ParagraphStyle(
        "Link",
        parent=body,
        fontSize=8.6,
        leading=12,
    )

    doc = SimpleDocTemplate(
        str(OUTPUT),
        pagesize=A4,
        rightMargin=18 * mm,
        leftMargin=18 * mm,
        topMargin=19 * mm,
        bottomMargin=21 * mm,
        title="FIAP - Tech Challenge - Fase 3 - Grupo 203",
        author="Grupo 203 - ToggleMaster",
        subject="Relatório preliminar de entrega",
    )

    story = []

    # Página 1 — capa.
    story.extend(
        [
            Spacer(1, 17 * mm),
            paragraph("FIAP | PÓS TECH", cover_subtitle),
            Spacer(1, 8 * mm),
            paragraph("Tech Challenge<br/>Fase 3", cover_title),
            paragraph("ToggleMaster", cover_subtitle),
            Spacer(1, 15 * mm),
            table(
                [[paragraph("RELATÓRIO PRELIMINAR", badge)]],
                [58 * mm],
                header=False,
                paddings=7,
            ),
            Spacer(1, 16 * mm),
            paragraph("Grupo 203", ParagraphStyle("Group", parent=h1, fontSize=18)),
            paragraph("Pós-graduação em DevOps e Arquitetura Cloud", body),
            paragraph("Revisado em 2026-09-14", body),
            Spacer(1, 18 * mm),
            Table(
                [[paragraph(
                    "<b>Antes do envio:</b> inserir o link do vídeo, confirmar os integrantes e garantir o acesso do avaliador ao repositório.",
                    body,
                )]],
                colWidths=[160 * mm],
                style=TableStyle(
                    [
                        ("BACKGROUND", (0, 0), (-1, -1), PALE_ORANGE),
                        ("BOX", (0, 0), (-1, -1), 0.9, ORANGE),
                        ("LEFTPADDING", (0, 0), (-1, -1), 10),
                        ("RIGHTPADDING", (0, 0), (-1, -1), 10),
                        ("TOPPADDING", (0, 0), (-1, -1), 9),
                        ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
                    ]
                ),
            ),
            Spacer(1, 20 * mm),
            paragraph(
                "Modelo editorial baseado no relatório aprovado da Fase 2, com o resumo de decisões e a captura obrigatória de custos acrescentados para a Fase 3.",
                small,
            ),
            PageBreak(),
        ]
    )

    # Página 2 — participantes, links e visão geral.
    story.extend([paragraph("Participantes e links", h1)])
    participants = [
        ["Nome", "RM", "GitHub"],
        ["Douglas Deveza dos Santos", "RM373827", "Douglasdeveza"],
        ["Gabriel Pinelli Silva", "RM373763", "Tocaccelli"],
        ["João Carlos da Silva Brito", "RM371738", "Durmiand"],
        ["João Gabriel da Cruz Sales", "RM372444", "jgabrieldev1"],
        ["João Vitor de Jesus Ciardullo", "RM372155", "joaociardullo"],
    ]
    story.extend(
        [
            table(participants, [88 * mm, 27 * mm, 52 * mm], font_size=8.5),
            paragraph("Lista conferida na entrega aprovada da Fase 2; confirmar se a composição do grupo permanece igual na Fase 3.", small),
            paragraph("Links da entrega", h2),
            paragraph(
                '<b>Repositório:</b> <link href="https://github.com/fiap-devops-arqcloud-2026/tech-challenge-03" color="#028090">github.com/fiap-devops-arqcloud-2026/tech-challenge-03</link>',
                link_style,
            ),
            paragraph(
                '<b>Documentação:</b> <link href="https://github.com/fiap-devops-arqcloud-2026/tech-challenge-03/blob/main/README.md" color="#028090">README na branch main</link>',
                link_style,
            ),
            paragraph(
                '<b>Estimativa AWS:</b> <link href="https://calculator.aws/#/estimate?id=1717508852ab38c3aefc4acf0aa7f3de4a797ff9" color="#028090">AWS Pricing Calculator</link>',
                link_style,
            ),
            paragraph('<b>Vídeo:</b> <font color="#D97706">PENDENTE — inserir a URL final e testar sem login.</font>', link_style),
            paragraph("Resumo da solução", h2),
            paragraph(
                "Na Fase 3, o ToggleMaster evoluiu da implantação manual para uma operação reproduzível. A infraestrutura foi definida em Terraform e separada em base AWS, cluster e objetos Kubernetes. Os cinco microsserviços possuem pipelines de integração e segurança; as imagens foram publicadas no Amazon ECR com tag derivada do commit.",
                body,
            ),
            paragraph(
                "Em 2026-09-11, as três camadas foram aplicadas: EKS, dois RDS, Redis, PostgreSQL do targeting, EBS e ArgoCD <b>Synced/Healthy</b> foram registrados. A AWS foi destruída depois do ensaio para controlar custos. Em 2026-09-14, não há infraestrutura ativa; a demonstração da nova tag no ArgoCD ainda precisa constar no vídeo.",
                body,
            ),
            Table(
                [[paragraph(
                    "<b>Acesso:</b> o repositório está privado em 2026-09-14. Conceder acesso ao avaliador ou ajustar a visibilidade antes do envio.",
                    small,
                )]],
                colWidths=[167 * mm],
                style=TableStyle(
                    [
                        ("BACKGROUND", (0, 0), (-1, -1), PALE_ORANGE),
                        ("BOX", (0, 0), (-1, -1), 0.6, ORANGE),
                        ("LEFTPADDING", (0, 0), (-1, -1), 7),
                        ("RIGHTPADDING", (0, 0), (-1, -1), 7),
                        ("TOPPADDING", (0, 0), (-1, -1), 6),
                        ("BOTTOMPADDING", (0, 0), (-1, -1), 3),
                    ]
                ),
            ),
            PageBreak(),
        ]
    )

    # Página 3 — desafios, decisões e evidências.
    story.extend([paragraph("Desafios, decisões e evidências", h1)])
    challenges = [
        ["Desafio", "Decisão tomada"],
        [
            paragraph("Limite de duas instâncias RDS", body),
            paragraph("Dois bancos no RDS e o targeting em StatefulSet PostgreSQL com EBS. Desvio literal adotado conforme registro D-015 de 2026-08-27; anexar o comprovante do professor se disponível.", small),
        ],
        [
            paragraph("Evitar custos fora das sessões", body),
            paragraph("Terraform em três camadas para controlar a criação e a destruição. Após o ensaio, todas as camadas foram destruídas e o backend S3 foi preservado.", small),
        ],
        [
            paragraph("Credenciais fora do código", body),
            paragraph("OIDC no CI, IRSA nos pods e senhas geradas pelo Terraform no Secrets Manager. Nenhuma chave AWS é versionada.", small),
        ],
        [
            paragraph("Vulnerabilidade crítica", body),
            paragraph("Build, lint, SAST, SCA e scan da imagem funcionam como portões. Falha crítica impede a publicação; exceções ficam nominais e justificadas.", small),
        ],
        [
            paragraph("CRD do ArgoCD no primeiro apply", body),
            paragraph("Bootstrap em duas etapas: instalar o chart e o CRD, depois criar a Application que gerencia os cinco serviços.", small),
        ],
    ]
    story.extend([table(challenges, [48 * mm, 119 * mm], font_size=8.1, paddings=4), Spacer(1, 3 * mm)])

    story.append(paragraph("Estado das evidências em 2026-09-14", h2))
    evidence = [
        ["Situação", "Evidência"],
        ["Histórico", "Pilha completa aplicada em 2026-09-11; EKS, RDS, Redis, EBS e ArgoCD observados"],
        ["Comprovado", "Pipeline bloqueou vulnerabilidade crítica e passou após a correção"],
        ["Comprovado", "Pipeline publicou imagem e atualizou a tag nos manifestos GitOps"],
        ["Atual", "AWS desmontada e três estados Terraform vazios em 2026-09-14"],
        ["Pendente", "Vídeo mostrando nova tag sincronizada e cinco serviços no ArgoCD"],
        ["Pendente", "Confirmação do grupo e acesso do avaliador ao repositório privado"],
    ]
    evidence_table = table(evidence, [30 * mm, 137 * mm], font_size=7.7, paddings=3.4)
    evidence_table.setStyle(
        TableStyle(
            [
                ("TEXTCOLOR", (0, 1), (0, 4), colors.HexColor("#087F5B")),
                ("FONTNAME", (0, 1), (0, -1), "SegoeUI-Bold"),
                ("TEXTCOLOR", (0, 5), (0, -1), ORANGE),
            ]
        )
    )
    story.extend(
        [
            evidence_table,
            Spacer(1, 4 * mm),
            paragraph(
                '<b>Evidências:</b> <link href="https://github.com/fiap-devops-arqcloud-2026/tech-challenge-03/actions/runs/34596859079" color="#028090">falha de segurança</link> | <link href="https://github.com/fiap-devops-arqcloud-2026/tech-challenge-03/actions/runs/34597106311" color="#028090">execução corrigida</link> | <link href="https://github.com/fiap-devops-arqcloud-2026/tech-challenge-03/actions/runs/34367909857" color="#028090">publicação e tag GitOps</link>',
                small,
            ),
            PageBreak(),
        ]
    )

    # Página 4 — estimativa de custos e captura oficial.
    story.extend([paragraph("Estimativa de custos AWS", h1)])
    story.append(
        paragraph(
            "Estimativa criada no AWS Pricing Calculator em <b>2026-09-11</b>, na região <b>us-east-2 (Ohio)</b>, usando 730 horas por mês para o cenário conservador em que toda a infraestrutura permanece ligada.",
            body,
        )
    )
    costs = [
        ["Serviço", "Configuração", "Mensal"],
        ["EKS", "1 cluster Kubernetes 1.34", "US$ 73,00"],
        ["EC2", "2 × c7i-flex.large, 20 GB cada", "US$ 126,99"],
        ["RDS PostgreSQL", "2 × db.t3.micro, Single-AZ, 20 GB gp3", "US$ 30,88"],
        ["ElastiCache", "1 × Redis cache.t3.micro", "US$ 12,41"],
        ["VPC", "1 NAT Gateway, 1 IPv4 e 1 GB processado", "US$ 36,54"],
        ["EBS", "1 volume gp3 de 5 GB", "US$ 0,40"],
        ["Secrets Manager", "2 segredos e 1.000 chamadas/mês", "US$ 0,81"],
        ["TOTAL", "730 horas por mês", "US$ 281,03"],
    ]
    costs_table = table(costs, [39 * mm, 91 * mm, 37 * mm], font_size=7.4, paddings=3)
    costs_table.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, -1), (-1, -1), colors.HexColor("#D8F3EC")),
                ("FONTNAME", (0, -1), (-1, -1), "SegoeUI-Bold"),
                ("TEXTCOLOR", (0, -1), (-1, -1), TEAL_DARK),
            ]
        )
    )
    story.extend([costs_table, Spacer(1, 4 * mm)])

    img = Image(str(COST_IMAGE))
    img.drawWidth = 167 * mm
    img.drawHeight = img.drawWidth * 1300 / 2100
    story.extend(
        [
            img,
            Spacer(1, 2 * mm),
            paragraph(
                'Captura oficial. Estimativa pública: <link href="https://calculator.aws/#/estimate?id=1717508852ab38c3aefc4acf0aa7f3de4a797ff9" color="#028090">abrir no AWS Pricing Calculator</link>.',
                small,
            ),
            paragraph(
            "O total de 12 meses é <b>US$ 3.372,36</b>. É uma estimativa, não uma fatura. S3, ECR, SQS, DynamoDB e transferência variam com o uso. O projeto reduz o gasto real mantendo o NAT desligado quando possível e destruindo o ambiente após as sessões.",
                small,
            ),
        ]
    )

    doc.build(story, onFirstPage=page_footer, onLaterPages=page_footer)
    print(OUTPUT)


if __name__ == "__main__":
    build()
