# Janus Softphone Deployment Guide

This document describes the Docker-based WebRTC softphone deployment, including
architecture, dependencies, configuration, deployment, user management,
certificate handling, TURN, and basic operations.

## 1. System Overview

The stack provides browser-based voice calling through Janus Gateway SIP plugin
using `softphone.html`. The direct Asterisk `sip.html` page is kept in the
repository as an internal diagnostic/testing page, but it is not part of the
client-facing deployment.

The deployment is designed for a VM behind NAT, including an Azure VM with a
private internal IP and a separate public IP address.

Main components:

- `janus-softphone`: nginx container serving the browser clients.
- `softphone-https`: HTTPS reverse proxy for the browser UI, using the same
  Let's Encrypt certificate path as Janus, Asterisk, and coturn.
- `asterisk`: Asterisk PBX with PJSIP, WebRTC WSS, DTLS-SRTP, and RTP.
- `janus`: Janus Gateway with SIP plugin and WebSocket/WSS transport.
- `turn`: coturn TURN server for WebRTC relay candidates.
- `certbot`: on-demand Let's Encrypt certificate issuance.
- `fail2ban`: protects exposed Asterisk PJSIP endpoints from authentication
  scanners.

Important browser note: microphone access requires a secure browser context in
normal production use. The stack includes an HTTPS reverse proxy on
`SOFTPHONE_HTTPS_PORT`, backed by the same Let's Encrypt certificate generated
for WebRTC services. The plain `janus-softphone` HTTP port is bound to
`127.0.0.1` for local diagnostics only.

## 2. Architecture

```text
Browser
  |
  | HTTPS static page on SOFTPHONE_HTTPS_PORT
  v
softphone-https / nginx reverse proxy
  |
  | HTTP inside Docker
  v
janus-softphone / nginx

Client flow:
Browser softphone.html
  | WSS: JANUS_WSS_PORT
  v
Janus Gateway
  | SIP UDP inside Docker network
  v
Asterisk PJSIP Janus endpoint

TURN flow:
Browser
  | TURN/TURNS on PUBLIC_DOMAIN
  v
coturn on host network
  | relay UDP range TURN_MIN_PORT-TURN_MAX_PORT
  v
WebRTC media peers
```

Asterisk and Janus run on a Docker bridge network. coturn uses host networking
so it can bind the VM private address and advertise the public NAT address using
`external-ip=PUBLIC_IP/INTERNAL_IP`.

## 3. Dependencies

Server requirements:

- Linux VM with Docker Engine and Docker Compose plugin.
- Public DNS record for `PUBLIC_DOMAIN` pointing to `PUBLIC_IP`.
- Inbound firewall/NAT rules for the ports listed below.
- Internet access from the VM to pull Docker images and request certificates.

Images used:

- `nginx:1.27.5-alpine`
- `ubuntu:22.04` based custom Asterisk image
- `canyan/janus-gateway:master@sha256:cddf2da2dba7947c2a3aa7b2e77b363b1200cd6874dbebe32b5148fe187a0d89`
- `coturn/coturn:4.14.0`
- `certbot/certbot:v5.6.0`
- `crazymax/fail2ban:1.1.0`

The Asterisk image installs Asterisk and the Digium Opus codec module at build
time.

## 4. Network and Firewall Requirements

Open these inbound ports on the cloud firewall, VM firewall, and NAT/security
group:

| Purpose | Default | Protocol |
| --- | ---: | --- |
| Softphone web UI | `SOFTPHONE_HTTPS_PORT=443` | TCP |
| Local diagnostic web UI | `SOFTPHONE_HTTP_PORT=9669` | TCP on `127.0.0.1` |
| Let's Encrypt HTTP challenge | `LETSENCRYPT_HTTP_PORT=80` | TCP |
| Asterisk SIP | `ASTERISK_SIP_PORT=5060` | UDP/TCP |
| Asterisk WebRTC WSS | `ASTERISK_WSS_PORT=8089` | TCP |
| Janus WSS | `JANUS_WSS_PORT=8989` | TCP |
| TURN | `TURN_PORT=3478` | UDP/TCP |
| TURN over TLS | `TURN_TLS_PORT=5349` | UDP/TCP |
| Asterisk RTP | `ASTERISK_RTP_PORT_START-ASTERISK_RTP_PORT_END` | UDP |
| Janus RTP | `JANUS_RTP_PORT_START-JANUS_RTP_PORT_END` | UDP |
| TURN relay | `TURN_MIN_PORT-TURN_MAX_PORT` | UDP |

Default RTP/TURN ranges in `.env.example`:

- Asterisk RTP: `20000-30000/udp`
- Janus RTP: `10000-19999/udp`
- TURN relay: `49152-49252/udp`

Keep these ranges non-overlapping.

Expose `SOFTPHONE_HTTPS_PORT` to users. `SOFTPHONE_HTTP_PORT` is published only
on `127.0.0.1` by Compose and should not be opened in the cloud firewall.

