#!/usr/bin/env sh
set -eu

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
ENV_FILE="${ENV_FILE:-$ROOT_DIR/.env}"

case "$ENV_FILE" in
  /*) ;;
  *) ENV_FILE="$ROOT_DIR/$ENV_FILE" ;;
esac

if [ -f "$ENV_FILE" ]; then
  set -a
  . "$ENV_FILE"
  set +a
fi

: "${PUBLIC_DOMAIN:?Set PUBLIC_DOMAIN in .env}"
: "${PUBLIC_IP:?Set PUBLIC_IP in .env}"
: "${JANUS_CONTAINER_IP:=172.30.0.20}"
: "${ASTERISK_LOCAL_NETS:=172.30.0.0/24 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16}"
: "${STUN_SERVER:=stun.l.google.com:19302}"
: "${ASTERISK_RTP_PORT_START:=10000}"
: "${ASTERISK_RTP_PORT_END:=10100}"
: "${JANUS_RTP_PORT_START:=20000}"
: "${JANUS_RTP_PORT_END:=20100}"

command -v envsubst >/dev/null 2>&1 || {
  echo "envsubst is required. Install gettext-base on Debian/Ubuntu." >&2
  exit 1
}

ASTERISK_LOCAL_NET_LINES=""
for net in $ASTERISK_LOCAL_NETS; do
  ASTERISK_LOCAL_NET_LINES="${ASTERISK_LOCAL_NET_LINES}local_net=${net}
"
done
export PUBLIC_DOMAIN PUBLIC_IP JANUS_CONTAINER_IP STUN_SERVER ASTERISK_LOCAL_NET_LINES
export ASTERISK_RTP_PORT_START ASTERISK_RTP_PORT_END JANUS_RTP_PORT_START JANUS_RTP_PORT_END

mkdir -p "$ROOT_DIR/deploy/generated/asterisk" "$ROOT_DIR/deploy/generated/janus"

envsubst < "$ROOT_DIR/deploy/templates/asterisk/pjsip.conf.tpl" > "$ROOT_DIR/deploy/generated/asterisk/pjsip.conf"
envsubst < "$ROOT_DIR/deploy/templates/asterisk/http.conf.tpl" > "$ROOT_DIR/deploy/generated/asterisk/http.conf"
envsubst < "$ROOT_DIR/deploy/templates/asterisk/rtp.conf.tpl" > "$ROOT_DIR/deploy/generated/asterisk/rtp.conf"
envsubst < "$ROOT_DIR/deploy/templates/janus/janus.jcfg.tpl" > "$ROOT_DIR/deploy/generated/janus/janus.jcfg"
envsubst < "$ROOT_DIR/deploy/templates/janus/janus.transport.websockets.jcfg.tpl" > "$ROOT_DIR/deploy/generated/janus/janus.transport.websockets.jcfg"
envsubst < "$ROOT_DIR/deploy/templates/janus/janus.plugin.sip.jcfg.tpl" > "$ROOT_DIR/deploy/generated/janus/janus.plugin.sip.jcfg"

echo "Generated deploy configs for ${PUBLIC_DOMAIN} (${PUBLIC_IP})."
