# Função utilitária de exemplo
def hello_spark():
    return "Hello from Spark Utils!"

def process_data(df):
    """Função para processar um dataframe"""
    # Simples processamento como exemplo
    return df.withColumn("processed", df.age * 2)