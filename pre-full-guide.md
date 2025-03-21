```sh
minikube start --memory=8000 --cpus=2
```

Para acessar alguns serviços via loadbalancer no Minikube, é necessário utilizar o [tunelamento do minikube](https://minikube.sigs.k8s.io/docs/handbook/accessing/#example-of-loadbalancer). Para isso, abra uma nova aba no seu terminal e execute o seguinte comando:
```sh
minikube tunnel
```

## Instalação das ferramentas

Depois do ambiente inicializado será necessario instalar algumas aplicações que serão responsaveis por manter e gerenciar nosso pipeline de dados.

Estando conectado em um cluster Kubernetes, execute os seguintes comandos para criar todos os namespaces necessarios:

```sh
kubectl create namespace orchestrator
kubectl create namespace processing
kubectl create namespace deepstorage
kubectl create namespace cicd
kubectl create namespace app
kubectl create namespace management
kubectl create namespace misc
kubectl create namespace jupyter
kubectl create namespace datagen
```

Instale o argocd que será responsavel por manter nossas aplicações:
```sh
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
helm install argocd argo/argo-cd --namespace cicd --version 5.27.1
```

Altere o service do argo para loadbalancer:
```sh
# create a load balancer
kubectl patch svc argocd-server -n cicd -p '{"spec": {"type": "LoadBalancer"}}'
```

Em seguida instale o argo cli para fazer a configuração do repositorio:
```sh
sudo curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo chmod +x /usr/local/bin/argocd
```
Em seguida armazene o ip atribiudo para acessar o argo e faça o login no argo, com os seguintes comandos:
```sh
ARGOCD_LB=$(kubectl get services -n cicd -l app.kubernetes.io/name=argocd-server,app.kubernetes.io/instance=argocd -o jsonpath="{.items[0].status.loadBalancer.ingress[0].ip}")

# get password to log into argocd portal
# argocd login 192.168.0.200 --username admin --password UbV0FdJ2ZNCD8kxU --insecure
kubectl get secret argocd-initial-admin-secret -n cicd -o jsonpath="{.data.password}" | base64 -d | xargs -t -I {} argocd login $ARGOCD_LB --username admin --password {} --insecure
```
> [!WARNING] 
Here, the tunnel kernel will probably ask for sudo permission.



Uma vez feita a autenticação não é necessario adicionar um cluster, pois o argo esta configurado para usar o cluster em que ele esta instalado, ou seja, o cluster local ja esta adicionado como **`--in-cluster`**, bastando apenas adicionar o seu repositorio com o seguinte comando:

### Creating ssh key
```sh
# exemple
ssh-keygen -t ed25519 -C "seu-email@example.com"  

cat ~/.ssh/id_ed25519.pub

```

argocd repo add git@github.com:Gabriel-Philot/K8-Brewery_API-Upgrade.git --ssh-private-key-path ~/..ssh/id_ed25519.pub --insecure-skip-server-verification

then paste it on github new ssh key.

```sh

argocd repo add git@github.com:Gabriel-Philot/{repo-path}.git --ssh-private-key-path ~/.ssh/{path-private-ssh-key-on computer} --insecure-skip-server-verification

#example
argocd repo add git@github.com:Gabriel-Philot/shadow-traffic-studies.git --ssh-private-key-path ~/.ssh/id_ed25519 --insecure-skip-server-verification
```


>[!NOTE] 
caso queira ver o password do argo para acessar a interface web execute este comando: `kubectl get secret argocd-initial-admin-secret -n cicd -o jsonpath="{.data.password}" | base64 -d`


> [!WARNING] 
Lembrando que para este comando funcionar é necessario que você tenha uma `chave ssh` configurada para se conectar com o github no seu computador.

Para acessar o argocd pelo IP gerado no Loadbalancer execute o comando:

```sh
echo http://$ARGOCD_LB
```

Uma vez que tenha acessado a pagina de autenticação do argocd use o `username` admin e o password gerado na instalação do argocd, executando o comando:

```sh
kubectl get secret argocd-initial-admin-secret -n cicd -o jsonpath="{.data.password}" | base64 -d
```

## Aqui o reflector armazena as secrets basicamente e distribui entre diferentes namespaces

```sh
kubectl apply -f minikube/manifests/management/reflector.yaml
```

Antes de executar os comandos, você pode alterar os secrets dos arquivos localizados na pasta `secrets/` se quiser mudar as senhas de acesso aos bancos de dados e ao storage.

Após o Reflector estar funcionando, execute o comando que cria os secrets nos namespaces necessários:

>[!NOTE] 
> Reflector uses various access control methods and secrets to point to the repository containing the actual access configurations. It reads the file and retrieves its path.

In this setup, we can modify the values in config.json (located at images/airflow/connections.json), but it's also necessary to update the corresponding secrets in minio-secrets.yaml and postgress-secrets.yaml. Be cautious with the Base64 encryption used in these files.

>[!Warning] 
> Watch the airflow.yaml file (line 50). If you change the keys, you'll need to update them there as well.

### alterar github -> manifests/misc/secrets.yaml
```sh
# secrets
kubectl apply -f minikube/manifests/misc/secrets.yaml
```

>[!NOTE] 
Caso não queira instalar o Reflactor para automatizar o processo de criar o secret em vários namespaces diferentes, você pode replicar manualmente o secret para outro namespace executando este comando:


[CASO NAO TENHA USADO O REFLECTOR]
- kubectl get secret minio-secrets -n deepstorage -o yaml | sed s/"namespace: deepstorage"/"namespace: processing"/| kubectl apply -n processing -f


Uma vez que os secrets estejam configurados, é possível instalar os bancos de dados e o storage do pipeline de dados com o seguinte comando:

```sh
# databases
!!! OFF HERE kubectl apply -f minikube/manifests/database/postgres.yaml !!! OFF HERE

# deep storage
kubectl apply -f minikube/manifests/deepstorage/minio.yaml
```

# Executando o projeto

```sh
# shadowtraffic-img
eval $(minikube docker-env)
docker build --no-cache -f minikube/images_docker/Dockerfile -t shadowtraffic-datagen:latest .
```
```bash
# Aplicar o secret com informações de licença
kubectl apply -f minikube/manifests/datagen/generator-secrets.yaml
```

```bash
# Aplicar o ConfigMap com a configuração
kubectl apply -f minikube/manifests/datagen/shadowtraffic-config.yaml
```

```bash
# Aplicar o Deployment
kubectl apply -f minikube/manifests/datagen/shadowtraffic-deployment.yaml
```
```bash
# Verificar se o pod está em execução
kubectl get pods -n datagen
```

##### All in one
```bash
kubectl apply -f minikube/manifests/datagen/generator-secrets.yaml
kubectl apply -f minikube/manifests/datagen/shadowtraffic-config.yaml
kubectl apply -f minikube/manifests/datagen/shadowtraffic-deployment.yaml
```
## to delete all too
```bash
kubectl delete deployment shadowtraffic -n datagen 
kubectl delete configmap shadowtraffic-config -n datagen 
kubectl delete secret generator-secrets -n datagen 
```


Para verificar os arquivos no `data lake`, acesse a interface web do `MinIO` e use as credenciais de acesso encontradas no arquivo *[minio-secrets.yaml](/secrets/minio-secrets.yaml)* na pasta *[secrets](/secrets/)*. Caso não saiba o IP atribuído ao MinIO, execute:

## geting miniO port

```sh
kubectl get services -n deepstorage -l app.kubernetes.io/name=minio -o jsonpath="{.items[0].status.loadBalancer.ingress[0].ip}"
```
+9000

Caso queira obter as credenciais de acesso do `MinIO`, execute:
```sh
echo "user: $(kubectl get secret minio-secrets -n deepstorage -o jsonpath="{.data.root-user}" | base64 -d)"
echo "password: $(kubectl get secret minio-secrets -n deepstorage -o jsonpath="{.data.root-password}" | base64 -d)"
```

check out the dag in airflow UI + logs, and the files at MiniO.


## Jupyter-notebook [acessing the data]
```sh
# Building image

eval $(minikube docker-env)
docker build --no-cache -f images/custom_jupyterlab/dockerfile images/custom_jupyterlab/ -t gabrielphilot/custom_jupyterlab:0.1
```

```sh
# notebook
kubectl apply -f minikube/manifests/notebook/jup-notebook.yaml
```


#### Need to nhance the token part but its ok.

```sh
# versão atual

# external-ip 
kubectl get svc -n jupyter

# get token
kubectl exec -it $(kubectl get pods -n jupyter -l app=custom-jupyter -o jsonpath='{.items[0].metadata.name}') -n jupyter -- jupyter server list

```

## Web interface
```
link = {external-ip} + 8888

then use token in login page

```

------
--- new part ------

cd minikube


### Notebook
eval $(minikube docker-env)
docker build -t jupyter:latest -f images_docker/jupyter-spark/Dockerfile images_docker/jupyter-spark/

kubectl apply -f manifests/jupyter-spark/jupyter-app.yaml

kubectl exec -it $(kubectl get pods -n jupyter -l app=custom-jupyter -o jsonpath='{.items[0].metadata.name}') -n jupyter -- jupyter server list



./scripts-bash/automation_config_k8.sh

### SPOK
kubectl apply -f manifests/processing/spark-operator.yaml
kubectl apply -f access-control/crb-spok.yaml 

 
./scripts-bash/upload-script-spark.sh
dont forget to change here the send of main.py to bucket

eval $(minikube docker-env)
docker build -t custom-spark:latest -f images_docker/spok-plus-modules/Dockerfile images_docker/spok-plus-modules/

kubectl apply -f spark-jobs/spark-job-modules-test.yaml
here aways pay attention for the path/file name in bashupload script main.py to bucket 

utils
docker rmi -f custom-spark:latest
