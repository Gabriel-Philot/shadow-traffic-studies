def hello_spark():
    """Retorna uma mensagem de teste."""
    return "Hello from utils_test.py! Módulo importado com sucesso!"

def process_data(df):
    """
    Processa um DataFrame adicionando novas colunas.
    
    Args:
        df: Um DataFrame Spark
    
    Returns:
        DataFrame processado com novas colunas
    """
    from pyspark.sql import functions as F
    
    # Adiciona uma coluna com a idade em meses
    processed = df.withColumn("idade_meses", F.col("idade") * 12)
    
    # Adiciona uma coluna com a categoria de idade
    processed = processed.withColumn(
        "categoria_idade",
        F.when(F.col("idade") < 25, "jovem")
         .when(F.col("idade") < 35, "adulto")
         .otherwise("senior")
    )
    
    return processed