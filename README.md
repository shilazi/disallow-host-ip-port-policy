# disallow-host-ip-port-policy

Disallow `hostIP` or/and `hostPort` was set

## Build

```bash
make
```

## Usage

1. Upload `disallow-host-ip-port-policy-v1.0.0.wasm` to static server
2. Generate `ClusterAdmissionPolicy` manifest
    ```yaml
    apiVersion: policies.kubewarden.io/v1alpha2
    kind: ClusterAdmissionPolicy
    metadata:
      name: disallow-host-ip-port-policy
    spec:
      module: https://your.server/kubewarden/policies/disallow-host-ip-port-policy-v1.0.0.wasm
      rules:
      - apiGroups: [""]
        apiVersions: ["v1"]
        resources: ["pods"]
        operations: ["CREATE"]
      - apiGroups: [""]
        apiVersions: ["v1"]
        resources: ["replicationcontrollers"]
        operations: ["CREATE", "UPDATE"]
      - apiGroups: ["apps"]
        apiVersions: ["v1"]
        resources: ["daemonsets", "deployments", "replicasets", "statefulsets"]
        operations: ["CREATE", "UPDATE"]
      - apiGroups: ["batch"]
        apiVersions: ["v1", "v1beta1"]
        resources: ["jobs", "cronjobs"]
        operations: ["CREATE", "UPDATE"]
      mutating: false
      settings:
        # exempt with service account by username
        exempt_users:
        - kubernetes-admin
        # exempt with Namespace
        exempt_namespaces:
        - kube-system
    ```
3. Apply with kubectl
   ```bash 
   kubectl apply -f disallow-host-ip-port-policy.yml
   ```

## Validation

Example pod manifest:

```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  containers:
  - image: nginx
    name: nginx
    ports:
    - name: t80
      containerPort: 80
      hostIP: 127.0.0.1
      hostPort: 80
EOF
```

With exempt:

```
$ kubectl get po
NAME   READY   STATUS             RESTARTS   AGE
nginx  1/1     Running            0          15s
```

```
accepting Pod with exemption data={"column":5,"file":"src/lib.rs","line":58,"policy":"disallow-host-ip-port-policy"}
```

Without exempt:

```
Error from server: error when creating "pod.yml": admission webhook "disallow-host-ip-port-policy.kubewarden.admission" denied the request: Container run with hostIP or/and hostPort is not allowed
```
