#!/bin/bash

# Cores para saída formatada
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # Sem cor

echo -e "${YELLOW}Iniciando upload dos scripts para o MinIO...${NC}"

# Definir variáveis
MINIO_ENDPOINT=$(kubectl get services -n deepstorage -l app.kubernetes.io/name=minio -o jsonpath="{.items[0].status.loadBalancer.ingress[0].ip}"):9000
MINIO_USER=$(kubectl get secret minio-secrets -n deepstorage -o jsonpath="{.data.root-user}" | base64 -d)
MINIO_PASSWORD=$(kubectl get secret minio-secrets -n deepstorage -o jsonpath="{.data.root-password}" | base64 -d)

echo -e "MinIO endpoint: ${MINIO_ENDPOINT}"
echo -e "MinIO user: ${MINIO_USER}"

# Configurar AWS CLI para MinIO
echo -e "Configurando AWS CLI para acessar MinIO..."
mkdir -p ~/.aws

cat > ~/.aws/credentials << EOF
[default]
aws_access_key_id = ${MINIO_USER}
aws_secret_access_key = ${MINIO_PASSWORD}
EOF

cat > ~/.aws/config << EOF
[default]
region = us-east-1
EOF

# Verificar se o bucket scripts existe
echo -e "Verificando se o bucket 'scripts' existe..."
if ! aws --endpoint-url=http://${MINIO_ENDPOINT} s3 ls s3://scripts &> /dev/null; then
    echo -e "Bucket 'scripts' não existe. Criando..."
    aws --endpoint-url=http://${MINIO_ENDPOINT} s3 mb s3://scripts
    echo -e "${GREEN}Bucket 'scripts' criado com sucesso!${NC}"
else
    echo -e "${GREEN}Bucket 'scripts' já existe.${NC}"
fi

# Fazer upload do script principal
echo -e "\n${YELLOW}Enviando script principal para o MinIO...${NC}"
aws --endpoint-url=http://${MINIO_ENDPOINT} s3 cp spark-src/test_spark2.py s3://scripts/minio-spark-scripts/

# Criar arquivo ZIP do módulo utils
echo -e "\n${YELLOW}Criando arquivo ZIP do módulo utils...${NC}"
cd spark-src
zip -r ../utils_modules.zip utils/
cd ..

# Verificar se o ZIP foi criado
if [ -f utils_modules.zip ]; then
    echo -e "${GREEN}Arquivo ZIP criado com sucesso: $(ls -la utils_modules.zip)${NC}"
    
    # Fazer upload do arquivo ZIP para o MinIO
    echo -e "\n${YELLOW}Enviando arquivo ZIP do módulo para o MinIO...${NC}"
    aws --endpoint-url=http://${MINIO_ENDPOINT} s3 cp utils_modules.zip s3://scripts/minio-spark-scripts/
    
    # Verificar o conteúdo
    echo -e "\n${YELLOW}Verificando conteúdo no MinIO...${NC}"
    echo "Conteúdo de minio-spark-scripts:"
    aws --endpoint-url=http://${MINIO_ENDPOINT} s3 ls s3://scripts/minio-spark-scripts/
    
    # Limpar arquivo ZIP local
    rm utils_modules.zip
else
    echo -e "${RED}Erro: Falha ao criar arquivo ZIP!${NC}"
fi

echo -e "\n${GREEN}Upload concluído!${NC}"