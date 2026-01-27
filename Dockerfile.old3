# Base oficial Node com Alpine (multi-arch, inclui ARM64)
FROM node:22-alpine

# Usar root para instalar dependências
USER root

# Instalar dependências necessárias para Chromium + Puppeteer + scraping
RUN apk update && apk add --no-cache \
    chromium \
    nss \
    freetype \
    harfbuzz \
    ttf-freefont \
    udev \
    git \
    python3 \
    py3-pip \
    curl \
    bind-tools \
    ca-certificates \
    bash \
    && rm -rf /var/cache/apk/*

# Variável obrigatória para o Puppeteer encontrar o Chromium do sistema
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium-browser
ENV PUPPETEER_SKIP_DOWNLOAD=true

# Instalar exatamente a versão do n8n desejada
RUN npm install -g n8n@2.4.6

# Criar diretório de dados do n8n e ajustar permissões
RUN mkdir -p /home/node/.n8n && chown -R node:node /home/node

# Rodar como usuário não-root (boa prática para Kubernetes)
USER node

# Porta padrão
EXPOSE 5678

# Comando padrão
CMD ["n8n"]
