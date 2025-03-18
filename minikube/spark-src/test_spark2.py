"""
Script de teste para verificar o acesso direto ao MinIO via S3A
"""
from pyspark.sql import SparkSession
import pyspark.sql.functions as F
import os
import socket
import datetime

# Inicialização simplificada - as configurações vêm do SparkApplication
spark = SparkSession.builder \
    .appName("MinioSparkTest") \
    .getOrCreate()

print("="*80)
print("TESTE DE ACESSO DIRETO AO SCRIPT NO MINIO")
print("="*80)

# Imprimir informações do ambiente para diagnóstico
print(f"Data/Hora atual: {datetime.datetime.now()}")
print(f"Hostname: {socket.gethostname()}")
print(f"Diretório atual: {os.getcwd()}")
print(f"Versão do Spark: {spark.version}")

# Resto do código mantido igual...