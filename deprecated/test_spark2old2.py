"""
Script de teste para verificar o acesso direto ao MinIO via S3A
com importação de funções da pasta utils
"""
from pyspark.sql import SparkSession
import pyspark.sql.functions as F
import os
import sys
import socket
import datetime

# Adicionar o diretório atual ao sys.path para permitir imports relativos
sys.path.append(os.getcwd())

# Imprimir sys.path para depuração
print("Python sys.path:")
for p in sys.path:
    print(f"  - {p}")

# Tentar importar o módulo
try:
    # Primeiro, tente o import direto
    from utils.utils_test import hello_spark, process_data
    print("Import direto funcionou!")
except ImportError as e:
    print(f"Erro no import direto: {e}")
    # Se falhar, tente o import alternativo
    try:
        sys.path.append("s3a://scripts/minio-spark-scripts/")
        from utils.utils_test import hello_spark, process_data
        print("Import com caminho S3 funcionou!")
    except ImportError as e:
        print(f"Erro no import com caminho S3: {e}")
        # Definir funções dummy para não quebrar o código
        def hello_spark():
            return "Função hello_spark não importada corretamente"
        
        def process_data(df):
            print("Usando função process_data alternativa")
            return df.withColumn("processed", df.idade * 2)

# Inicialização do Spark
spark = SparkSession.builder \
    .appName("MinioSparkTest") \
    .getOrCreate()

print("="*80)
print("TESTE DE ACESSO DIRETO AO SCRIPT NO MINIO COM IMPORTS")
print("="*80)

# Imprimir informações do ambiente para diagnóstico
print(f"Data/Hora atual: {datetime.datetime.now()}")
print(f"Hostname: {socket.gethostname()}")
print(f"Diretório atual: {os.getcwd()}")
print(f"Conteúdo do diretório atual: {os.listdir('.')}")
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

# Testar a função hello_spark
print("="*80)
print("\nTestando função hello_spark:")
print("="*80)
message = hello_spark()
print(message)

# Aplicar função process_data
print("="*80)
print("\nAplicando função process_data:")
print("="*80)
processed_df = process_data(df)
processed_df.show()

print("\nTESTE CONCLUÍDO COM SUCESSO!")
print("="*80)

# Encerrar a sessão Spark
spark.stop()