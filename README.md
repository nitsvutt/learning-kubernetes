# learning-kubernetes

## Table of Contents
1. [Kubernetes architecture](#architecture)
2. [How does Kubernetes work](#work)
3. [Set up Kubernetes cluster with kubeadm](#set-up)

<div id="architecture"/>

## 1. Kubernetes architecture

<p align="center">
    <img src="https://github.com/nitsvutt/learning-kubernetes/blob/main/image/kubernetes-architecture.png" title="Kubernetes architecture" alt="kubernetes architecture" width=600/>
</p>

- **Control Plane:** orchestrates containers and maintains the desired state of the cluster.
    - **API Server:** works as the central hub that expose the Kubernetes API. All users and other cluster components communicate with the cluster via the API server.
    - **Scheduler:** recieves pod creation requests and select the best node that satisfies the pod requirements.
    - **Controller Manager:** runs continuously and ensures that the kubernetes resource/object is in the desired state.
    - **etcd:** is a consistent and highly-available key value store that stores all cluster data.
- **Worker Node:** runs containerized applications.
    - **Kubelet:** communicates with the API server and works with the pod specification as a daemon.
    - **Kube-proxy:** maintains network rules on the node and load-balances network traffic between application components.
    - **Container Runtime:** manages the execution and lifecycle of containers within the Kubernetes environment.
    - **Container Networking Interface (CNI):** creates network interfaces for containers.

<div id="work"/>

## 2. How does Kubernetes work

<p align="center">
    <img src="https://github.com/nitsvutt/learning-kubernetes/blob/main/image/kubernetes-work.png" title="Kubernetes' work" alt="kubernetes' work" width=600/>
</p>

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
containerd config default | sudo tee /etc/containerd/config.toml >/dev/null 2>&1
sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml
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
- Initialize:
```
kubeadm init --control-plane-endpoint=master
```
- Configure kubectl:
```
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```
- Deploy CNI:
```
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/calico.yaml
```

### 3.10. Join Kubernetes cluster (only on worker node):
```
kubeadm join master:6443 --token kw3rku.qgibpx77dv1fzq33 --discovery-token-ca-cert-hash sha256:4f88b416dee4c7d777d76640e8fea03b628f355f90d01bc4c29d59d31b704a00
```