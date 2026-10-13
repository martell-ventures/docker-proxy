# app_proxy

Shared nginx reverse proxy (`jwilder/nginx-proxy`) for the local docker
development projects. It watches the docker socket: any container on
`proxy_network` with a `VIRTUAL_HOST` env var is routed automatically, and
gets HTTPS if a matching certificate exists in `ssl/`. Any number of sites
can be up at once; nginx picks the right certificate per hostname (SNI).

    docker compose up -d

## First-time setup

    brew install mkcert
    mkcert -install          # trust the local CA in the macOS keychain
    ./certs.sh --default     # ssl/default.crt for *.local.martell.dev

`*.local.martell.dev` resolves to 127.0.0.1 via DNS, so names under it need
no `/etc/hosts` entry and no per-site certificate.

## Wiring up a project

The project's web service needs:

    environment:
      VIRTUAL_HOST: myapp.local.martell.dev
      VIRTUAL_PORT: 80          # the port the container serves plain HTTP on
    networks:
      - proxy_network

    networks:
      proxy_network:
        external: true

The proxy terminates TLS; the container itself only needs HTTP.

## Certificates

nginx-proxy chooses a certificate for each `VIRTUAL_HOST` in this order:

1. `ssl/<VIRTUAL_HOST>.crt` (+ `.key`)
2. `ssl/<parent domain>.crt`
3. `ssl/default.crt`, the `*.local.martell.dev` wildcard from `./certs.sh --default`

If none of them covers the name, the browser shows a certificate error
(or the handshake is rejected when no default cert exists). A name outside the
wildcard, such as `storyhives.local`, needs its own certificate and an
`/etc/hosts` entry:

    ./certs.sh storyhives.local

`certs.sh` restarts the proxy afterwards, because docker-gen regenerates the
nginx config only on container events, not when files appear in `ssl/`.
Certificates and keys are gitignored and machine-local.

Other devices or containers trust these certificates only if the mkcert CA
(`~/Library/Application Support/mkcert/rootCA.pem`) is installed in their
trust store.

## Debugging

- `docker exec app_proxy nginx -T`: full generated config, including each
  vhost's upstream IP and certificate.
- `https://<any-proxied-host>/nginx-proxy-debug`: JSON of what nginx-proxy
  sees for that vhost (enabled with `DEBUG_ENDPOINT=true`).
- 503 on a hostname: no running container on `proxy_network` claims that
  `VIRTUAL_HOST`.

`conf/locals.conf` is included into the http block (large uploads, long
timeouts).
