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
- Worker3:
```
hostnamectl set-hostname worker3 --static
```

### 3.3. Append ip, hostname to host file:
```
vi /etc/hosts
```
```
192.168.0.105   master
192.168.0.106   worker1
192.168.0.107   worker2
192.168.0.108   worker3
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

### 4.2.1. kubectl get:
- Get nodes:
```
kubectl get nodes
```
```
kubectl get node worker3
```
- Get pods:
```
kubectl get pods -A
```
```
kubectl get pods --namespace kube-system
```
```
kubectl get pod etcd-master --namespace kube-system
```
- Get services:
```
kubectl get services
```
- Options:
    - `-o wide` to see more information.
    - `-o yaml` to get the description file.
    - `--field-selector key:value` to get which matching specified selectors.