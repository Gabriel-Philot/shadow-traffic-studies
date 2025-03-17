FROM apache/spark-py:v3.3.2

# Switch to user root para adicionar jars e ferramentas
USER root

# Criar diretório para a aplicação
RUN mkdir -p /app

# Adicionar os JARs necessários para S3/MinIO e Delta Lake
ADD https://repo1.maven.org/maven2/io/delta/delta-core_2.12/2.2.0/delta-core_2.12-2.2.0.jar $SPARK_HOME/jars/
ADD https://repo1.maven.org/maven2/io/delta/delta-storage/2.2.0/delta-storage-2.2.0.jar $SPARK_HOME/jars/
ADD https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.12.431/aws-java-sdk-bundle-1.12.431.jar $SPARK_HOME/jars/
ADD https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-common/3.3.4/hadoop-common-3.3.4.jar $SPARK_HOME/jars/
ADD https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.3.4/hadoop-aws-3.3.4.jar $SPARK_HOME/jars/

# Definir permissões corretas
RUN chmod 644 $SPARK_HOME/jars/*.jar

# Instalar dependências adicionais necessárias
RUN pip install --no-cache-dir \
    delta-spark \
    pandas \
    pyarrow \
    matplotlib \
    seaborn

# Configurar ambiente para acesso ao MinIO
ENV PYSPARK_PYTHON=python3
ENV PYSPARK_DRIVER_PYTHON=python3

# Definir diretório de trabalho
WORKDIR /app

# Voltar para o usuário do Spark
USER ${spark_uid}