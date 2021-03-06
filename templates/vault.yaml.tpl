apiVersion: v1
kind: ConfigMap
metadata:
  name: vault
data:
  vault.json: |-
    storage "swift" {
      auth_url  = "${os_auth_url}"
      username  = "${os_username}"
      tenant    = "${os_project}"
      password  = "${os_password}"
      container = "${container}"
    }
    listener "tcp" {
     address = "0.0.0.0:8200"
     cluster_address = "0.0.0.0:8201"
     tls_disable = 1
    }
---
apiVersion: v1
kind: Service
metadata:
  name: vault
  labels:
    app: vault
spec:
  ports:
    - port: 8200
  selector:
    app: vault
  type: NodePort
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: vault
  labels:
    app: vault
spec:
  replicas: 3
  selector:
    matchLabels:
      app: vault
  template:
    metadata:
      labels:
        app: vault
    spec:
      containers:
      - name: vault-server
        image: vault:0.9.1
        args: [ "server" ]
        securityContext:
          capabilities:
            add: ["IPC_LOCK"]
        env:
          - name: VAULT_LOCAL_CONFIG
            valueFrom:
              configMapKeyRef:
                name: vault
                key: vault.json
        ports:
        - containerPort: 8200
        - containerPort: 8201
