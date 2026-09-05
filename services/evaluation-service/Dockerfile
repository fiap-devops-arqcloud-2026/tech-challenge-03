# -------------------------
# STAGE 1: builder
# Objetivo: compilar o binário Go dentro de um ambiente com toolchain do Go.
# O resultado (binário) será copiado para uma imagem final bem menor.
# -------------------------
FROM golang:1.22-alpine AS builder

# Instala:
# - ca-certificates: para permitir downloads/HTTPS (ex.: go mod download via https)
# - git: algumas dependências podem precisar (mesmo que poucas hoje em dia)
RUN apk add --no-cache ca-certificates git

# Diretório de trabalho dentro do container de build
WORKDIR /src

# Copia primeiro somente os arquivos de dependência.
# Isso permite cache: se o código mudar mas o go.mod/go.sum não, o Docker reaproveita a camada do download.
COPY go.mod go.sum ./

# Baixa dependências do módulo (cacheável)
RUN go mod download

# Agora copia o restante do código-fonte
COPY . .

# Compila o serviço:
# - CGO_ENABLED=0: gera binário estático (reduz dependências no runtime)
# - GOOS=linux: garante binário para Linux (ambiente container)
# - -trimpath: remove caminhos locais do build (mais limpo e reproduzível)
# - -ldflags "-s -w": reduz tamanho removendo símbolos de debug
#
# O "." funciona porque o README manda "go run .", indicando main package na raiz do serviço.
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-s -w" -o /out/service .

# -------------------------
# STAGE 2: runtime
# Objetivo: imagem final mínima, contendo só o binário e certificados.
# -------------------------
FROM alpine:3.20

# Instala certificados para chamadas HTTPS (caso o serviço faça requests HTTPS),
# e cria um usuário não-root (boa prática de segurança).
RUN apk add --no-cache ca-certificates \
  && addgroup -S app \
  && adduser -S app -G app

# Diretório do app no runtime
WORKDIR /app

# Copia somente o binário compilado do stage builder
COPY --from=builder /out/service /app/service

# Usa usuário não-root para executar o processo
USER app

# Porta documentada (quem define a porta real é a env PORT e o docker-compose faz o mapeamento)
EXPOSE 8004

# Comando principal do container
ENTRYPOINT ["/app/service"]