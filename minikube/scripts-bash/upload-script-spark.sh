#!/bin/bash

# Cores para saída formatada
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # Sem cor

echo -e "${YELLOW}Iniciando upload do script para o MinIO...${NC}"

# Definir variáveis
MINIO_ENDPOINT=$(kubectl get services -n deepstorage -l app.kubernetes.io/name=minio -o jsonpath="{.items[0].status.loadBalancer.ingress[0].ip}"):9000
MINIO_USER=$(kubectl get secret minio-secrets -n deepstorage -o jsonpath="{.data.root-user}" | base64 -d)
MINIO_PASSWORD=$(kubectl get secret minio-secrets -n deepstorage -o jsonpath="{.data.root-password}" | base64 -d)

echo -e "MinIO endpoint: ${MINIO_ENDPOINT}"
echo -e "MinIO user: ${MINIO_USER}"

# Verificar se a AWS CLI está instalada
if ! command -v aws &> /dev/null; then
    echo -e "${YELLOW}AWS CLI não encontrada. Instalando...${NC}"
    pip install awscli
fi

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

# Fazer upload do script de teste
echo -e "\n${YELLOW}Fazendo upload do script de teste para o MinIO...${NC}"
aws --endpoint-url=http://${MINIO_ENDPOINT} s3 cp spark-src/test_spark.py s3://scripts/minio-spark-scripts/

if [ $? -eq 0 ]; then
    echo -e "${GREEN}Script enviado para o MinIO com sucesso!${NC}"
    echo -e "Caminho no MinIO: s3a://scripts/minio-spark-scripts/test_spark.py"
else
    echo -e "${RED}Erro ao enviar script para o MinIO!${NC}"
fi

echo -e "\n${GREEN}Processo de upload concluído!${NC}"