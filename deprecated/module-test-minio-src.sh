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

# Verificar se os arquivos existem localmente
if [ ! -f spark-src/test_spark2.py ]; then
    echo -e "${RED}Erro: O arquivo spark-src/test_spark2.py não existe!${NC}"
    exit 1
fi

if [ ! -f spark-src/utils/utils_test.py ]; then
    echo -e "${RED}Erro: O arquivo spark-src/utils/utils_test.py não existe!${NC}"
    exit 1
fi

# Fazer upload do script principal
echo -e "\n${YELLOW}Enviando script principal para o MinIO...${NC}"
aws --endpoint-url=http://${MINIO_ENDPOINT} s3 cp spark-src/test_spark2.py s3://scripts/minio-spark-scripts/

# Fazer upload do arquivo utils
echo -e "\n${YELLOW}Enviando utils_test.py para o MinIO...${NC}"
aws --endpoint-url=http://${MINIO_ENDPOINT} s3 cp spark-src/utils/utils_test.py s3://scripts/minio-spark-scripts/utils/

# Verificar o conteúdo
echo -e "\n${YELLOW}Verificando conteúdo no MinIO...${NC}"
echo "Conteúdo de minio-spark-scripts:"
aws --endpoint-url=http://${MINIO_ENDPOINT} s3 ls s3://scripts/minio-spark-scripts/
echo "Conteúdo de minio-spark-scripts/utils:"
aws --endpoint-url=http://${MINIO_ENDPOINT} s3 ls s3://scripts/minio-spark-scripts/utils/

echo -e "\n${GREEN}Upload concluído!${NC}"