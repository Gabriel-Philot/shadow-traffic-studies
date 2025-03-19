FROM spark:3.5.3

USER root

RUN chmod -R 777 /tmp

# Criar diretório para módulos Python personalizados
RUN mkdir -p /opt/spark/work-dir/utils

# Copiar módulos Python auxiliares
COPY utils/ /opt/spark/work-dir/utils/

# Copiar JARs para o diretório jars do Spark
COPY jars/*.jar $SPARK_HOME/jars/

# Definir permissões corretas
RUN chmod 645 $SPARK_HOME/jars/*.jar && \
    chmod -R 777 /opt/spark/work-dir/utils

# Instalar bibliotecas Python
RUN pip install delta-spark==3.3.0
RUN pip install boto3

# Voltar para o usuário Spark
USER ${spark_uid}