# Base oficial Node com Alpine (multi-arch, inclui ARM64)
FROM node:22-alpine

# Usar root para instalar dependências
USER root

# Instalar dependências necessárias para Chromium + Puppeteer + scraping
# ADICIONEI: gcompat, libstdc++, mesa-gl (necessários para tentar rodar OCP/build123d no Alpine)
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
    gcompat \
    libstdc++ \
    mesa-gl \
    mesa-egl \
    && rm -rf /var/cache/apk/*

# Variável obrigatória para o Puppeteer encontrar o Chromium do sistema
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium-browser
ENV PUPPETEER_SKIP_DOWNLOAD=true

# Instalar a biblioteca build123d para Python
# ALTERAÇÃO CRÍTICA: Adicionado --break-system-packages para permitir instalação no Alpine
RUN pip install build123d --break-system-packages

# Instalar exatamente a versão do n8n desejada
RUN npm install -g n8n@2.6.3

# Criar diretório de dados do n8n e ajustar permissões
RUN mkdir -p /home/node/.n8n && chown -R node:node /home/node

# Rodar como usuário não-root (boa prática para Kubernetes)
USER node

# Porta padrão
EXPOSE 5678

# Comando padrão
CMD ["n8n"]