#!/bin/bash

# Cores para melhor visualização
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Script para download de JARs do Spark ===${NC}"

# Criar diretório jars se não existir
if [ ! -d "jars" ]; then
    echo -e "Criando diretório jars..."
    mkdir -p jars
    echo -e "${GREEN}✓ Diretório jars criado com sucesso!${NC}"
else
    echo -e "${GREEN}✓ Diretório jars já existe!${NC}"
fi

# Função para baixar JARs
download_jar() {
    local url=$1
    local filename=$(basename "$url")
    local target="jars/$filename"
    
    # Verifica se o arquivo já existe
    if [ -f "$target" ]; then
        echo -e "${GREEN}✓ Arquivo $filename já existe. Pulando...${NC}"
        return 0
    fi
    
    echo -e "Baixando $filename..."
    wget -q --show-progress "$url" -O "$target"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Download de $filename concluído com sucesso!${NC}"
    else
        echo -e "${RED}✗ Falha ao baixar $filename!${NC}"
        return 1
    fi
}

# Lista de JARs para baixar
echo -e "\n${BLUE}Iniciando downloads:${NC}"

# Hadoop/AWS JARs
download_jar "https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.3.4/hadoop-aws-3.3.4.jar"
download_jar "https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-common/3.3.4/hadoop-common-3.3.4.jar"
download_jar "https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.11.901/aws-java-sdk-bundle-1.11.901.jar"

# Delta Lake JARs
download_jar "https://repo1.maven.org/maven2/io/delta/delta-spark_2.12/3.3.0/delta-spark_2.12-3.3.0.jar"
download_jar "https://repo1.maven.org/maven2/io/delta/delta-storage/3.3.0/delta-storage-3.3.0.jar"

# JARs adicionais que podem ser úteis
download_jar "https://repo1.maven.org/maven2/org/apache/commons/commons-pool2/2.11.1/commons-pool2-2.11.1.jar"

echo -e "\n${BLUE}=== Resumo ===${NC}"
echo -e "Total de JARs no diretório: $(ls jars | wc -l)"
echo -e "${GREEN}Download de JARs concluído!${NC}"
echo -e "Os JARs estão disponíveis no diretório: $(pwd)/jars"
