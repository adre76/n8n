# Imagem oficial do n8n (2.4.6 - Latest em 23/01/2026)
FROM docker.n8n.io/n8nio/n8n:2.4.6

# Permite instalar pacotes
USER root

# Instalar dependências do sistema para Chromium/Puppeteer
RUN apt-get update && apt-get install -y --no-install-recommends \
    chromium \
    chromium-driver \
    ca-certificates \
    fonts-liberation \
    libasound2 \
    libatk-bridge2.0-0 \
    libatk1.0-0 \
    libcups2 \
    libdbus-1-3 \
    libdrm2 \
    libgbm1 \
    libgtk-3-0 \
    libnspr4 \
    libnss3 \
    libx11-xcb1 \
    libxcomposite1 \
    libxdamage1 \
    libxrandr2 \
    xdg-utils \
    udev \
    git \
    python3 \
    python3-pip \
    curl \
    dnsutils \
    && rm -rf /var/lib/apt/lists/*

# Defina o caminho do Chromium para Puppeteer
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium

# Voltar para o usuário padrão do n8n
USER node
