# kubelogin
```bash
$ kubectl oidc-login get-token --oidc-issuer-url=https://keycloak.adiachan.cn/auth/realms/kind --oidc-client-id=kube --oidc-extra-scope=email

$ kubectl oidc-login setup --oidc-issuer-url=https://keycloak.adiachan.cn/auth/realms/kind --oidc-client-id=kube --oidc-extra-scope=email

$ kubectl config set-credentials oidc \
  --exec-api-version=client.authentication.k8s.io/v1 \
  --exec-interactive-mode=Never \
  --exec-command=kubectl \
  --exec-arg=oidc-login \
  --exec-arg=get-token \
  --exec-arg="--oidc-issuer-url=https://keycloak.adiachan.cn/auth/realms/kind" \
  --exec-arg="--oidc-client-id=kube" \
  --exec-arg="--oidc-extra-scope=email"

$ kubectl --user=oidc cluster-info

$ kubectl config set-context --current --user=oidc
```

# setup
https://github.com/int128/kubelogin/blob/master/docs/setup.md

# standalone
https://github.com/int128/kubelogin/blob/master/docs/standalone-mode.md

# debug
```bash
$ rm -rf ~/.kube/cache
$ rm -rf ~/.kube/http-cache
```
