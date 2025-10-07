FROM docker.n8n.io/n8nio/n8n:latest

USER root

# Instalar dependências do Chromium usando apk (para Alpine Linux)
RUN apk add --no-cache \
    chromium \
    nss \
    freetype \
    harfbuzz \
    ttf-freefont \
    udev \
    --repository=http://dl-cdn.alpinelinux.org/alpine/v3.14/main && \
    rm -rf /var/cache/apk/*

# Instalar Puppeteer globalmente
RUN npm install -g puppeteer@latest

# Instalar o community node n8n-nodes-puppeteer
RUN npm install -g n8n-nodes-puppeteer@latest

USER node

