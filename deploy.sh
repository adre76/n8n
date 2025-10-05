#!/bin/bash

# --- Script otimizado para deploy do n8n no Kubernetes ---
# Melhores práticas:
# 1. Usa o namespace como um parâmetro para flexibilidade.
# 2. Aplica todos os arquivos de uma vez, deixando o Kubernetes gerenciar as dependências.
# 3. Usa o comando nativo 'rollout status' para verificar se a aplicação está pronta.

# Cores para a saída do terminal
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# --- 1. Verificação de Pré-requisitos e Namespace ---

# Verifica se o kubectl está instalado
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Erro: kubectl não encontrado. Por favor, instale e configure o kubectl.${NC}"
    exit 1
fi

# Verifica se o namespace foi passado como argumento
if [ -z "$1" ]; then
  echo -e "${RED}Erro: Namespace não especificado.${NC}"
  echo "Uso: $0 <namespace>"
  exit 1
fi

NAMESPACE=$1
DEPLOYMENT_NAME="n8n-deployment" # Nome do deployment definido em n8n-deployment.yaml

echo -e "\n${GREEN}=== Iniciando deploy do n8n no namespace '$NAMESPACE' ===${NC}"

# --- 2. Criação do Namespace ---

echo -e "\n${GREEN}Garantindo que o namespace '$NAMESPACE' exista...${NC}"
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f - > /dev/null
if [ $? -ne 0 ]; then
    echo -e "${RED}Erro ao criar o namespace '$NAMESPACE'.${NC}"
    exit 1
fi
echo "Namespace '$NAMESPACE' pronto."


# --- 3. Aplicando todos os manifestos ---

echo -e "\n${GREEN}Aplicando todos os arquivos .yaml (Secret, PVC, Deployment, Service, etc.)...${NC}"
# Esta é a forma correta: aplicar tudo de uma vez.
# O Kubernetes entende a ordem e o PVC esperará pelo Pod sem travar o script.
kubectl apply -f . -n "$NAMESPACE"
if [ $? -ne 0 ]; then
    echo -e "${RED}Erro ao aplicar os manifestos. Verifique a saída acima.${NC}"
    exit 1
fi
echo "Todos os manifestos foram aplicados com sucesso."


# --- 4. Verificando o Status do Deploy ---

echo -e "\n${GREEN}Aguardando o n8n ficar pronto... (Isso pode levar alguns minutos)${NC}"
# Este é o único "wait" que realmente precisamos.
# Ele monitora os Pods sendo criados e se tornando saudáveis.
if kubectl rollout status "deployment/$DEPLOYMENT_NAME" -n "$NAMESPACE" --timeout=5m; then
  echo -e "\n${GREEN}✅ Deploy do n8n concluído com sucesso!${NC}"
  echo "Para verificar os recursos, use: kubectl get all -n $NAMESPACE"
else
  echo -e "\n${RED}❌ O deploy falhou ou excedeu o tempo limite.${NC}"
  echo "Use os seguintes comandos para investigar o problema:"
  echo "  kubectl get pods -n $NAMESPACE"
  echo "  kubectl describe pod <nome-do-pod-com-erro> -n $NAMESPACE"
  exit 1
fi