#!/bin/env bash
export PATH=$PATH:/usr/local/bin


kubectl get ns external-dns 1>/dev/null || kubectl create ns external-dns
helm repo add external-dns https://kubernetes-sigs.github.io/external-dns/
helm repo update

cat > external-dns-values.yaml <<EOF
provider: rdns
policy: sync
env:
  - name: ETCD_URLS
    value: "http://192.168.2.195:2379"
  - name: RDNS_ROOT_DOMAIN
    value: kind.cluster
EOF

helm upgrade --install external-dns -n external-dns external-dns/external-dns --values external-dns-values.yaml
kubectl wait pods -n external-dns -l app.kubernetes.io/instance=external-dns--for=condition=ready pod --timeout=90s
