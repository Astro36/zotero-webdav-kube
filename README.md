# Zotero WebDAV for Kubernetes

This guide explains how to deploy a self-hosted Zotero WebDAV server on a lightweight Kubernetes (K3s) cluster.

## (Option) Install K3s

Run the following command to install K3s:

```sh
curl -sfL https://get.k3s.io | sh -
```

Configure access to the cluster:

```sh
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config
chmod 600 ~/.kube/config
```

### (Option) Setup Local Docker Registry

To speed up local development and avoid pushing images to external registries, set up a local registry mirror:

```sh
sudo tee /etc/rancher/k3s/registries.yaml > /dev/null <<EOF
mirrors:
  "REGISTRY":
    endpoint:
    - "http://REGISTRY"
EOF
```

> Replace `REGISTRY` with your registry address (e.g. `localhost:5000`).

Restart K3s to apply the config:

```sh
sudo systemctl restart k3s
```

## Build and Push WebDAV Image

Build the Docker image for the WebDAV server:

```sh
docker build -t zotero-webdav .
```

(Option) If you're using a local registry:

```sh
docker tag zotero-webdav REGISTRY/zotero-webdav
docker push REGISTRY/zotero-webdav
```

> Replace `REGISTRY` with your registry address.

## Setup Zotero WebDAV

Create a namespace:

```sh
kubectl create namespace zotero-webdav
```

Edit `manifest.yaml.template`:

```diff
 spec:
   containers:
   - name: zotero-webdav
+    image: zotero-webdav
-    image: REGISTRY/zotero-webdav
     ports:
     - containerPort: 8080
```

> Replace `REGISTRY` with your registry address.

Deploy:

```sh
USER=zotero PASSWORD=password envsubst < manifest.yaml.template | kubectl apply -f -
```

> Replace `USER` and `PASSWORD` with your username and password.

Check deployment status:

```sh
kubectl get all -n zotero-webdav
```

If you rebuild or retag your Docker image, restart the deployment like this:

```sh
kubectl rollout restart deployment -n zotero-webdav -l app.kubernetes.io/component=webdav
```

## Configure Ingress

`ingress.yaml` Example:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: zotero-webdav
  namespace: zotero-webdav
  labels:
    app.kubernetes.io/name: zotero-webdav
    app.kubernetes.io/component: ingress
spec:
  ingressClassName: traefik
  rules:
  - host: HOST
    http:
      paths:
      - path: /zotero-webdav/USER/zotero
        pathType: Prefix
        backend:
          service:
            name: zotero-webdav-USER-svc
            port:
              number: 8080
```

> Fix `HOST` and `USER` with your domain and username.

Apply the Ingress:

```sh
kubectl apply -f ingress.yaml
```
