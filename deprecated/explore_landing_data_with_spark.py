## used to test the connection to the MinIO bucket in jupyterlab

from pyspark.sql import SparkSession
from pyspark.sql.functions import *
from pyspark.sql.types import *
import os


# Obter credenciais do MinIO
minio_endpoint = os.environ.get('MINIO_ENDPOINT')
minio_access_key = os.environ.get('MINIO_ACCESS_KEY')
minio_secret_key = os.environ.get('MINIO_SECRET_KEY')

# Criar sessão Spark
spark = SparkSession.builder \
    .appName("TestSparkMinIO") \
    .config("spark.hadoop.fs.s3a.access.key", minio_access_key) \
    .config("spark.hadoop.fs.s3a.secret.key", minio_secret_key) \
    .config("spark.hadoop.fs.s3a.endpoint", minio_endpoint.replace("http://", "")) \
    .config("spark.hadoop.fs.s3a.path.style.access", "true") \
    .config("spark.hadoop.fs.s3a.impl", "org.apache.hadoop.fs.s3a.S3AFileSystem") \
    .config("spark.hadoop.fs.s3a.connection.ssl.enabled", "false") \
    .getOrCreate()

print(f"Spark version: {spark.version}")

# Testar leitura do MinIO
try:
    path = "s3a://landing/shadow-traffic-data/customers/"
    df = spark.read.json(path)
    print("Amostra de dados:")
    df.show(5)
except Exception as e:
    print(f"Erro ao ler dados: {e}")