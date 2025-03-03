#!/bin/bash

# Install MinIO client if not already installed
if ! command -v mc &> /dev/null; then
    echo "Installing MinIO client..."
    wget https://dl.min.io/client/mc/release/linux-amd64/mc
    chmod +x mc
    sudo mv mc /usr/local/bin/
fi

# Configure MinIO client
mc alias set minikube-minio http://10.108.217.62:9000 miniouser miniosecret

# List buckets to verify connection
echo "Testing connection to MinIO..."
mc ls minikube-minio

# Check if landing bucket exists, create if it doesn't
if ! mc ls minikube-minio/landing &> /dev/null; then
    echo "Creating landing bucket..."
    mc mb minikube-minio/landing
fi

echo "Connection test complete!"