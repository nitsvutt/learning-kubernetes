# learning-kubernetes

## Table of Contents
1. [Kubernetes architecture](#architecture)
2. [How does Kubernetes work](#work)
3. [Set up Kubernetes cluster with kubeadm](#set-up)
4. [Cheat sheet](#cheat-sheet)

<div id="architecture"/>

## 1. Kubernetes architecture

<p align="center">
    <img src="https://github.com/nitsvutt/learning-kubernetes/blob/main/image/kubernetes-architecture.png" title="Kubernetes architecture" alt="kubernetes architecture" width=700/>
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

<p align="center">
    <img src="https://github.com/nitsvutt/learning-kubernetes/blob/main/image/kubernetes-work.png" title="Kubernetes' work" alt="kubernetes' work" width=700/>
</p>

- First, users need to package their application into one or more container images, push those images to an image registry, and then post a description of the application to the **API Server**.
- At the following stage, the **API Server** process the application's description. After that, the **Scheduler** schedule the specified groups of containers (including the desired replicas) onto the available worker nodes based on the resources required by each group and the unallocated resources on each node.
- Finnally, the **Kubelet** on those nodes then instructs the **Container Runtime** to pull the required container images and run them.
- Additional, the **Controller Manager** then keeps track and and guarantees the desired state of all containers.

<div id="set-up"/>

## 3. Set up Kubernetes cluster with kubeadm

### 3.1. Set up SSH, vim, and cURL:
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

### 3.2. Set static hostname:
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

### 3.3. Append ip, hostname to host file:
```
vi /etc/hosts
```
```
192.168.0.105   master
192.168.0.106   worker1
192.168.0.107   worker2
```

### 3.4. Disable swap space:
```
sed -i.bak -r 's/(.+ swap .+)/#\1/' /etc/fstab
swapoff -a
```

### 3.5. Add kernel modules:
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

### 3.6 Enable IP forwarding:
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

### 3.7. Install container runtime:
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

### 3.8. Install kubectl, kubelet, and kubeadm:
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

### 3.9. Initialize Kubernetes cluster using kubeadm (only on master node):
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

### 3.10. Join Kubernetes cluster (only on worker nodes):
```
kubeadm join master:6443 --token qvafpa.64eu73o0evu394ka --discovery-token-ca-cert-hash sha256:9c58e793cb9067ab131da5074cfe60eba1007ea1e5a3824d399df7310985ec80
```

<div id="cheat-sheet"/>

## 4. Cheat sheet:

### 4.1. kubeadm:
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

### 4.2. kubectl:

#### 4.2.1. kubectl get/describe:
- Nodes:
```
kubectl get no
```
```
kubectl get no worker3
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
> Get options:
> - `-o wide`: view more information.
> - `-o yaml`: view the description file.
> - `-l key=value`: filter with label selectors.
> 
> Describe options:
> - `-l key=value`: filter with label selectors.
#### 4.2.3. kubectl create:
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
#### 4.2.4. kubectl apply:
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
#### 4.2.5. kubectl edit:
```
kubectl edit svc/mysql -n todo-app
```
```
kubectl edit -f todo-app.yaml -n todo-app
```
#### 4.2.6. kubectl label:
```
kubectl label po mysql-7bc458848f-96f4p -n todo-app dev=backend
```
```
kubectl label -f mysql-deploy.yaml -n todo-app dev=backend
```
> Options:
> - `-l key=value`: filter with label selectors.
#### 4.2.7. kubectl anotate:
```
kubectl annotate svc mysql -n todo-app description='this is the entrypoint of mysql'
```
```
kubectl annotate svc mysql -n todo-app description-
```
```
kubectl annotate -f mysql-deploy.yaml -n todo-app overview='this is mysql deployment'
```
```
kubectl annotate -f mysql-deploy.yaml -n todo-app overview-
```
> Options:
> - `-l key=value`: filter with label selectors.
#### 4.2.8. kubectl logs:
```
kubectl logs mysql-7bc458848f-96f4p -n todo-app
```
> Options:
> - `-f`: follow the logs.
> - `--tail=i`: generate last i logs.
> - `-l key=value`: filter with label selectors.
#### 4.2.9. kubectl exec:
```
kubectl exec -it mysql-7bc458848f-96f4p -n todo-app bash
```
#### 4.2.10. kubectl delete:
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