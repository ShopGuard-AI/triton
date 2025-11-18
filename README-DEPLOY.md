# Triton Inference Server - Deploy com Pesos Embutidos

Este diretório contém os arquivos para fazer deploy do Triton Inference Server no Kubernetes com os pesos do modelo embutidos na imagem Docker.

## 📁 Estrutura de Arquivos

```
triton/
├── Dockerfile              # Imagem Docker com pesos embutidos
├── docker-compose.yml      # Para testes locais
├── triton-k8s.yaml        # Manifesto Kubernetes
├── build-and-deploy.sh    # Script automatizado de build e deploy
├── deploy-triton.sh       # Script antigo (hostPath) - deprecated
└── weights/               # Pesos dos modelos
    └── models/
        └── yolov11n/
```

## 🎯 Vantagens da Abordagem com Imagem

### ✅ Benefícios:
- **Portabilidade**: A imagem funciona em qualquer cluster Kubernetes
- **Consistência**: Mesma versão dos pesos em todos os pods
- **Simplicidade**: Não precisa configurar volumes ou copiar arquivos
- **Escalabilidade**: Fácil de escalar horizontalmente (múltiplos pods)
- **Versionamento**: Pode versionar pesos junto com código usando tags
- **CI/CD**: Integra facilmente em pipelines de deployment

### ⚠️ Considerações:
- Imagem será maior (inclui os pesos)
- Build demora mais na primeira vez
- Para atualizar pesos, precisa fazer rebuild da imagem

## 🚀 Como Usar

### Passo 1: Preparar os Pesos

Certifique-se de que seus pesos estejam na estrutura correta:

```bash
weights/
└── models/
    └── yolov11n/
        ├── config.pbtxt
        └── 1/
            └── model.onnx  # ou .engine, .pt, etc
```

### Passo 2: Build e Deploy Automatizado

```bash
cd triton
chmod +x build-and-deploy.sh
./build-and-deploy.sh
```

Este script irá:
1. ✅ Verificar a pasta de pesos
2. ✅ Detectar seu tipo de cluster (Minikube/Kind/Docker)
3. ✅ Construir a imagem Docker com os pesos embutidos
4. ✅ Carregar a imagem no cluster (se necessário)
5. ✅ Fazer deploy no Kubernetes
6. ✅ Aguardar o pod ficar pronto

### Passo 3: Verificar o Deployment

```bash
# Ver status dos pods
kubectl get pods -n triton

# Ver logs
kubectl logs -f -n triton -l app=triton

# Fazer port-forward para acessar localmente
kubectl port-forward -n triton svc/triton 8000:8000 8001:8001 8002:8002

# Testar o servidor
curl http://localhost:8000/v2/health/ready
```

## 🔧 Build Manual

Se preferir fazer o build manualmente:

```bash
cd triton

# Para Minikube
eval $(minikube docker-env)
docker build -t shopguard/triton-server:latest .

# Para Kind
docker build -t shopguard/triton-server:latest .
kind load docker-image shopguard/triton-server:latest

# Para clusters remotos
docker build -t <seu-registry>/triton-server:latest .
docker push <seu-registry>/triton-server:latest
# Depois atualize o triton-k8s.yaml com a imagem correta
```

## 🐳 Teste Local com Docker Compose

Para testar localmente antes de fazer deploy no Kubernetes:

```bash
docker-compose up
```

Acesse em:
- HTTP: http://localhost:8000
- gRPC: localhost:8001
- Metrics: http://localhost:8002/metrics

## 📝 Atualizar Pesos

Para atualizar os pesos do modelo:

1. Atualize os arquivos em `weights/models/`
2. Execute novamente o script:
   ```bash
   ./build-and-deploy.sh
   ```

## 🔍 Troubleshooting

### Pod não inicia
```bash
kubectl describe pod -n triton -l app=triton
kubectl logs -n triton -l app=triton
```

### Erro de GPU
Certifique-se de que seu cluster tem suporte a GPU e o NVIDIA device plugin instalado:
```bash
kubectl get nodes -o json | jq '.items[].status.allocatable'
```

### Imagem muito grande
Se a imagem ficar muito grande, considere:
- Usar modelos quantizados (FP16, INT8)
- Comprimir os pesos
- Usar um registry privado mais próximo

## 🌐 Deploy em Produção

Para ambientes de produção:

1. **Use um registry privado**:
   ```bash
   docker tag shopguard/triton-server:latest gcr.io/seu-projeto/triton-server:v1.0.0
   docker push gcr.io/seu-projeto/triton-server:v1.0.0
   ```

2. **Atualize o manifesto** (`triton-k8s.yaml`):
   ```yaml
   image: gcr.io/seu-projeto/triton-server:v1.0.0
   imagePullPolicy: Always
   ```

3. **Adicione recursos adequados**:
   ```yaml
   resources:
     limits:
       nvidia.com/gpu: "1"
       memory: "8Gi"
     requests:
       nvidia.com/gpu: "1"
       memory: "4Gi"
   ```

4. **Configure health checks**:
   ```yaml
   livenessProbe:
     httpGet:
       path: /v2/health/live
       port: 8000
     initialDelaySeconds: 30
     periodSeconds: 10
   readinessProbe:
     httpGet:
       path: /v2/health/ready
       port: 8000
     initialDelaySeconds: 30
     periodSeconds: 10
   ```
