# Kubernetes OIDC Authentication with Keycloak

This guide demonstrates how to set up OIDC authentication for Kubernetes using Keycloak as the identity provider.

## Prerequisites

- kubectl installed
- kubelogin plugin installed
- Access to a Keycloak instance
- A Kubernetes cluster configured for OIDC authentication

## Quick Start with kubelogin

### Get Token
```bash
kubectl oidc-login get-token \
    --oidc-issuer-url=https://keycloak.adiachan.cn/auth/realms/kind \
    --oidc-client-id=kube \
    --oidc-extra-scope=email
```

### Setup kubelogin
```bash
kubectl oidc-login setup \
    --oidc-issuer-url=https://keycloak.adiachan.cn/auth/realms/kind \
    --oidc-client-id=kube
```

### Setup kubeconfig
```bash
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

# debug
$ rm -rf ~/.kube/cache
$ rm -rf ~/.kube/http-cache
```

## Documentation

- [kubelogin Setup Guide](https://github.com/int128/kubelogin/blob/master/docs/setup.md)
- [Standalone Mode](https://github.com/int128/kubelogin/blob/master/docs/standalone-mode.md)

## Manual OIDC Authentication

For scenarios where you need to manually obtain and configure OIDC tokens:

### Step 1: Set User Credentials
```bash
export K8S_USER='k8suser'
export K8S_USER_PASS='THE_USER_PASS'
```

### Step 2: Obtain Tokens from Keycloak
```bash
export RESPONSE=$(curl -v -k -X POST \
    -H "Content-Type: application/x-www-form-urlencoded" \
    "https://keycloak.adiachan.cn/auth/realms/kind/protocol/openid-connect/token" \
    -d grant_type=password \
    -d client_id=kube \
    -d username=$K8S_USER \
    -d password=$K8S_USER_PASS \
    -d scope="openid profile email groups" | jq '.')
```

### Step 3: Extract Token Values
```bash
export ID_TOKEN=$(echo $RESPONSE | jq -r '.id_token')
export REFRESH_TOKEN=$(echo $RESPONSE | jq -r '.refresh_token')
export ACCESS_TOKEN=$(echo $RESPONSE | jq -r '.access_token')
```

### Step 4: Verify Token (Optional)
```bash
curl -s -H "Content-Type: application/x-www-form-urlencoded" \
    -H "Authorization: Bearer ${ACCESS_TOKEN}" \
    "https://keycloak.adiachan.cn/auth/realms/kind/protocol/openid-connect/userinfo" | jq '.'
```

### Step 5: Configure kubectl User Credentials
```bash
kubectl config set-credentials $K8S_USER \
    --auth-provider=oidc \
    --auth-provider-arg=idp-issuer-url=https://keycloak.adiachan.cn/auth/realms/kind \
    --auth-provider-arg=client-id=kube \
    --auth-provider-arg=refresh-token=${REFRESH_TOKEN} \
    --auth-provider-arg=id-token=${ID_TOKEN}
```

### Step 6: Create kubectl Context
```bash
kubectl config set-context $K8S_USER \
    --cluster=kind-helm \
    --user=$K8S_USER \

```

### Step 7: Use the New Context
```bash
kubectl config use-context $K8S_USER
```

## Troubleshooting

- Ensure your Keycloak realm and client are properly configured
- Verify that the Kubernetes API server has the correct OIDC flags set
- Check token expiration if authentication fails
- Use `kubectl config view` to verify your configuration

## Security Notes

- Never commit credentials or tokens to version control
- Use environment variables or secure secret management solutions
- Tokens expire and need to be refreshed periodically
- The `--auth-provider` flag is deprecated in newer kubectl versions; consider using kubelogin instead