## 5. Configuration

Create the environment file:

```sh
cp .env.example .env
```

Required values:

```sh
PUBLIC_DOMAIN=webrtc.example.com
PUBLIC_IP=203.0.113.10
INTERNAL_IP=10.0.0.4
LETSENCRYPT_EMAIL=admin@example.com
TURN_USERNAME=webrtc
TURN_PASSWORD=replace-with-strong-turn-password
JANUS_ADMIN_SECRET=replace-with-strong-janus-admin-secret
WEBRTC_1001_PASSWORD=replace-with-strong-1001-password
WEBRTC_1002_PASSWORD=replace-with-strong-1002-password
JANUS_2001_PASSWORD=replace-with-strong-2001-password
JANUS_2002_PASSWORD=replace-with-strong-2002-password
JANUS_2003_PASSWORD=replace-with-strong-2003-password
JANUS_2004_PASSWORD=replace-with-strong-2004-password
```

Important variables:

| Variable | Meaning |
| --- | --- |
| `PUBLIC_DOMAIN` | DNS name used by browsers and certificates. |
| `PUBLIC_IP` | Public NAT IP announced in SDP/ICE/TURN. |
| `INTERNAL_IP` | VM private IP, used by coturn bind/relay settings. |
| `VOICE_SUBNET` | Docker bridge subnet for Asterisk and Janus. |
| `ASTERISK_CONTAINER_IP` | Static Docker IP for Asterisk. |
| `JANUS_CONTAINER_IP` | Static Docker IP for Janus. |
| `LETSENCRYPT_PATH` | Host path mounted into services for certificates. |
| `ASTERISK_LOCAL_NETS` | Private networks that Asterisk should treat as local. |
| `TURN_REALM` | TURN auth realm. Empty value defaults to `PUBLIC_DOMAIN`. |
| `TURN_USERNAME` / `TURN_PASSWORD` | TURN credentials entered in browser clients. |
| `JANUS_ADMIN_SECRET` | Janus admin secret value; required even though admin WebSocket is disabled. |
| `WEBRTC_*_PASSWORD` / `JANUS_*_PASSWORD` | Static Asterisk PJSIP user passwords used by generated configs. |

For Azure, `INTERNAL_IP` should be the VM private NIC address, and `PUBLIC_IP`
should be the public address attached to the VM or load balancer.

## 6. First Deployment

1. Prepare `.env`.
2. Ensure DNS for `PUBLIC_DOMAIN` resolves to `PUBLIC_IP`.
3. Open the firewall ports listed above.
4. Run the bootstrap script:

```sh
./deploy/bootstrap.sh
```

The bootstrap script:

1. Checks whether `LETSENCRYPT_PATH/live/PUBLIC_DOMAIN/fullchain.pem` exists.
2. Runs certbot if the certificate is missing.
3. Generates runtime configs from templates.
4. Starts the Docker Compose stack.

Manual equivalent:

```sh
./deploy/issue-letsencrypt.sh
./deploy/render-configs.sh
docker compose --env-file .env up -d --build
```

## 7. Runtime Config Generation

Do not edit files under `deploy/generated/` manually. They are generated from:

- `deploy/templates/asterisk/pjsip.conf.tpl`
- `deploy/templates/asterisk/http.conf.tpl`
- `deploy/templates/asterisk/rtp.conf.tpl`
- `deploy/templates/janus/janus.jcfg.tpl`
- `deploy/templates/janus/janus.transport.websockets.jcfg.tpl`
- `deploy/templates/janus/janus.plugin.sip.jcfg.tpl`
- `deploy/templates/coturn/turnserver.conf.tpl`
- `deploy/templates/nginx/softphone-https.conf.tpl`

Regenerate after changing `.env` or templates:

```sh
./deploy/render-configs.sh
docker compose --env-file .env restart softphone-https asterisk janus turn
```

Config generation fails intentionally if any `replace-with-*` placeholder
secret is still present in `.env`.

## 8. Browser Client Configuration

- Open `https://PUBLIC_DOMAIN/`. The HTTPS reverse proxy serves
  `softphone.html` as the default page.
- WSS URL should be `wss://PUBLIC_DOMAIN:8989`.
- Use users from the Janus range, currently `2001` through `2004`.
- Optional TURN settings:
  - TURN URL: `turn:PUBLIC_DOMAIN:3478?transport=udp`
  - TURN Username: value of `TURN_USERNAME`
  - TURN Password: value of `TURN_PASSWORD`

Test extensions:

- `600`: Asterisk echo test.
- `700`: Music on hold test.

## 9. User Management

Users are currently static Asterisk PJSIP users. They are defined in:

- `deploy/templates/asterisk/pjsip.conf.tpl`
- `asterisk/config/extensions.conf`

Client-facing users should use the `janus-endpoint` template, for example
`2001`.

