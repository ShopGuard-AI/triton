# Dockerfile para Triton Inference Server com pesos embutidos
FROM nvcr.io/nvidia/tritonserver:25.03-py3

# Copiar os pesos do modelo para dentro da imagem
COPY weights/ /mnt/weights/

# Expor as portas do Triton
EXPOSE 8000 8001 8002

# Comando padrão para iniciar o Triton
CMD ["tritonserver", \
     "--model-repository=/mnt/weights/models", \
     "--model-control-mode=poll", \
     "--repository-poll-secs=300", \
     "--disable-auto-complete-config", \
     "--allow-http=true", \
     "--allow-grpc=true", \
     "--allow-metrics=true", \
     "--log-verbose=1"]
