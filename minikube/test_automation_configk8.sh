#!/bin/bash

# Exit on error
set -e

# Color codes for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
print_section() {
    echo -e "${BLUE}===================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}===================================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

wait_for_pod_ready() {
    namespace=$1
    label=$2
    echo -e "Waiting for pods with label $label in namespace $namespace to be ready..."
    
    while [[ $(kubectl get pods -n $namespace -l $label -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do
        echo -n "."
        sleep 3
    done
    echo
    print_success "Pod is ready!"
}

wait_for_loadbalancer_ip() {
    namespace=$1
    label=$2
    echo -e "Waiting for LoadBalancer IP for service with label $label in namespace $namespace..."
    
    while [[ -z $(kubectl get services -n $namespace -l $label -o jsonpath="{.items[0].status.loadBalancer.ingress[0].ip}") ]]; do
        echo -n "."
        sleep 3
    done
    echo
    print_success "LoadBalancer IP is ready!"
}

# Assuming minikube is already running
print_success "Minikube is assumed to be running with tunnel active"

print_section "Creating necessary namespaces"
kubectl create namespace orchestrator 2>/dev/null || echo "Namespace orchestrator already exists"
kubectl create namespace deepstorage 2>/dev/null || echo "Namespace deepstorage already exists"
kubectl create namespace cicd 2>/dev/null || echo "Namespace cicd already exists"
kubectl create namespace app 2>/dev/null || echo "Namespace app already exists"
kubectl create namespace management 2>/dev/null || echo "Namespace management already exists"
kubectl create namespace misc 2>/dev/null || echo "Namespace misc already exists"
kubectl create namespace jupyter 2>/dev/null || echo "Namespace jupyter already exists"
kubectl create namespace processing 2>/dev/null || echo "Namespace jupyter already exists"
kubectl create namespace datagen 2>/dev/null || echo "Namespace datagen already exists"

print_section "Installing ArgoCD"
echo "Installing ArgoCD with Helm..."
helm install argocd argo/argo-cd --namespace cicd --version 5.27.1 || echo "ArgoCD already installed or error occurred"

echo "Patching ArgoCD server service to use LoadBalancer..."
kubectl patch svc argocd-server -n cicd -p '{"spec": {"type": "LoadBalancer"}}'

print_section "Waiting for ArgoCD to be ready"
wait_for_pod_ready "cicd" "app.kubernetes.io/name=argocd-server"
wait_for_loadbalancer_ip "cicd" "app.kubernetes.io/name=argocd-server"

# Store ArgoCD LoadBalancer IP
ARGOCD_LB=$(kubectl get services -n cicd -l app.kubernetes.io/name=argocd-server -o jsonpath="{.items[0].status.loadBalancer.ingress[0].ip}")
print_success "ArgoCD LoadBalancer IP: $ARGOCD_LB"

# Get ArgoCD admin password
ARGOCD_PASSWORD=$(kubectl get secret argocd-initial-admin-secret -n cicd -o jsonpath="{.data.password}" | base64 -d)
print_success "ArgoCD admin password: $ARGOCD_PASSWORD"

echo "ArgoCD web interface available at: http://$ARGOCD_LB"

# Assuming minikube tunnel is already running
print_success "Minikube tunnel is assumed to be running in another terminal"

print_section "Adding Git repository to ArgoCD"
echo "Logging into ArgoCD..."
kubectl get secret argocd-initial-admin-secret -n cicd -o jsonpath="{.data.password}" | base64 -d | xargs -t -I {} argocd login $ARGOCD_LB --username admin --password {} --insecure

echo "Adding repository to ArgoCD..."
argocd repo add git@github.com:Gabriel-Philot/shadow-traffic-studies.git --ssh-private-key-path ~/.ssh/id_ed25519 --insecure-skip-server-verification

print_success "Repository added to ArgoCD"

print_section "Setting up Reflector for secret management"
kubectl apply -f manifests/management/reflector.yaml

print_warning "Waiting for Reflector to be deployed (30 seconds)..."
sleep 30

print_section "Setting up Secrets"
kubectl apply -f manifests/misc/secrets.yaml

print_warning "Waiting for Secrets to be processed (10 seconds)..."
sleep 10

print_section "Setting up Acess control"
kubectl apply -f access-control/crb-jupyter.yaml

print_warning "Waiting for Acess control to be processed (10 seconds)..."
sleep 10

print_section "Setting up MinIO Storage"
kubectl apply -f manifests/deepstorage/minio.yaml

print_warning "Waiting for MinIO to be deployed (45 seconds)..."
sleep 45

print_section "Building and deploying ShadowTraffic data generator"

# Switch to minikube's Docker environment
eval $(minikube docker-env)

echo "Building ShadowTraffic Docker image..."
docker build --no-cache -f images_docker/datagenShadow/Dockerfile -t shadowtraffic-datagen:latest .

echo "Deploying ShadowTraffic components..."
kubectl apply -f manifests/datagen/generator-secrets.yaml
kubectl apply -f manifests/datagen/shadowtraffic-config.yaml
kubectl apply -f manifests/datagen/shadowtraffic-deployment.yaml

wait_for_pod_ready "datagen" "app=shadowtraffic"

print_section "Getting access credentials"

# Get MinIO LoadBalancer IP
MINIO_LB=$(kubectl get services -n deepstorage -l app.kubernetes.io/name=minio -o jsonpath="{.items[0].status.loadBalancer.ingress[0].ip}")
MINIO_USER=$(kubectl get secret minio-secrets -n deepstorage -o jsonpath="{.data.root-user}" | base64 -d)
MINIO_PASSWORD=$(kubectl get secret minio-secrets -n deepstorage -o jsonpath="{.data.root-password}" | base64 -d)

print_success "Setup Complete!"
echo "================ SERVICE ACCESS INFORMATION ================"
echo "ArgoCD:"
echo "  URL: http://$ARGOCD_LB"
echo "  Username: admin"
echo "  Password: $ARGOCD_PASSWORD"
echo ""
echo "MinIO:"
echo "  URL: http://$MINIO_LB:9000"
echo "  Username: $MINIO_USER"
echo "  Password: $MINIO_PASSWORD"

print_success "Git repository has been configured in ArgoCD"

echo "To check the ShadowTraffic generator status, run:"
echo "kubectl get pods -n datagen"

# Return to the original Docker environment
eval $(minikube docker-env -u)