# kubelogin
```bash
$ kubectl oidc-login get-token --oidc-issuer-url=https://keycloak.adiachan.cn/auth/realms/kind --oidc-client-id=kube --oidc-extra-scope=email

$ kubectl oidc-login setup --oidc-issuer-url=https://keycloak.adiachan.cn/auth/realms/kind --oidc-client-id=kube
```

# setup
https://github.com/int128/kubelogin/blob/master/docs/setup.md

# standalone
https://github.com/int128/kubelogin/blob/master/docs/standalone-mode.md
