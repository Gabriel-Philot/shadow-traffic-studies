# Use a imagem base do shadowtraffic
FROM shadowtraffic/shadowtraffic:latest

# Criar diretórios necessários
RUN mkdir -p /workspace /app/files

# Copiar o arquivo de configuração v0_local_gen.json para o diretório /workspace
COPY v0_local_gen.json /workspace/

# Copiar o diretório files/ para /app/files no contêiner
COPY files/ /app/files/

# Copiar o arquivo de licença license.env
COPY license.env /

# Configurar entrypoint para carregar as variáveis de ambiente e executar o aplicativo
ENTRYPOINT ["/bin/sh", "-c", "while IFS= read -r line; do \
    if echo \"$line\" | grep -q -E '^[^#]'; then \
        key=$(echo \"$line\" | cut -d= -f1); \
        value=$(echo \"$line\" | cut -d= -f2-); \
        export \"$key\"=\"$value\"; \
    fi; \
done < /license.env && java -Djava.security.manager=allow -jar /home/shadowtraffic.jar --config /workspace/v0_local_gen.json"]