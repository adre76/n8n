#!/bin/bash

# Script para deploy automatizado do n8n no Kubernetes

NAMESPACE="n8n"

# Cores para a saída do terminal
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Função para verificar se um recurso foi criado
wait_for_resource() {
  local resource_type=$1
  local resource_name=$2
  local namespace=$3
  local status_check_cmd=$4
  local timeout=${5:-300} # Default timeout de 5 minutos
  local interval=5
  local elapsed=0

  echo -e "${GREEN}Aguardando que o recurso $resource_type/$resource_name no namespace $namespace esteja pronto...${NC}"

  while ! eval "$status_check_cmd" &>/dev/null && [ $elapsed -lt $timeout ]; do
    printf "."
    sleep $interval
    elapsed=$((elapsed + interval))
  done

  if [ $elapsed -ge $timeout ]; then
    echo -e "\nErro: Tempo limite excedido para $resource_type/$resource_name."
    exit 1
  fi
  echo -e "\n${GREEN}Recurso $resource_type/$resource_name pronto.${NC}"
}

# 1. Verificar pré-requisitos
echo -e "\n${GREEN}=== 1. Verificando pré-requisitos ===${NC}"
if ! command -v kubectl &> /dev/null
then
    echo "Erro: kubectl não encontrado. Por favor, instale e configure o kubectl."
    exit 1
fi

# 2. Criar o Namespace
echo -e "\n${GREEN}=== 2. Criando o Namespace ===${NC}"
echo "Criando o namespace \'$NAMESPACE\' se ele não existir..."
kubectl get namespace $NAMESPACE &> /dev/null || kubectl create namespace $NAMESPACE
if [ $? -ne 0 ]; then
    echo "Erro ao criar ou verificar o namespace \'$NAMESPACE\'."
    exit 1
fi
echo "Namespace \'$NAMESPACE\' garantido."

# 3. Aplicar Secret
echo -e "\n${GREEN}=== 3. Aplicando Secret ===${NC}"
echo "Aplicando n8n-secret.yaml..."
kubectl apply -f n8n-secret.yaml -n $NAMESPACE
wait_for_resource "secret" "n8n-secret" "$NAMESPACE" "kubectl get secret n8n-secret -n $NAMESPACE"

# 4. Aplicar Persistent Volume Claim (PVC)
echo -e "\n${GREEN}=== 4. Aplicando Persistent Volume Claim (PVC) ===${NC}"
echo "Aplicando n8n-pvc.yaml..."
kubectl apply -f n8n-pvc.yaml -n $NAMESPACE
wait_for_resource "pvc" "n8n-pvc" "$NAMESPACE" "kubectl get pvc n8n-pvc -n $NAMESPACE -o jsonpath=\'{$.status.phase}\' | grep -q \'Bound\'"

# 5. Aplicar Deployment
echo -e "\n${GREEN}=== 5. Aplicando Deployment ===${NC}"
echo "Aplicando n8n-deployment.yaml..."
kubectl apply -f n8n-deployment.yaml -n $NAMESPACE
wait_for_resource "deployment" "n8n" "$NAMESPACE" "kubectl rollout status deployment/n8n -n $NAMESPACE --timeout=0s"

# 6. Aplicar Service
echo -e "\n${GREEN}=== 6. Aplicando Service ===${NC}"
echo "Aplicando n8n-service.yaml..."
kubectl apply -f n8n-service.yaml -n $NAMESPACE
wait_for_resource "service" "n8n" "$NAMESPACE" "kubectl get service n8n -n $NAMESPACE"

# 7. Aplicar Ingress
echo -e "\n${GREEN}=== 7. Aplicando Ingress ===${NC}"
echo "Aplicando n8n-ingress.yaml..."
kubectl apply -f n8n-ingress.yaml -n $NAMESPACE
wait_for_resource "ingress" "n8n-ingress" "$NAMESPACE" "kubectl get ingress n8n-ingress -n $NAMESPACE"

echo -e "\n${GREEN}Deploy do n8n concluído com sucesso no namespace \'$NAMESPACE\'.${NC}"
echo "Verifique o status dos recursos com: kubectl get all -n $NAMESPACE"
#echo "Lembre-se de configurar seu arquivo /etc/hosts para \'n8n.local\' apontando para o IP do seu Ingress Controller."