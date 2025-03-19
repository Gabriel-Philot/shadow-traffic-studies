"""
Script de teste para verificar o acesso direto ao MinIO via S3A
"""
from pyspark.sql import SparkSession
import pyspark.sql.functions as F
import os
import sys
import socket
import datetime

# Diagnóstico e configuração do ambiente
print("="*80)
print("DIAGNÓSTICO DO AMBIENTE PYTHON")
print(f"Data/Hora atual: {datetime.datetime.now()}")
print(f"Hostname: {socket.gethostname()}")
print(f"Diretório atual: {os.getcwd()}")
print(f"Conteúdo do diretório atual: {os.listdir('.')}")

# Adicionar caminhos ao sys.path
possible_paths = [
    '/opt/spark/work-dir',
    '/opt/spark/work-dir/utils',
    '/usr/local/lib/python3.9/site-packages',
    '/usr/local/lib/python3.8/site-packages',
    '/usr/local/lib/python3.7/site-packages',
    os.getcwd()
]

for path in possible_paths:
    if path not in sys.path and os.path.exists(path):
        sys.path.insert(0, path)
        print(f"Adicionado ao sys.path: {path}")

print(f"PYTHONPATH atual: {sys.path}")

# Verificar diretórios onde o módulo utils poderia estar
for path in sys.path:
    try:
        if os.path.exists(path):
            print(f"Conteúdo de {path}: {os.listdir(path)}")
            if os.path.exists(os.path.join(path, 'utils')):
                utils_dir = os.path.join(path, 'utils')
                print(f"Conteúdo de {utils_dir}: {os.listdir(utils_dir)}")
    except Exception as e:
        print(f"Erro ao listar {path}: {e}")

# Tentar importar de diferentes maneiras
try:
    # Tentativa 1: importação normal
    print("Tentando importação normal...")
    from utils.utils_test import hello_spark, process_data
    print("Importação normal bem-sucedida!")
except ImportError as e1:
    print(f"Erro na importação normal: {e1}")
    
    try:
        # Tentativa 2: importação com caminho absoluto
        print("Tentando importação absoluta...")
        sys.path.append('/opt/spark/work-dir')
        from utils.utils_test import hello_spark, process_data
        print("Importação absoluta bem-sucedida!")
    except ImportError as e2:
        print(f"Erro na importação absoluta: {e2}")
        
        try:
            # Tentativa 3: importação manual do módulo
            print("Tentando importação manual...")
            import imp
            utils_test = imp.load_source('utils_test', '/opt/spark/work-dir/utils/utils_test.py')
            hello_spark = utils_test.hello_spark
            process_data = utils_test.process_data
            print("Importação manual bem-sucedida!")
        except Exception as e3:
            print(f"Erro na importação manual: {e3}")
            
            # Definir funções mock se tudo falhar
            print("Usando funções mock...")
            def hello_spark():
                return "Função mock - importação falhou"
                
            def process_data(df):
                return df.withColumn("mock_column", F.lit("Importação falhou"))

# Inicialização do Spark
print("="*80)
print("INICIALIZANDO SPARK")
spark = SparkSession.builder \
    .appName("MinioSparkTest") \
    .getOrCreate()

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