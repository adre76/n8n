# 1. MUDANÇA OBRIGATÓRIA: Usar Debian (bookworm) em vez de Alpine.
# O Alpine não roda o motor CAD (OCP) necessário para o build123d.
FROM node:22-bookworm

USER root

# 2. Instalar Chromium, Python e dependências do sistema
# No Debian, os nomes dos pacotes são diferentes do Alpine.
# Adicionamos libgl1-mesa-glx e libglib2.0-0 para o suporte 3D.
RUN apt-get update && apt-get install -y \
    chromium \
    git \
    python3 \
    python3-pip \
    python3-venv \
    curl \
    libgl1-mesa-glx \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# 3. Configurar Variáveis do Puppeteer
# No Debian, o chromium é instalado em /usr/bin/chromium
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium
ENV PUPPETEER_SKIP_DOWNLOAD=true

# 4. Configurar Ambiente Virtual Python (Obrigatório no Debian 12+)
# Isso evita erros de "externally managed environment" sem precisar de hacks
ENV VIRTUAL_ENV=/opt/venv
RUN python3 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# 5. Instalar build123d
# Agora vai funcionar porque o Debian é compatível com os binários do OCP
RUN pip install --upgrade pip && \
    pip install build123d

# 6. Instalar n8n
RUN npm install -g n8n@2.7.4

# 7. Configurar usuário e permissões
RUN mkdir -p /home/node/.n8n && chown -R node:node /home/node

USER node

EXPOSE 5678

CMD ["n8n"]