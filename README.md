# learning-kubernetes

## 1. Kubernetes architecture

<p align="center">
    <img src="https://github.com/nitsvutt/learning-kubernetes/blob/main/image/kubernetes-architecture-diagram.png" title="Kubernetes architecture" alt="kubernetes architecture" width=700/>
</p>

<p>
    <b>Kubenetes components:</b>
    <ul>
        <li><b>Control Plane:</b> orchestrates containers and maintains the desired state of the cluster.</li>
        <ul>
            <li><b>API Server:</b> works as the central hub that expose the Kubernetes API. All users and other cluster components talk to the cluster via the API server.</li>
            <li><b>Scheduler:</b> recieves pod creation requests and select the best node that satisfies the pod requirements.</li>
            <li><b>Controller Manager:</b> runs continuously and ensures that the kubernetes resource/object is in the desired state.</li>
            <li><b>etcd:</b> is a consistent and highly-available key value store that stores all cluster data.</li>
        </ul>
        <li><b>Worker Node:</b></li>
        <ul>
            <li><b>Kubelet:</b></li>
            <li><b>Kube-proxy:</b></li>
            <li><b>Container Runtime:</b></li>
        </ul>
        <li><b>Container Networking Interface (CNI):</b> creates network interfaces for containers.</li>
    </ul>
</p>