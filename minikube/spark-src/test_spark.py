"""
Script de teste para verificar o acesso direto ao MinIO via S3A
Este arquivo deve ser carregado em: s3a://scripts/minio-spark-scripts/teste_spark.py
"""
from pyspark.sql import SparkSession
import pyspark.sql.functions as F
import os
import socket
import datetime

# Inicializar o Spark com as configurações para Delta Lake
spark = SparkSession.builder \
    .appName("MinioSparkTest") \
    .config("spark.sql.extensions", "io.delta.sql.DeltaSparkSessionExtension") \
    .config("spark.sql.catalog.spark_catalog", "org.apache.spark.sql.delta.catalog.DeltaCatalog") \
    .getOrCreate()

print("="*80)
print("TESTE DE ACESSO DIRETO AO SCRIPT NO MINIO")
print("="*80)

# Imprimir informações do ambiente para diagnóstico
print(f"Data/Hora atual: {datetime.datetime.now()}")
print(f"Hostname: {socket.gethostname()}")
print(f"Diretório atual: {os.getcwd()}")
print(f"Versão do Spark: {spark.version}")

# Criar um DataFrame simples para teste
print("\nCriando DataFrame de teste...")
data = [
    ("Alice", 30),
    ("Bob", 25),
    ("Charlie", 35),
    ("David", 28)
]
columns = ["nome", "idade"]
df = spark.createDataFrame(data, columns)

# Mostrar amostra
df.show()

# Aplicar algumas transformações
df_transformed = df.withColumn("mensagem", 
                             F.concat(F.lit("Olá "), 
                                     F.col("nome"), 
                                     F.lit("! Você tem "), 
                                     F.col("idade").cast("string"), 
                                     F.lit(" anos.")))
print("DataFrame transformado:")
df_transformed.show(truncate=False)

# Tentar listar arquivos no MinIO
print("\nTestando acesso ao MinIO...")
try:
    # Listar conteúdo do bucket landing
    landing_files = spark._jvm.org.apache.hadoop.fs.FileSystem.get(
        spark._jsc.hadoopConfiguration()
    ).listStatus(spark._jvm.org.apache.hadoop.fs.Path("s3a://landing/"))
    
    print("Arquivos no bucket landing:")
    for file_status in landing_files:
        print(f"  - {file_status.getPath().getName()}")

    # Tentar acessar dados reais se existirem
    try:
        # Tentar ler arquivo JSON do bucket landing
        customer_df = spark.read.format("json").load("s3a://landing/shadow-traffic-data/customers/")
        print("\nDados de clientes encontrados! Amostra:")
        customer_df.printSchema()
        customer_df.show(5, truncate=False)
        print(f"Total de registros: {customer_df.count()}")
    except Exception as e:
        print(f"Não foi possível ler dados de clientes: {e}")
        
except Exception as e:
    print(f"Erro ao acessar MinIO: {str(e)}")

# Escrever resultado em Delta format como teste
try:
    print("\nTentando escrever dados no formato Delta...")
    df_transformed.write \
        .format("delta") \
        .mode("overwrite") \
        .save("s3a://scripts/teste-output/delta-teste")
    print("Dados escritos com sucesso no formato Delta!")
except Exception as e:
    print(f"Erro ao escrever no formato Delta: {str(e)}")

print("\nTESTE CONCLUÍDO COM SUCESSO!")
print("="*80)

# Encerrar a sessão Spark
spark.stop()