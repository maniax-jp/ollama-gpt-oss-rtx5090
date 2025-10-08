#!/bin/bash
# Setup script for gpt-oss-20b model on Ollama

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}GPT-OSS-20B Model Setup Script${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check if Docker is running
if ! docker ps > /dev/null 2>&1; then
    echo -e "${RED}Error: Docker is not running${NC}"
    exit 1
fi

# Check if Ollama container is running
CONTAINER_NAME="ollama-gpt-oss"
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo -e "${YELLOW}Starting Ollama container...${NC}"
    docker-compose up -d
    echo -e "${GREEN}Waiting for Ollama to be ready...${NC}"
    sleep 10
fi

# Check Ollama health
echo -e "${YELLOW}Checking Ollama service status...${NC}"
MAX_RETRIES=10
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if docker exec ${CONTAINER_NAME} curl -f http://localhost:11434/api/tags > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Ollama service is ready${NC}"
        break
    fi
    RETRY_COUNT=$((RETRY_COUNT+1))
    echo -e "${YELLOW}Waiting for Ollama to be ready... (${RETRY_COUNT}/${MAX_RETRIES})${NC}"
    sleep 3
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    echo -e "${RED}Error: Ollama service did not start properly${NC}"
    docker-compose logs ollama
    exit 1
fi

# Check GPU availability
echo -e "${YELLOW}Checking GPU availability...${NC}"
if docker exec ${CONTAINER_NAME} nvidia-smi > /dev/null 2>&1; then
    echo -e "${GREEN}✓ GPU detected${NC}"
    docker exec ${CONTAINER_NAME} nvidia-smi --query-gpu=name,memory.total --format=csv,noheader
else
    echo -e "${RED}Warning: GPU not detected. Performance may be limited.${NC}"
fi

# Check if model already exists
echo -e "${YELLOW}Checking for existing gpt-oss:20b model...${NC}"
if docker exec ${CONTAINER_NAME} ollama list | grep -q "gpt-oss:20b"; then
    echo -e "${YELLOW}Model already exists. Do you want to re-download? (y/N)${NC}"
    read -r response
    if [[ ! "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        echo -e "${GREEN}Using existing model.${NC}"
        docker exec ${CONTAINER_NAME} ollama list
        exit 0
    fi
    echo -e "${YELLOW}Removing existing model...${NC}"
    docker exec ${CONTAINER_NAME} ollama rm gpt-oss:20b
fi

# Download gpt-oss-20b model
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Downloading gpt-oss:20b model...${NC}"
echo -e "${GREEN}This may take several minutes (16GB+ download)${NC}"
echo -e "${GREEN}========================================${NC}"

if docker exec -it ${CONTAINER_NAME} ollama pull gpt-oss:20b; then
    echo -e "${GREEN}✓ Model downloaded successfully${NC}"
else
    echo -e "${RED}Error: Failed to download model${NC}"
    exit 1
fi

# Verify installation
echo -e "${YELLOW}Verifying installation...${NC}"
docker exec ${CONTAINER_NAME} ollama list

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Setup completed successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "You can now use the model with:"
echo -e "${YELLOW}  docker exec -it ${CONTAINER_NAME} ollama run gpt-oss:20b${NC}"
echo ""
echo -e "Or via API:"
echo -e "${YELLOW}  curl http://localhost:11434/api/generate -d '{\"model\":\"gpt-oss:20b\",\"prompt\":\"Hello\"}'${NC}"
echo ""
echo -e "To test performance:"
echo -e "${YELLOW}  docker exec ${CONTAINER_NAME} ollama run gpt-oss:20b \"Explain quantum computing in 100 words\"${NC}"
echo ""
