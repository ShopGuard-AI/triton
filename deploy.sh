#!/bin/bash

# Script de deployment do Triton Server no Kubernetes
# Namespace: triton

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configurações
IMAGE_NAME="shopguard/triton-server"
IMAGE_TAG="latest"
NAMESPACE="triton"
KUBECTL_CMD="kubectl"

echo -e "${GREEN}=== Triton Server Deployment Script ===${NC}"
echo ""

# Função para verificar se o comando existe
check_command() {
    if ! command -v $1 &> /dev/null; then
        echo -e "${RED}Erro: $1 não está instalado${NC}"
        exit 1
    fi
}

# Verificar dependências
echo -e "${YELLOW}Verificando dependências...${NC}"
check_command docker
check_command kubectl

# Build da imagem Docker
echo -e "${YELLOW}Construindo imagem Docker...${NC}"
docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Imagem Docker construída com sucesso${NC}"
else
    echo -e "${RED}✗ Erro ao construir imagem Docker${NC}"
    exit 1
fi

# Opcional: Push da imagem para registry (descomente se necessário)
# echo -e "${YELLOW}Fazendo push da imagem para o registry...${NC}"
# docker push ${IMAGE_NAME}:${IMAGE_TAG}

# Criar namespace se não existir
echo -e "${YELLOW}Verificando namespace...${NC}"
if ! ${KUBECTL_CMD} get namespace ${NAMESPACE} &> /dev/null; then
    echo -e "${YELLOW}Criando namespace ${NAMESPACE}...${NC}"
    ${KUBECTL_CMD} create namespace ${NAMESPACE}
    echo -e "${GREEN}✓ Namespace criado${NC}"
else
    echo -e "${GREEN}✓ Namespace já existe${NC}"
fi

# Aplicar manifesto Kubernetes
echo -e "${YELLOW}Aplicando manifesto Kubernetes...${NC}"
${KUBECTL_CMD} apply -f triton-k8s.yaml

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Manifesto aplicado com sucesso${NC}"
else
    echo -e "${RED}✗ Erro ao aplicar manifesto${NC}"
    exit 1
fi

# Aguardar deployment estar pronto
echo -e "${YELLOW}Aguardando deployment estar pronto...${NC}"
${KUBECTL_CMD} wait --for=condition=available --timeout=300s deployment/triton -n ${NAMESPACE}

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Deployment pronto${NC}"
else
    echo -e "${RED}✗ Timeout aguardando deployment${NC}"
    exit 1
fi

# Mostrar status
echo ""
echo -e "${GREEN}=== Status do Deployment ===${NC}"
${KUBECTL_CMD} get pods -n ${NAMESPACE}
echo ""
${KUBECTL_CMD} get svc -n ${NAMESPACE}

echo ""
echo -e "${GREEN}=== Deployment concluído com sucesso! ===${NC}"
echo ""
echo -e "${YELLOW}Para verificar os logs:${NC}"
echo "  kubectl logs -n ${NAMESPACE} -l app=triton -f"
echo ""
echo -e "${YELLOW}Para acessar o serviço localmente:${NC}"
echo "  kubectl port-forward -n ${NAMESPACE} svc/triton 8000:8000 8001:8001 8002:8002"
echo ""
