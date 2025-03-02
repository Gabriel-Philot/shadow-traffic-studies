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
kubectl create namespace deepstorage
kubectl create namespace cicd
kubectl create namespace app
kubectl create namespace management
kubectl create namespace misc
kubectl create namespace jupyter
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
kubectl apply -f minikube/manifests/database/postgres.yaml

# deep storage
kubectl apply -f minikube/manifests/deepstorage/minio.yaml
```

Por fim, instale o Spark e o Airflow, juntamente com suas permissões para executar os processos do Spark, executando os seguintes comandos:

```sh
# add & update helm list repos
helm repo add spark-operator https://kubeflow.github.io/spark-operator
helm repo add apache-airflow https://airflow.apache.org/
helm repo update
```

```sh
# processing
kubectl apply -f minikube/manifests/processing/spark.yaml
```


## Grafana [Still without metrics]
```sh
kubectl apply -f minikube/manifests/monitoring/prometheus.yaml
kubectl apply -f minikube/manifests/monitoring/grafana.yaml
#kubectl apply -f manifests/monitoring/pod-monitoring.yaml  deprecated

```
##### Remember!
```sh
# loadb -> exertnal ip for grafana web
kubectl get services --namespace monitoring

kubectl describe service prometheus-server --namespace=monitoring
# use the ip plus 80 in grafana's link data source.
```


<!-- Para criar um imagem do airflow com algumas libs inclusas, para isto execute o seguinte comando:
```sh 
eval $(minikube docker-env)
docker build -f images/airflow/dockerfile images/airflow/ -t airflow:0.1
``` -->


## Airflow

Antes de instalar o Airflow, é preciso atender a um requisito: criar um secret contendo sua `chave ssh`, para que o Airflow possa baixar as `DAGs` necessárias por meio do `gitSync`. É possível criar esse secret com o seguinte comando:

> Lembrando que você deve ter a `chave ssh` configurada em sua máquina.

> .ssh/{path-private-ssh-key-on-computer}


### change github -> orchestrator/airflow.yaml repo
```sh
kubectl create secret generic airflow-ssh-secret --from-file=gitSshKey=$HOME/.ssh/{path-private-ssh-key-on-computer} -n orchestrator

# example
kubectl create secret generic airflow-ssh-secret --from-file=gitSshKey=$HOME/.ssh/id_ed25519 -n orchestrator
```

```sh
# orchestrator
kubectl apply -f minikube/manifests/orchestrator/airflow.yaml
```

Em seguida, instale as configurações de acesso:
### change github -> anifests/misc/access-control.yaml repo

```sh
kubectl apply -f minikube/manifests/misc/access-control.yaml
```

Para que seja possivel o Ariflow executar de maneira independente os processos spark é preciso que ele tenha uma conexão com o cluster, e para isto é necessario passar essa informação ao Airflow. Para adicionar a conexão com o cluster ao Airflow execute:



```sh
kubectl get pods --no-headers -o custom-columns=":metadata.name" -n orchestrator | grep scheduler | xargs -i sh -c 'kubectl cp images/airflow/connections.json orchestrator/{}:./ -c scheduler | kubectl -n orchestrator exec {} -- airflow connections import connections.json'
```
> [!WARNING] 
Sneaky cp path, care with the env->images path that will be used above


<!-- export SCHEDULER_POD_NAME="$(kubectl get pods --no-headers -o custom-columns=":metadata.name" -n orchestrator | grep scheduler)"
kubectl cp images/airflow/connections.json orchestrator/$SCHEDULER_POD_NAME:./ -c scheduler
kubectl -n orchestrator exec $SCHEDULER_POD_NAME -- airflow connections import connections.json -->


Ótimo, agora que você configuro u as ferramentas necessárias, temos o ambiente de desenvolvimento e de execução instalado e pronto para uso.

# Executando o projeto
<!--

## Solved but dont know why:

* Reminder: 
DAGS_FOLDER_PATH = path.dirname(__file__) in K8podOperator task.
-->

```sh
# ingestion image
eval $(minikube docker-env)
docker build --no-cache -f images/python_ingestion/dockerfile images/python_ingestion/ -t gabrielphilot/brewapi-ingestion-minio:0.1

# here dont forget if change this name, change it into dags yamls

# for cloud deploy this image should be pushed into a repo.
```
try later to push from docker repo.

<!-- old version
eval $(minikube docker-env)
docker build --no-cache -f images/python/dockerfile images/python/ -t python_image:0.2
-->

>[!Note] 
One way the debug your deploy of a pod.

dúvida como fazer isso de uma forma melhor ?? debugar com o K8?

```sh
# ir até o path da do yaml
kubectl apply -f brewapi_ingestion.yaml -n orchestrator

kubectl logs brewapi-ingestion-minio -n orchestrator -c python-container
```


try later to push from docker repo.


é necessário possuir uma `imagem do Spark` que contenha todos os JARs necessários para a execução do nosso pipeline. Para criar uma imagem do Spark com essas especificações, execute:

```sh
# first test
eval $(minikube docker-env)
docker build --no-cache -f images/spark_brewery/dockerfile images/spark_brewery/ -t gabrielphilot/brew-process-spark-delta:0.2
```
remind to change it in to dags spark_jobs yamls.


## Acess airflow and check the admin/connections
```sh
kubectl get services -n orchestrator -l component=webserver,argocd.argoproj.io/instance=airflow -o jsonpath="{.items[0].status.loadBalancer.ingress[0].ip}"
```
this adress + :8080 

login/pass : admin

[!!!!! ADPTAR IDEI!!!!!]
Uma vez na interface do Airflow, ative o pipeline de dados `pipeline-delta-lake-deep-dive-complete` e veja a mágica acontecer. Ou, se preferir, você também pode executar cada etapa separadamente, seguindo a sequência:
  * `ingestion-from-local-data-file-to-bronze-tables`
  * `transformation-and-enrichment-from-bronze-to-silver`
  * `delivery-data-from-silver-to-gold`

Caso não deseje executar o pipeline pelo Airflow, você pode executar o pipeline de dados executando os seguintes comandos em sequência:
```sh
kubectl apply -f dags/spark_jobs/ingestion_from_local_data_file_to_bronze_tables.yaml -n processing
kubectl apply -f dags/spark_jobs/transform_and_enrichment_from_bronze_to_silver.yaml -n processing
kubectl apply -f dags/spark_jobs/delivery_data_from_silver_to_gold.yaml -n processing
```
Para verificar os arquivos no `data lakehouse`, acesse a interface web do `MinIO` e use as credenciais de acesso encontradas no arquivo *[minio-secrets.yaml](/secrets/minio-secrets.yaml)* na pasta *[secrets](/secrets/)*. Caso não saiba o IP atribuído ao MinIO, execute:

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

<!--
#### comandos v atual

```sh
### versão ruim
kubectl port-forward svc/custom-jupyter -n jupyter 8888:8888


kubectl get pods -n jupyter

kubectl logs jupyter-admin -n jupyter | grep token

kubectl exec -it $(kubectl get pods -n jupyter -l app=custom-jupyter -o jsonpath='{.items[0].metadata.name}') -n jupyter -- jupyter server list

####
token -> vai aparecer
```
-->

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