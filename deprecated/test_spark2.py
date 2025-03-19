"""
Script de teste para verificar o acesso direto ao MinIO via S3A
com importação de módulos do arquivo ZIP
"""
from pyspark.sql import SparkSession
import pyspark.sql.functions as F
import os
import sys
import socket
import datetime

# Importando funções do módulo utils
from utils.utils_test import hello_spark, process_data

# Inicialização do Spark
spark = SparkSession.builder \
    .appName("MinioSparkTest") \
    .getOrCreate()

print("="*80)
print("TESTE DE ACESSO DIRETO AO SCRIPT NO MINIO COM MÓDULOS ZIP")
print("="*80)

# Imprimir informações do ambiente para diagnóstico
print(f"Data/Hora atual: {datetime.datetime.now()}")
print(f"Hostname: {socket.gethostname()}")
print(f"Diretório atual: {os.getcwd()}")
print(f"Versão do Spark: {spark.version}")
print(f"Python path: {sys.path}")

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

# Testar a função hello_spark
print("\nTestando função hello_spark:")
message = hello_spark()
print(message)

# Aplicar função process_data
print("\nAplicando função process_data:")
processed_df = process_data(df)
processed_df.show()

print("\nTESTE CONCLUÍDO COM SUCESSO!")
print("="*80)

# Encerrar a sessão Spark
spark.stop()