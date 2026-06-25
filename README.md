# Zotero WebDAV for Kubernetes

> Self-hosted WebDAV server for syncing Zotero attachments, deployed on a lightweight Kubernetes (K3s) cluster

## 1. Install K3s

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

## 2. Build and Import the WebDAV Image

Build the Docker image for the WebDAV server:

```sh
docker build -t zotero-webdav .
```

K3s uses its own containerd runtime and doesn't see images in Docker's local store.
With no registry to pull from, export the image and import it into containerd directly:

```sh
docker save zotero-webdav:latest -o zotero-webdav.tar
sudo k3s ctr images import zotero-webdav.tar
sudo k3s ctr images ls | grep zotero   # confirm it imported
```

## 3. Deploy Zotero WebDAV

Create a namespace:

```sh
kubectl create namespace zotero-webdav
```

Fill the template's `USER`/`PASSWORD` placeholders with `envsubst` and apply the result.
Use your own credentials here:

```sh
USER=zotero PASSWORD=password envsubst < manifest.yaml.template | kubectl apply -f -
```

Check that everything came up:

```sh
kubectl get all -n zotero-webdav
```

### Update the Deployment

After rebuilding and re-importing the image (step 2), restart the deployment to roll out the new build:

```sh
kubectl rollout restart deployment -n zotero-webdav -l app.kubernetes.io/component=webdav
```

A restart leaves the previous ReplicaSet scaled to zero.
Once you no longer need it for rollback, delete these empty ReplicaSets:

```sh
kubectl delete rs -n zotero-webdav $(kubectl get rs -n zotero-webdav -o jsonpath='{range .items[?(@.spec.replicas==0)]}{.metadata.name} {end}')
```

## 4. Configure Ingress

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
  - http:
      paths:
      - path: /zotero-webdav/USER/zotero
        pathType: Prefix
        backend:
          service:
            name: zotero-webdav-USER-svc
            port:
              number: 8080
```

> Replace `USER` with username.

Apply the Ingress:

```sh
kubectl apply -f ingress.yaml
```

## 5. Connect from Zotero

In Zotero, go to **Settings → Sync → File Syncing**, set attachment syncing to **WebDAV**, and enter the server URL (`http://<host>/zotero-webdav/<USER>/zotero`) with the credentials from step 3.
Click **Verify Server** to test the connection.
