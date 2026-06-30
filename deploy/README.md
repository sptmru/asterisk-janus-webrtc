# Deployment

This compose setup is parameterized for a server behind NAT, including Azure VMs.

## Configure

1. Copy `.env.example` to `.env`.
2. Set:
   - `PUBLIC_DOMAIN` to the DNS name used by browsers.
   - `PUBLIC_IP` to the public NAT address announced in WebRTC/SIP SDP.
   - `INTERNAL_IP` to the Azure VM private address, for operator reference and firewall rules.
   - `ASTERISK_LOCAL_NETS` to include the Docker subnet and private Azure/VPN CIDRs.
3. Make sure the certificate exists at:
   `/etc/letsencrypt/live/${PUBLIC_DOMAIN}/fullchain.pem`

For a first certificate on the host, stop anything using port 80 and run:

```sh
certbot certonly --standalone -d "$PUBLIC_DOMAIN"
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
- UDP `ASTERISK_RTP_PORT_START-ASTERISK_RTP_PORT_END`
- UDP `JANUS_RTP_PORT_START-JANUS_RTP_PORT_END`

The default Docker bridge subnet is `172.30.0.0/24`. Change `VOICE_SUBNET`,
`ASTERISK_CONTAINER_IP`, and `JANUS_CONTAINER_IP` together if that subnet
conflicts with Azure/VPN routes.