### Add a Client User

Add a `janus-endpoint` block, for example `2005`:

```ini
[2005](janus-endpoint)
auth=2005
aors=2005
callerid=Janus 2005 <2005>

[2005]
type=auth
auth_type=userpass
username=2005
password=StrongPasswordHere

[2005]
type=aor
max_contacts=2
remove_existing=yes
qualify_frequency=0
```

Then add the same style of dialplan entry for extension `2005` in
`asterisk/config/extensions.conf`.

Regenerate and restart:

```sh
./deploy/render-configs.sh
docker compose --env-file .env restart asterisk
```

## 10. Certificate Operations

Issue a certificate:

```sh
./deploy/issue-letsencrypt.sh
```

Renew certificates and restart certificate consumers:

```sh
./deploy/renew-letsencrypt.sh
```

The certificate is mounted into Asterisk, Janus, and coturn from
`LETSENCRYPT_PATH`, normally `/etc/letsencrypt`.

For automated renewal, install a host cron entry or systemd timer that runs
`deploy/renew-letsencrypt.sh`. Keep TCP port `80` available for the HTTP
challenge during renewal.

## 11. Common Operations

Start or update the stack:

```sh
docker compose --env-file .env up -d --build
```

Stop the stack:

```sh
docker compose --env-file .env down
```

View service status:

```sh
docker compose --env-file .env ps
```

View logs:

```sh
docker compose --env-file .env logs -f asterisk
docker compose --env-file .env logs -f janus
docker compose --env-file .env logs -f turn
docker compose --env-file .env logs -f janus-softphone
```

Open an Asterisk CLI:

```sh
docker compose --env-file .env exec asterisk asterisk -rvvv
```

Useful Asterisk CLI commands:

```text
pjsip show endpoints
pjsip show contacts
pjsip show registrations
rtp set debug on
rtp set debug off
```

## 12. Troubleshooting

Certificate issuance fails:

- Confirm DNS resolves `PUBLIC_DOMAIN` to `PUBLIC_IP`.
- Confirm TCP `LETSENCRYPT_HTTP_PORT`, usually `80`, is open.
- Stop any other service using host port `80`.

Browser cannot connect over WSS:

- Confirm the certificate exists under
  `LETSENCRYPT_PATH/live/PUBLIC_DOMAIN/fullchain.pem`.
- Confirm `JANUS_WSS_PORT` is open.
- Confirm the browser URL uses the correct port and protocol.

Registration succeeds but calls have no audio:

- Confirm UDP RTP ranges are open in the firewall.
- Confirm `PUBLIC_IP` is correct.
- Confirm `ASTERISK_LOCAL_NETS` includes the Docker subnet and private Azure
  network.
- Try enabling TURN in the browser client.

TURN connection works but relay media fails:

- Confirm UDP `TURN_MIN_PORT-TURN_MAX_PORT` is open.
- Confirm `INTERNAL_IP` is the VM private IP.
- Confirm `external-ip=PUBLIC_IP/INTERNAL_IP` in
  `deploy/generated/coturn/turnserver.conf`.

Janus users cannot register:

- Confirm Janus can resolve `PUBLIC_DOMAIN` to `ASTERISK_CONTAINER_IP` through
  the Compose `extra_hosts` entry.
- Check Janus logs and Asterisk PJSIP logs.
- Confirm the user exists as a `janus-endpoint` in generated `pjsip.conf`.

Fail2ban is not banning scanner IPs:

- Confirm `fail2ban` is running with host networking.
- Confirm Asterisk logs are present in the shared `asterisk_logs` volume.
- Confirm Docker forwarding rules allow bans through the configured fail2ban
  action.

## 13. Security Notes

- Replace all placeholder SIP, TURN, and Janus secret values in `.env` before
  production use.
- Restrict management access to the VM.
- Keep SIP users limited to required extensions.
- Keep TURN relay range as small as practical for the expected call volume.
- Do not expose Janus admin WebSocket.
- Review logs periodically for SIP authentication failures.
- Keep Docker images and the host OS patched.

## 14. File Map

| Path | Purpose |
| --- | --- |
| `.env.example` | Example deployment environment file. |
| `docker-compose.yml` | Main service definition. |
| `deploy/bootstrap.sh` | First deploy helper. |
| `deploy/issue-letsencrypt.sh` | Certificate issuance helper. |
| `deploy/renew-letsencrypt.sh` | Certificate renewal helper. |
| `deploy/render-configs.sh` | Generates runtime configs from templates. |
| `deploy/templates/` | Source templates for generated configs. |
| `deploy/generated/` | Generated runtime configs, not edited manually. |
| `asterisk/config/extensions.conf` | Dialplan and test extensions. |
| `softphone.html` | Client-facing Janus-based browser softphone. |
| `sip.html` | Internal direct Asterisk SIP-over-WSS diagnostic page. |
