services:
  traefik:
    image: traefik:v3.0.2
    container_name: traefik
    restart: unless-stopped
    security_opt:
      - no-new-privileges:true
    networks:
      - kind
      - socket_proxy
    ports:
      - target: 80
        published: 80
        protocol: tcp
        mode: host
      - target: 443
        published: 443
        protocol: tcp
        mode: host
      # - 443:443/tcp # Uncomment if you want HTTP3
      # - 443:443/udp # Uncomment if you want HTTP3
    environment:
      CF_DNS_API_TOKEN_FILE: /run/secrets/cf_dns_api_token # note using _FILE for docker secrets
      # TRAEFIK_DASHBOARD_CREDENTIALS: /run/secrets/basic_auth_credentials
    secrets:
      - cf_dns_api_token
      - basic_auth_credentials
    # env_file: .env
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - $DOCKERDIR/appdata/traefik/rules:/rules:ro
      # - /var/run/docker.sock:/var/run/docker.sock:ro # Enable if not using Socket Proxy
      - $DOCKERDIR/appdata/traefik/data/traefik.yml:/traefik.yml:ro
      - $DOCKERDIR/appdata/traefik/data/acme.json:/acme.json
      # - ./data/dynamic_config.yml:/dynamic_config.yml:ro
      - $DOCKERDIR/appdata/traefik/logs:/logs
    labels:
      - "traefik.enable=true"

      - "traefik.http.routers.traefik-ssl.entrypoints=websecure"
      - "traefik.http.routers.traefik-ssl.rule=Host(`traefik-dash.${DOMAINNAME}`)"
      - "traefik.http.routers.traefik-ssl.middlewares=chain-basic-auth@file"
      - "traefik.http.routers.traefik-ssl.tls=true"
      - "traefik.http.routers.traefik-ssl.tls.certresolver=cloudflare"
      - "traefik.http.routers.traefik-ssl.tls.domains[0].main=${DOMAINNAME}"
      - "traefik.http.routers.traefik-ssl.tls.domains[0].sans=*.${DOMAINNAME}"
      - "traefik.http.routers.traefik-ssl.service=api@internal"

  # traefik-forward-auth:
  #   image: thomseddon/traefik-forward-auth
  #   container_name: traefik-forward-auth
  #   restart: unless-stopped

  #   volumes:
  #     - '$DOCKERDIR/appdata/traefik/data/forward.ini:/forward.ini'

  #   environment:
  #     - CONFIG=/forward.ini

  #   dns_search: ${DOMAINNAME}
  #   networks:
  #     - proxy

  #   labels:
  #     - traefik.enable=true
  #     # SSL configuration
  #     - traefik.http.routers.traefik-forward-auth-ssl.tls=true
  #     - traefik.http.routers.traefik-forward-auth-ssl.entryPoints=websecure
  #     - traefik.http.routers.traefik-forward-auth-ssl.rule=Host(`traefik-auth.${DOMAINNAME}`)
  #     # Middlewares
  #     - traefik.http.routers.traefik-forward-auth-ssl.middlewares=chain-oauth@file
  #     # HTTP Services
  #     # - traefik.http.routers.traefik-forward-auth.service=oauth-svc
  #     - traefik.http.services.traefik-forward-auth.loadBalancer.server.port=4181

