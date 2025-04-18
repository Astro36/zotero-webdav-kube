# Zotero WebDAV

## Install K3s

```sh
curl -sfL https://get.k3s.io | sh -
```

```sh
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config
chmod 600 ~/.kube/config
```

### (Option) Setup Local Registry:

```sh
sudo tee /etc/rancher/k3s/registries.yaml > /dev/null <<EOF
mirrors:
  "REGISTRY:5000":
    endpoint:
    - "http://REGISTRY:5000"
EOF
```

```sh
sudo systemctl restart k3s
```

## Build OCI Image

```sh
docker build -t zotero-webdav .
```

### (Option) Push to Local Registry

```sh
docker tag zotero-webdav REGISTRY:5000/zotero-webdav
```

```sh
docker push REGISTRY:5000/zotero-webdav
```

## Update Pod Image

```
kubectl rollout restart deployment -n zotero-webdav -l app.kubernetes.io/component=webdav
```

## Setup Zotero WebDAV

```sh
kubectl create namespace zotero-webdav
```

```sh
USER=zotero PASSWORD=password envsubst < manifest.yaml.template | sudo kubectl apply -f -
```

## Setup Zotero WebDAV Ingress:

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

```sh
kubectl apply -f ingress.yaml
```
