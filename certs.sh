#!/usr/bin/env bash
# Issue locally-trusted TLS certificates (mkcert) into ssl/ for nginx-proxy.
#
#   ./certs.sh --default        wildcard fallback cert (ssl/default.crt)
#   ./certs.sh <host> [...]     one cert per host (ssl/<host>.crt)
#
# nginx-proxy picks a cert per VIRTUAL_HOST in this order:
#   ssl/<VIRTUAL_HOST>.crt  ->  ssl/<parent domain>.crt  ->  ssl/default.crt
# and rejects the TLS handshake if none exists. The default cert covers every
# *.local.martell.dev name, so those need no per-host step. Names outside that
# wildcard (e.g. storyhives.local) need their own cert.
#
# docker-gen only regenerates nginx config on container events, not when a
# file appears in ssl/, so this script restarts the proxy afterwards.
set -euo pipefail
cd "$(dirname "$0")"

command -v mkcert >/dev/null || { echo "mkcert not found: brew install mkcert && mkcert -install" >&2; exit 1; }

if [[ $# -lt 1 ]]; then
  sed -n '4,5p' "$0" | sed 's/^# //' >&2
  exit 1
fi

mkdir -p ssl

# True if /etc/hosts maps $1 to some address (ignores comments; whole-name match).
in_etc_hosts() {
  sed 's/#.*//' /etc/hosts | awk -v h="$1" '{ for (i = 2; i <= NF; i++) if ($i == h) found = 1 } END { exit !found }'
}

missing_hosts=()

if [[ "$1" == "--default" ]]; then
  mkcert -cert-file ssl/default.crt -key-file ssl/default.key \
    '*.local.martell.dev' localhost 127.0.0.1 ::1
else
  for host in "$@"; do
    mkcert -cert-file "ssl/$host.crt" -key-file "ssl/$host.key" "$host"
    # *.local.martell.dev resolves via public DNS; everything else needs /etc/hosts.
    if [[ "$host" != *.local.martell.dev ]] && ! in_etc_hosts "$host"; then
      missing_hosts+=("$host")
    fi
  done
fi

if docker ps --format '{{.Names}}' | grep -qx app_proxy; then
  # Plain `docker restart`: compose's animated progress display redraws the
  # terminal and buries the output around it.
  echo "Restarting app_proxy to load the new cert..."
  docker restart app_proxy >/dev/null
fi

if [[ ${#missing_hosts[@]} -gt 0 ]]; then
  echo
  echo "Not in /etc/hosts: ${missing_hosts[*]}"
  echo "Add with:"
  echo
  for host in "${missing_hosts[@]}"; do
    # tee, not `sudo cat >>`: the redirect would run as you, not root.
    printf "  echo '127.0.0.1       %s' | sudo tee -a /etc/hosts\n" "$host"
  done
fi
