# Deployment

This compose setup is parameterized for a server behind NAT, including Azure VMs.

## Configure

1. Copy `.env.example` to `.env`.
2. Set:
   - `PUBLIC_DOMAIN` to the DNS name used by browsers.
   - `PUBLIC_IP` to the public NAT address announced in WebRTC/SIP SDP.
   - `INTERNAL_IP` to the Azure VM private address.
   - `ASTERISK_LOCAL_NETS` to include the Docker subnet and private Azure/VPN CIDRs.
   - `LETSENCRYPT_EMAIL` to the email used for Let's Encrypt registration.
   - `TURN_USERNAME` and `TURN_PASSWORD` for browser TURN credentials.
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

## Start

```sh
docker compose --env-file .env up -d --build
```

## Azure networking

Allow or forward these ports to the VM:

- TCP `SOFTPHONE_HTTP_PORT`
- UDP/TCP `ASTERISK_SIP_PORT`
- TCP `ASTERISK_WSS_PORT`
- TCP `JANUS_WSS_PORT`
- UDP/TCP `TURN_PORT`
- UDP/TCP `TURN_TLS_PORT`
- UDP `ASTERISK_RTP_PORT_START-ASTERISK_RTP_PORT_END`
- UDP `JANUS_RTP_PORT_START-JANUS_RTP_PORT_END`
- UDP `TURN_MIN_PORT-TURN_MAX_PORT`

The default Docker bridge subnet is `172.30.0.0/24`. Change `VOICE_SUBNET`,
`ASTERISK_CONTAINER_IP`, and `JANUS_CONTAINER_IP` together if that subnet
conflicts with Azure/VPN routes.

The TURN service uses host networking and advertises
`external-ip=PUBLIC_IP/INTERNAL_IP`, which matches an Azure VM behind NAT.
