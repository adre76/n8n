# 1. Imagem oficial do n8n (2.0.0 - Latest em 05/12/2025)
FROM docker.n8n.io/n8nio/n8n:2.0.0

# 2. Mudar para usuário root para instalar pacotes de sistema
USER root

# 3. Instalar todas as dependências do sistema necessárias
RUN apk add --no-cache \
    chromium \
    nss \
    freetype \
    harfbuzz \
    ttf-freefont \
    udev \
    git \
    python3 \
    py3-pip && \
    rm -rf /var/cache/apk/*

# 4. Instalar a biblioteca cliente do n8n para Python
#    Usamos --break-system-packages para contornar a proteção PEP 668
RUN pip3 install n8n --break-system-packages

# 5. Configurar o Git para usar HTTPS em vez de SSH
RUN git config --global url."https://github.com/".insteadOf "git@github.com:"
RUN git config --global url."https://github.com/".insteadOf "ssh://git@github.com/"

# 6. Instalar o Puppeteer e o node da comunidade n8n
RUN npm install -g puppeteer@latest
RUN npm install -g n8n-nodes-puppeteer@latest

# 7. Retornar ao usuário padrão 'node' para segurança e operação normal
USER node