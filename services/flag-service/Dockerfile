# -------------------------
# STAGE 1: builder
# Objetivo: compilar/baixar dependências e gerar "wheels" (pacotes .whl)
# para instalar depois no runtime sem precisar de compiladores.
# -------------------------
FROM python:3.12-slim AS builder

# Essas variáveis melhoram comportamento padrão em container:
# - PYTHONDONTWRITEBYTECODE=1: não cria .pyc (menos lixo)
# - PYTHONUNBUFFERED=1: logs saem "ao vivo" no stdout (bom para docker logs)
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Diretório de trabalho dentro do container (tudo roda a partir daqui)
WORKDIR /build

# Instala dependências de sistema necessárias para COMPILAR algumas libs Python
# (ex.: libs com extensões em C) e para libs de Postgres (libpq-dev).
# - build-essential/gcc: compiladores
# - libpq-dev: headers para drivers Postgres (se necessário)
# - ca-certificates: certificados TLS para downloads HTTPS
# Depois apaga o cache do apt para não inchar a imagem.
RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential \
      gcc \
      libpq-dev \
      ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copia SOMENTE o requirements.txt primeiro.
# Isso permite cache: se o código mudar mas requirements não, o Docker reaproveita a camada.
COPY requirements.txt .

# Gera wheels das dependências em /wheels.
# Assim no runtime você instala a partir de arquivos locais, sem toolchain.
RUN pip wheel --no-cache-dir --wheel-dir /wheels -r requirements.txt


# -------------------------
# STAGE 2: runtime
# Objetivo: imagem final pequena, só com Python + libs runtime + seu código.
# -------------------------
FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Instala apenas dependências MÍNIMAS de execução.
# - libpq5: runtime lib do Postgres (útil para drivers que linkam em libpq)
# - ca-certificates: TLS (chamadas HTTPS para auth-service, etc. se houver)
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates \
      libpq5 \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd -r app \
    && useradd --no-log-init -r -g app -d /app app

# Copia as wheels prontas do builder para o runtime
COPY --from=builder /wheels /wheels

# Instala as wheels (rápido e sem compilar) e remove os arquivos depois
RUN pip install --no-cache-dir /wheels/* && rm -rf /wheels

# Copia o código do serviço para dentro do container
COPY . .

# Garante que o usuário app é dono de todos os arquivos da pasta /app
RUN chown -R app:app /app

# A partir daqui, tudo roda como usuário não-root (boa prática de segurança)
USER app

EXPOSE 8002

CMD ["sh", "-c", "gunicorn --bind 0.0.0.0:${PORT:-8002} app:app"]