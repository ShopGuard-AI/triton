#!/bin/bash

# Script para testar o Triton localmente com Docker Compose
# Este é útil para validar a configuração antes do deploy no Kubernetes

set -e

echo "🐳 Iniciando Triton localmente com Docker Compose..."

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Verificar se docker-compose está instalado
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}❌ docker-compose não encontrado${NC}"
    echo "   Instale com: sudo apt-get install docker-compose"
    exit 1
fi

# Verificar se a pasta de pesos existe
if [ ! -d "weights/models" ]; then
    echo -e "${RED}❌ Pasta de pesos não encontrada${NC}"
    exit 1
fi

echo -e "${YELLOW}📦 Iniciando container...${NC}"
docker-compose up -d

echo ""
echo -e "${YELLOW}⏳ Aguardando servidor ficar pronto...${NC}"
sleep 5

# Testar se o servidor está respondendo
MAX_RETRIES=30
RETRY=0
while [ $RETRY -lt $MAX_RETRIES ]; do
    if curl -s http://localhost:8000/v2/health/ready > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Servidor Triton está pronto!${NC}"
        break
    fi
    echo -n "."
    sleep 2
    RETRY=$((RETRY + 1))
done

if [ $RETRY -eq $MAX_RETRIES ]; then
    echo ""
    echo -e "${RED}❌ Timeout aguardando servidor${NC}"
    echo "   Verifique os logs com: docker-compose logs"
    exit 1
fi

echo ""
echo -e "${GREEN}🎉 Triton está rodando localmente!${NC}"
echo ""
echo "URLs disponíveis:"
echo "  HTTP:    http://localhost:8000"
echo "  gRPC:    localhost:8001"
echo "  Metrics: http://localhost:8002/metrics"
echo ""
echo "Comandos úteis:"
echo "  Ver logs:   docker-compose logs -f"
echo "  Parar:      docker-compose down"
echo "  Reiniciar:  docker-compose restart"
echo ""
echo "Teste de health check:"
echo "  curl http://localhost:8000/v2/health/ready"
