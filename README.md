# Learning Kubernetes
![license](https://img.shields.io/github/license/nitsvutt/learning-kubernetes)
![stars](https://img.shields.io/github/stars/nitsvutt/learning-kubernetes)
![forks](https://img.shields.io/github/forks/nitsvutt/learning-kubernetes)

## Table of Contents
1. [Kubernetes architecture](#architecture)
2. [How does Kubernetes work](#work)
3. [Set up Kubernetes cluster with kubeadm](#set-up)
4. [Cheat sheet](#cheat-sheet)
5. [Practice](#practice)

<div id="architecture"/>

## 1. Kubernetes architecture

<p align="center">
    <img src="https://github.com/nitsvutt/learning-kubernetes/blob/main/image/kubernetes-architecture.png" title="Kubernetes architecture" alt="kubernetes architecture" width=600/>
</p>

- **Control Plane (master):** orchestrates containers and maintains the desired state of the cluster.
    - **API Server:** works as the central hub that expose the Kubernetes API. All users and other cluster components communicate with the cluster via the API server.
    - **etcd:** is a consistent and highly-available key value store that stores all cluster data.
    - **Scheduler:** recieves pod creation requests and select the best node that satisfies the pod requirements.
    - **Controller Manager:** runs continuously and ensures that the kubernetes resource/object is in the desired state.
- **Worker Node:** runs containerized applications.
    - **Kubelet:** communicates with the API server and works with the pod specification as a daemon.
    - **kube-proxy:** maintains network rules on the node and load-balances network traffic between application components.
    - **Container Runtime:** manages the execution and lifecycle of containers within the Kubernetes environment.
- **Container Networking Interface (CNI):** creates network interfaces for containers.

<div id="work"/>

## 2. How does Kubernetes work

### 2.1. Application deployment

<p align="center">
    <img src="https://github.com/nitsvutt/learning-kubernetes/blob/main/image/kubernetes-work.png" title="Kubernetes' work" alt="kubernetes' work" width=600/>
</p>

- First, users need to package their application into one or more container images, push those images to an image registry, and then post a description of the application to the **API Server**.
- At the following stage, the **API Server** process the application's description. After that, the **Scheduler** schedule the specified groups of containers (including the desired replicas) onto the available worker nodes based on the resources required by each group and the unallocated resources on each node.
- Finnally, the **Kubelet** on those nodes then instructs the **Container Runtime** to pull the required container images and run them.
- Additional, the **Controller Manager** then keeps track and and guarantees the desired state of all containers.

### 2.2.Application development:

#### 2.2.1. ReCreate strategy:

<p align="center">
    <img src="https://github.com/nitsvutt/learning-kubernetes/blob/main/image/recreate.png" title="Recreate" alt="recreate" height=172.38/>
</p>

- With `Recreate` strategy, when making an update instruction to a deployment, the pod template of the deployment's replicaset change immediately. After that, all old pods are deleted by Kubernetes, the replicaset now have to ensure that the cluster in the desired state. As a result, new pods with new template are created and new application version is released.

#### 2.2.2. RollingUpdate strategy:

<p align="center">
    <img src="https://github.com/nitsvutt/learning-kubernetes/blob/main/image/rollingupdate.png" title="RollingUpdate" alt="rollingupdate" width=100%/>
</p>

- With `RollingUpdate` strategy, when making an update instruction to a deployment, Kubernetes create new replicaset immediately. Assume that the `maxUnavailable` property is set to `m` and the `maxSurge` is set to `n` (with `m`, `n` are integer). `m` old pod(s) will be deleted by Kubernetes and then `m+n` new pod(s) will be appended to the cluster. The process loop until the desired state of the new replicaset is ensured.

<div id="set-up"/>

## 3. Set up Kubernetes cluster with kubeadm

### 3.1. Set up SSH, vim, and cURL
- Switch to the superuser:
```
su root
```
- Install openssh-server, vim, and curl:
```
apt update
apt upgrade -y
apt install openssh-server vim curl -y
ufw allow ssh
systemctl start ssh
```

### 3.2. Set static hostname
- Master:
```
hostnamectl set-hostname master --static
```
- Worker1:
```
hostnamectl set-hostname worker1 --static
```
- Worker2:
```
hostnamectl set-hostname worker2 --static
```

### 3.3. Append ip, hostname to host file
```
vi /etc/hosts
```
```
192.168.0.105   master
192.168.0.106   worker1
192.168.0.107   worker2
```

### 3.4. Disable swap space
```
sed -i.bak -r 's/(.+ swap .+)/#\1/' /etc/fstab
swapoff -a
```

### 3.5. Add kernel modules
```
tee /etc/modules-load.d/containerd.conf <<EOF
overlay
br_netfilter
EOF
```
```
modprobe overlay
modprobe br_netfilter
```

### 3.6 Enable IP forwarding
```
tee /etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
```
```
sysctl --system
```

### 3.7. Install container runtime
- Install requirement dependencies for containerd:
```
apt install gnupg2 software-properties-common apt-transport-https ca-certificates -y
```
- Add docker repository:
```
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmour -o /etc/apt/trusted.gpg.d/docker.gpg
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
```
- Install containerd:
```
apt update
apt install containerd.io -y
```
- Configure containerd:
```
containerd config default | sudo tee /etc/containerd/config.toml >/dev/null 2>&1
sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml
```
- Start and enable containerd:
```
systemctl restart containerd
systemctl enable containerd
```

### 3.8. Install kubectl, kubelet, and kubeadm
- Add Kubernetes repository:
```
curl -fsSL  https://packages.cloud.google.com/apt/doc/apt-key.gpg|sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/k8s.gpg
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
```
- Install kubectl, kubelet, and kubeadm:
```
apt update
apt install kubelet kubeadm kubectl -y
```

### 3.9. Initialize Kubernetes cluster using kubeadm (only on master node)
- Initialize the Control Plane:
```
kubeadm init --control-plane-endpoint=master
```
- Configure kubectl:
```
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
```
- Deploy CNI:
```
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/calico.yaml
```

### 3.10. Join Kubernetes cluster (only on worker nodes)
```
kubeadm join master:6443 --token qvafpa.64eu73o0evu394ka --discovery-token-ca-cert-hash sha256:9c58e793cb9067ab131da5074cfe60eba1007ea1e5a3824d399df7310985ec80
```

<div id="cheat-sheet"/>

## 4. Cheat sheet

### 4.1. kubeadm
- Initialize the Control Plane:
```
kubeadm init --control-plane-endpoint=master
```
- Get join command:
```
kubeadm token create --print-join-command
```
- Join a Kubernetes cluster:
```
kubeadm join master:6443 --token qvafpa.64eu73o0evu394ka --discovery-token-ca-cert-hash sha256:9c58e793cb9067ab131da5074cfe60eba1007ea1e5a3824d399df7310985ec80
```
- Reset kubeadm:
```
kubeadm reset
```

### 4.2. kubectl

#### 4.2.1. kubectl get/describe
- Nodes:
```
kubectl get no
```
```
kubectl get no worker2
```
- Namespaces:
```
kubectl get ns
```
```
kubectl get ns kube-system
```
- Pods:
```
kubectl get po -A
```
```
kubectl get po -n kube-system
```
```
kubectl get po etcd-master -n kube-system
```
- Services:
```
kubectl get svc -A
```
```
kubectl get svc -n kube-system
```
```
kubectl get svc kubernetes -n kube-system
```
- PersitentVolumes:
```
kubectl get pv
```
```
kubectl get pv metadata
```
- PersitentVolumeClaims:
```
kubectl get pvc -A
```
```
kubectl get pvc -n kube-system
```
```
kubectl get pvc metadata -n kube-system
```
- Deployments:
```
kubectl get deploy -A
```
```
kubectl get deploy -n kube-system
```
```
kubectl get deploy calico-kube-controllers -n kube-system
```
- Replicasets:
```
kubectl get replicaset -A
```
```
kubectl get replicaset -n kube-system
```
```
kubectl get replicaset coredns-5dd5756b68 -n kube-system
```
> Get options:
> - `-o wide`: view more information.
> - `-o yaml`: view the description file.
> - `-l key=value`: filter with label selectors.
> 
> Describe options:
> - `-l key=value`: filter with label selectors.
#### 4.2.3. kubectl create
- Namespaces:
```
kubectl create ns todo-app
```
```
kubectl create -f ns.yaml
```
- Other resources:
```
kubectl create -f todo-app.yaml -A
```
```
kubectl create -f todo-app.yaml -n todo-app
```
> Options:
> - `-l key=value`: define label selectors.
#### 4.2.4. kubectl apply
- Namespaces:
```
kubectl apply -f ns.yaml
```
- Other resources:
```
kubectl apply -f todo-app.yaml -A
```
```
kubectl apply -f todo-app.yaml -n todo-app
```
> Note:
> - `kubectl create` and `kubectl apply` can be used to create resources interchangeably.
> - `kubectl create` does not support updating resources.
#### 4.2.5. kubectl edit
```
kubectl edit svc mysql -n todo-app
```
```
kubectl edit -f todo-app.yaml -n todo-app
```

#### 4.2.6. kubectl replace
- Namespaces:
```
kubectl replace -f ns.yaml
```
- Other resources:
```
kubectl replace -f todo-app.yaml -A
```
```
kubectl replace -f todo-app.yaml -n todo-app
```
> Note:
> - `kubectl replace` require the resource to exist.

#### 4.2.7. kubectl patch
```
kubectl patch po mysql-7bc458848f-96f4p -n todo-app -p '{"spec":{"containers":[{"name":"mysql","image":"mysql:8.1"}]}}'
```
```
kubectl patch -f mysql-deploy.yaml -n todo-app -p '{"spec":{"template":{"spec":{"containers":[{"name":"mysql","image":"mysql:8.1"}]}}}}'
```

#### 4.2.8. kubectl set image
```
kubectl set image deploy mysql -A mysql=mysql:8.1
```
```
kubectl set image deploy mysql -n todo-app mysql=mysql:8.1
```
> Options:
> - `-l key=value`: define label selectors.

#### 4.2.9. kubectl label
```
kubectl label po mysql-7bc458848f-96f4p -n todo-app dev=backend
```
```
kubectl label -f mysql-deploy.yaml -n todo-app dev=backend
```
> Options:
> - `-l key=value`: filter with label selectors.
#### 4.2.10. kubectl anotate
```
kubectl annotate deploy mysql -n todo-app kubernetes.io/change-cause='mysql:8.0 deployment'
```
```
kubectl annotate deploy mysql -n todo-app kubernetes.io/change-cause-
```
```
kubectl annotate -f mysql-deploy.yaml -n todo-app kubernetes.io/change-cause='mysql:8.0 deployment'
```
```
kubectl annotate -f mysql-deploy.yaml -n todo-app kubernetes.io/change-cause-
```
> Options:
> - `-l key=value`: filter with label selectors.
#### 4.2.11. kubectl logs
```
kubectl logs mysql-7bc458848f-96f4p -n todo-app
```
> Options:
> - `-f`: follow the logs.
> - `--tail=i`: generate last i logs.
> - `-l key=value`: filter with label selectors.
#### 4.2.12. kubectl exec
```
kubectl exec -it mysql-7bc458848f-96f4p -n todo-app bash
```
#### 4.2.13. kubectl delete
- Namespaces:
```
kubectl delete ns todo-app
```
- Other resources:
```
kubectl delete svc mysql-pv-volume -A
```
```
kubectl delete svc mysql-pv-volume -n todo-app
```
- With .yaml files:
```
kubectl delete -f todo-app.yaml -A
```
```
kubectl delete -f todo-app.yaml -n todo-app
```
> Options:
> - `-l key=value`: filter with label selectors.

#### 4.2.14. kubectl scale
```
kubectl scale deploy todo-app -n todo-app --replicas=3
```
```
kubectl scale -f todo-app.yaml -n todo-app --replicas=3
```
> Options:
> - `-l key=value`: filter with label selectors.

#### 4.2.15. kubectl rollout
```
kubectl rollout status deploy mysql -n todo-app
```
```
kubectl rollout history deploy mysql -n todo-app
```
```
kubectl rollout undo deploy mysql -n todo-app --to-revision=1
```
```
kubectl rollout pause deploy mysql -n todo-app
```
```
kubectl rollout resume deploy mysql -n todo-app
```

<div id="practice"/>

## 5. Practice

### 5.1. Overview

<p align="center">
    <img src="https://github.com/nitsvutt/learning-kubernetes/blob/main/image/example-architecture.png" title="Example architecture" alt="example architecture" width=600/>
</p>

- **Problem**: Deploy a todo web application on Kubernetes Cluster.
- **Approach**: The application contains 2 main components, a web app and a database. In this example, I use the getting-started-app on [Docker Github](https://github.com/docker/getting-started-app) to build the todo-app image and utilize the existing mysql image from [Docker Hub](https://hub.docker.com/_/mysql). In order to persist the app's data, I create a local PersistentVolume (not recommend for production) and its' PersistentVolumeClaim for mysql database usage. Finally, a ClusterIP for mysql deployment and a NodePort for the todo-app deployment are mandotory to support communication.

### 5.2. Prepare images

- Download my Dockerfile and build todo-app image:
```
git clone https://github.com/nitsvutt/learning-kubernetes.git
```
```
docker build -f learning-kubernetes/source/todo-app/prepare/Dockerfile -t nitsvutt/todo-app .
```
- Push the image to Docker Hub:
```
docker push nitsvutt/todo-app
```

### 5.3. Prepare .yaml files
- Write a .yaml file like [mysql-vol.yaml](https://github.com/nitsvutt/learning-kubernetes/blob/main/source/todo-app/db/mysql-vol.yaml) to create a PersistentVolume and a PersitentVolumeClaim.
- Write a .yaml file like [mysql-deploy.yaml](https://github.com/nitsvutt/learning-kubernetes/blob/main/source/todo-app/db/mysql-deploy.yaml) to deploy a mysql deployment and its' ClusterIP.
- Write a .yaml file like [todo-app.yaml](https://github.com/nitsvutt/learning-kubernetes/blob/main/source/todo-app/app/todo-app.yaml) to deploy a todo-app deployment and its' NodePort.

### 5.4. Deploy all necessary resources
- Move to todo-app directory:
```
cd learning-kubernetes/source/todo-app/
```
- Create todo-app namespace:
```
kubectl create ns todo-app
```
- Create mysql-pv-volume and a mysql-pv-claim through mysql-vol.yaml file:
```
kubectl apply -f db/mysql-vol.yaml -n todo-app
```
- Deploy mysql deployment and create mysql ClusterIp through mysql-deploy.yaml:
```
kubectl apply -f db/mysql-deploy.yaml -n todo-app
```
- Deploy todo-app deployment and create todo-app NodePort through todo-app.yaml:
```
kubectl apply -f todo-app.yaml -n todo-app
```

### 5.5. Enjoy your app
- Now you can enjoy your app on arbitrary machine residing in the same network with the Kubernetes Cluster through any master/workers ip with port 30000.

<p align="center">
    <img src="https://github.com/nitsvutt/learning-kubernetes/blob/main/image/todo-app-ui.png" title="todo-app UI" alt="todo-app ui" width=100%/>
</p>

- Now you may want to give RollingUpdate a try with `kubectl set image deploy mysql mysql=mysql:8.1 -n todo-app`, you can refresh the app continuously without experiencing any downtime.
