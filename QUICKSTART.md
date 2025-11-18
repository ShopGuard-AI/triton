# Guia Rápido - Deploy do Triton

## 🎯 Fluxo de Deploy

```
┌─────────────────────────────────────────────────────────┐
│  1. Build da Imagem Docker (com pesos embutidos)        │
│     - Feito no Docker daemon do Minikube/Kind           │
│     - Imagem fica disponível localmente no cluster     │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  2. Deploy no Kubernetes via Manifesto                  │
│     - kubectl apply -f triton-k8s.yaml                  │
│     - Usa a imagem local (sem pull de registry)        │
└─────────────────────────────────────────────────────────┘
```

## 📋 Opções de Deploy

### Opção 1: Deploy Automatizado no Minikube/Kind ⭐ (Recomendado)

```bash
cd triton
chmod +x build-and-deploy.sh
./build-and-deploy.sh
```

**O que faz:**
1. ✅ Detecta Minikube ou Kind
2. ✅ Faz build da imagem no Docker do cluster
3. ✅ Deploy automático via kubectl
4. ✅ Aguarda pod ficar pronto

### Opção 2: Teste Local (sem Kubernetes)

```bash
cd triton
chmod +x test-local.sh
./test-local.sh
```

**Usa docker-compose para testar rapidamente**

### Opção 3: Deploy Manual no Minikube

```bash
cd triton

# 1. Configurar Docker do Minikube
eval $(minikube docker-env)

# 2. Build da imagem
docker build -t shopguard/triton-server:latest .

# 3. Verificar imagem
docker images | grep triton

# 4. Deploy
kubectl apply -f triton-k8s.yaml

# 5. Verificar
kubectl get pods -n triton
kubectl logs -f -n triton -l app=triton
```

### Opção 4: Deploy Manual no Kind

```bash
cd triton

# 1. Build da imagem
docker build -t shopguard/triton-server:latest .

# 2. Carregar no Kind
kind load docker-image shopguard/triton-server:latest

# 3. Deploy
kubectl apply -f triton-k8s.yaml

# 4. Verificar
kubectl get pods -n triton
```

## 🔍 Verificação Pós-Deploy

```bash
# Status dos pods
kubectl get pods -n triton -o wide

# Logs
kubectl logs -f -n triton -l app=triton

# Health check (com port-forward)
kubectl port-forward -n triton svc/triton 8000:8000
curl http://localhost:8000/v2/health/ready

# Informações do deployment
kubectl describe deployment triton -n triton
kubectl describe pod -n triton -l app=triton
```

## 🛠️ Comandos Úteis

```bash
# Deletar deployment
kubectl delete -f triton-k8s.yaml

# Recriar deployment (forçar nova imagem)
kubectl delete deployment triton -n triton
kubectl apply -f triton-k8s.yaml

# Ver eventos
kubectl get events -n triton --sort-by='.lastTimestamp'

# Acessar shell do pod
kubectl exec -it -n triton $(kubectl get pod -n triton -l app=triton -o jsonpath='{.items[0].metadata.name}') -- /bin/bash
```

## ⚠️ Troubleshooting

### Pod não inicia
```bash
kubectl describe pod -n triton -l app=triton
kubectl logs -n triton -l app=triton
```

### ImagePullBackOff
- A imagem não está no cluster
- Rode novamente: `eval $(minikube docker-env) && docker build -t shopguard/triton-server:latest .`

### CrashLoopBackOff
- Verifique os logs: `kubectl logs -n triton -l app=triton`
- Possíveis causas:
  - Pesos não estão na estrutura correta
  - GPU não disponível
  - Erro no config.pbtxt

### GPU não detectada
```bash
# Verificar se GPU está disponível
kubectl get nodes -o json | jq '.items[].status.allocatable'

# Deve mostrar: "nvidia.com/gpu": "1"
```

## 📂 Estrutura de Arquivos

```
triton/
├── Dockerfile                  # Imagem com pesos embutidos
├── docker-compose.yml         # Teste local
├── triton-k8s.yaml           # Manifesto Kubernetes
├── build-and-deploy.sh       # Script automatizado ⭐
├── test-local.sh             # Teste rápido local
└── weights/                  # Pesos dos modelos
    └── models/
        └── yolov11n/
            ├── config.pbtxt
            └── 1/
                └── model.onnx
```
