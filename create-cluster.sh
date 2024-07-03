#!/bin/bash

set -e

# re-create cluster
kind delete cluster

cat <<EOF | kind create cluster --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
EOF

# Install ingress
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# Wait for ingress pods to be created
sleep 30

# Wait until the ingress is functional
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=180s

# Install cert-manager
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm upgrade --install cert-manager jetstack/cert-manager --namespace cert-manager --set installCRDs=true --set extraArgs={--enable-certificate-owner-ref=true} --create-namespace --wait --timeout=10m

# Install our custom charts
# Put your files in some directory and run
# nohup python -m http.server -b 172.19.0.1 8000 -d ./ &
echo "If you haven't already you need to host these charts somewhere, if running locally drop this command in another shell:"
echo
echo "nohup python -m http.server -b 172.19.0.1 8000 -d ./ &"
echo
echo "To terminate the process just run: fg -> ctrl-c"

sleep 60

helm repo add charts http://172.19.0.1:8000/
helm repo update
helm upgrade --install epinio charts/epinio-preview --namespace epinio --create-namespace --set global.domain=172-19-0-2.sslip.com --wait --timeout=10m
