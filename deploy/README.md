# Deployment

This compose setup is parameterized for a server behind NAT, including Azure VMs.

For the full client-facing deployment and operations guide, see
`deploy/CLIENT_GUIDE.md`.

## Configure

1. Copy `.env.example` to `.env`.
2. Set:
   - `PUBLIC_DOMAIN` to the DNS name used by browsers.
   - `PUBLIC_IP` to the public NAT address announced in WebRTC/SIP SDP.
   - `INTERNAL_IP` to the Azure VM private address.
   - `ASTERISK_LOCAL_NETS` to include private Azure/VPN CIDRs.
   - `LETSENCRYPT_EMAIL` to the email used for Let's Encrypt registration.
   - `TURN_USERNAME` and `TURN_PASSWORD` for browser TURN credentials.
   - `JANUS_ADMIN_SECRET` and SIP user passwords to strong per-deploy values.
3. Make sure DNS for `PUBLIC_DOMAIN` points to `PUBLIC_IP`.

## Issue TLS Certificate

Port `LETSENCRYPT_HTTP_PORT` must be reachable from the internet. By default this
is TCP `80`.

```sh
./deploy/issue-letsencrypt.sh
```

This runs the Compose `certbot` profile and writes the certificate under
`LETSENCRYPT_PATH`, usually `/etc/letsencrypt/live/${PUBLIC_DOMAIN}/...`.

For a full first deploy, this helper issues the certificate when missing,
generates configs, and starts the stack:

```sh
./deploy/bootstrap.sh
```

## Generate configs

```sh
./deploy/render-configs.sh
```

Run this again after changing `.env`.
Config generation fails intentionally if any `replace-with-*` placeholder
secret is still present.

## Start

```sh
docker compose --env-file .env up -d --build
```

Grafana is available on `127.0.0.1:${GRAFANA_PORT}` after startup. Use SSH
port-forwarding or a private VPN to access it; do not expose it publicly.

## Azure networking

Allow or forward these ports to the VM:

- TCP `SOFTPHONE_HTTPS_PORT`
- UDP/TCP `ASTERISK_SIP_PORT`
- TCP `ASTERISK_WSS_PORT`
- TCP `JANUS_WSS_PORT`
- UDP/TCP `TURN_PORT`
- UDP/TCP `TURN_TLS_PORT`
- UDP `ASTERISK_RTP_PORT_START-ASTERISK_RTP_PORT_END`
- UDP `JANUS_RTP_PORT_START-JANUS_RTP_PORT_END`
- UDP `TURN_MIN_PORT-TURN_MAX_PORT`

Do not expose `GRAFANA_PORT`, `PROMETHEUS_PORT`, or `LOKI_PORT` publicly. They
are bound to `127.0.0.1` by Compose for local/SSH-tunnel access.

The Asterisk, Janus, and TURN services use host networking. This avoids Docker
creating per-port proxy bindings for large UDP RTP ranges.

The TURN service advertises
`external-ip=PUBLIC_IP/INTERNAL_IP`, which matches an Azure VM behind NAT.

`SOFTPHONE_HTTP_PORT` is bound to `127.0.0.1` for local diagnostics only. The
production browser entrypoint is the HTTPS reverse proxy on
`SOFTPHONE_HTTPS_PORT`, using the same Let's Encrypt certificate as the WebRTC
services.
