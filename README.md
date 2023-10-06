# learning-kubernetes

## 1. Kubernetes architecture

<p align="center">
    <img src="https://github.com/nitsvutt/learning-kubernetes/blob/main/image/kubernetes-architecture-diagram.png" title="Kubernetes architecture" alt="kubernetes architecture" width=700/>
</p>

<p>
    <ul>
        <li><b>Control Plane:</b> orchestrates containers and maintains the desired state of the cluster.</li>
        <ul>
            <li><b>API Server:</b> works as the central hub that expose the Kubernetes API. All users and other cluster components communicate with the cluster via the API server.</li>
            <li><b>Scheduler:</b> recieves pod creation requests and select the best node that satisfies the pod requirements.</li>
            <li><b>Controller Manager:</b> runs continuously and ensures that the kubernetes resource/object is in the desired state.</li>
            <li><b>etcd:</b> is a consistent and highly-available key value store that stores all cluster data.</li>
        </ul>
        <li><b>Worker Node:</b> runs containerized applications.</li>
        <ul>
            <li><b>Kubelet:</b> communicates with the API server and works with the pod specification as a daemon.</li>
            <li><b>Kube-proxy:</b> maintains network rules on the node and load-balances network traffic between application components.</li>
            <li><b>Container Runtime:</b> manages the execution and lifecycle of containers within the Kubernetes environment.</li>
        </ul>
        <li><b>Container Networking Interface (CNI):</b> creates network interfaces for containers.</li>
    </ul>
</p>

## 2. Set up Kubernetes cluster with kubeadm

### 2.1. Set up SSH, vim, and cURL:
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

### 2.2. Set static hostname:
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

### 2.3. Append ip, hostname to host file:
```
vi /etc/hosts
```
```
192.168.0.105   master
192.168.0.106   worker1
192.168.0.107   worker2
```

### 2.4. Disable swap space:
```
sed -i.bak -r 's/(.+ swap .+)/#\1/' /etc/fstab
swapoff -a
```

### 2.5. Add kernel modules:
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