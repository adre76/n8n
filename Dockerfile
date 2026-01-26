# 1. Imagem oficial do n8n (2.4.6 - Latest em 23/01/2026)
FROM docker.n8n.io/n8nio/n8n:2.4.6

# 2. Mudar para usuário root para instalar pacotes de sistema
USER root

# 3. Instala apk-tools (removido da imagem base a partir do n8n 2.1.0)
RUN apk update && apk add --no-cache apk-tools

# 4. Instalar todas as dependências do sistema necessárias
RUN apk add --no-cache \
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
    && rm -rf /var/cache/apk/*

# 5. Instalar a biblioteca cliente do n8n para Python
#    Usamos --break-system-packages para contornar a proteção PEP 668
RUN pip3 install n8n --break-system-packages

# 6. Configurar o Git para usar HTTPS em vez de SSH
RUN git config --global url."https://github.com/".insteadOf "git@github.com:"
RUN git config --global url."https://github.com/".insteadOf "ssh://git@github.com/"

# 7. Instalar o Puppeteer e o node da comunidade n8n
RUN npm install -g puppeteer@latest
RUN npm install -g n8n-nodes-puppeteer@latest

# 8. Configure as variáveis de ambiente para o Puppeteer usar o Chromium do sistema
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium

# 9. Retornar ao usuário padrão 'node' para segurança e operação normal
USER node