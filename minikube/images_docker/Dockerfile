# Usar a imagem base do ShadowTraffic
FROM shadowtraffic/shadowtraffic:latest

# Instrução para usar variáveis de ambiente no ShadowTraffic
ENV LICENSE_ID=$LICENSE_ID
ENV LICENSE_EMAIL=$LICENSE_EMAIL
ENV LICENSE_ORGANIZATION=$LICENSE_ORGANIZATION
ENV LICENSE_EDITION=$LICENSE_EDITION
ENV LICENSE_EXPIRATION=$LICENSE_EXPIRATION
ENV LICENSE_SIGNATURE=$LICENSE_SIGNATURE
ENV AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
ENV AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
ENV AWS_REGION=$AWS_REGION

# Comando de entrada, garantindo que as variáveis sejam usadas
CMD ["shadowtraffic", "--config", "/workspace/v0_local_gen_minio.json"]