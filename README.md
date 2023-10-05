# learning-kubernetes

## 1. Kubernetes architecture

<p align="center">
    <img src="https://github.com/nitsvutt/learning-kubernetes/blob/main/image/kubernetes-architecture-diagram.png" title="Kubernetes architecture" alt="kubernetes architecture" width=700/>
</p>

<p>
    Kubenetes cluster:
    <ul>
        <li><b>Control Plane:</b></li>
        <ul>
            <li><b>API Server:</b></li>
            <li><b>Scheduler:</b></li>
            <li><b>Controller Manager:</b></li>
            <li><b>etcd:</b></li>
        </ul>
        <li><b>Worker Node:</b></li>
        <ul>
            <li><b>Kubelet:</b></li>
            <li><b>Kube-proxy:</b></li>
            <li><b>Container Runtime:</b></li>
        </ul>
        <li><b>Container Networking Interface (CNI):</b> A framework for creating network interfaces for Containers.</li>
    </ul>
</p>