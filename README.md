# learning-kubernetes

## 1. Kubernetes architecture

<p align="center">
    <img src="https://github.com/nitsvutt/learning-kubernetes/blob/main/image/kubernetes-architecture-diagram.png" title="Kubernetes architecture" alt="kubernetes architecture" width=700/>
</p>

<p>
    Kubenetes cluster:
    <ul>
        <li>Control Plane:</li>
        <ul>
            <li>API Server</li>
            <li>Scheduler</li>
            <li>Controller Manager</li>
            <li>etcd</li>
        </ul>
        <li>Worker Node:
        <ul>
            <li>Kubelet</li>
            <li>Kube Proxy</li>
            <li>Container Runtime</li>
        </ul>
    </ul>
</p>