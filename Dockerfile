# Dockerfile for Ollama with RTX 5090 (Blackwell) and MXFP4 support
# Base image: Official Ollama 0.12.3 with CUDA support
FROM ollama/ollama:0.12.3

# Metadata
LABEL maintainer="maniax"
LABEL description="Ollama 0.12.3 optimized for NVIDIA RTX 5090 with gpt-oss-20b MXFP4 support"
LABEL version="1.0"

# Environment variables for NVIDIA GPU
ENV NVIDIA_VISIBLE_DEVICES=all \
    NVIDIA_DRIVER_CAPABILITIES=compute,utility \
    OLLAMA_HOST=0.0.0.0:11434 \
    OLLAMA_ORIGINS=* \
    OLLAMA_NUM_PARALLEL=1 \
    OLLAMA_MAX_LOADED_MODELS=1

# Install additional utilities (optional)
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    wget \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Create directory for models
RUN mkdir -p /root/.ollama

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:11434/api/tags || exit 1

# Expose Ollama API port
EXPOSE 11434

# Start Ollama service
CMD ["serve"]
