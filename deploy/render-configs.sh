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
: "${INTERNAL_IP:?Set INTERNAL_IP in .env}"
: "${JANUS_CONTAINER_IP:=172.30.0.20}"
: "${ASTERISK_LOCAL_NETS:=172.30.0.0/24 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16}"
: "${STUN_SERVER:=stun.l.google.com:19302}"
: "${ASTERISK_RTP_PORT_START:=10000}"
: "${ASTERISK_RTP_PORT_END:=10100}"
: "${JANUS_RTP_PORT_START:=20000}"
: "${JANUS_RTP_PORT_END:=20100}"
: "${TURN_PORT:=3478}"
: "${TURN_TLS_PORT:=5349}"
: "${TURN_MIN_PORT:=49152}"
: "${TURN_MAX_PORT:=49252}"
: "${TURN_REALM:=$PUBLIC_DOMAIN}"
: "${TURN_USERNAME:?Set TURN_USERNAME in .env}"
: "${TURN_PASSWORD:?Set TURN_PASSWORD in .env}"
: "${JANUS_ADMIN_SECRET:?Set JANUS_ADMIN_SECRET in .env}"
: "${WEBRTC_1001_PASSWORD:?Set WEBRTC_1001_PASSWORD in .env}"
: "${WEBRTC_1002_PASSWORD:?Set WEBRTC_1002_PASSWORD in .env}"
: "${JANUS_2001_PASSWORD:?Set JANUS_2001_PASSWORD in .env}"
: "${JANUS_2002_PASSWORD:?Set JANUS_2002_PASSWORD in .env}"
: "${JANUS_2003_PASSWORD:?Set JANUS_2003_PASSWORD in .env}"
: "${JANUS_2004_PASSWORD:?Set JANUS_2004_PASSWORD in .env}"

require_real_secret() {
  var_name="$1"
  eval "var_value=\${$var_name:-}"
  case "$var_value" in
    replace-with-*|change-me*|changeme*)
      echo "$var_name must be replaced with a real per-deploy secret in .env." >&2
      exit 1
      ;;
  esac
}

require_real_secret TURN_PASSWORD
require_real_secret JANUS_ADMIN_SECRET
require_real_secret WEBRTC_1001_PASSWORD
require_real_secret WEBRTC_1002_PASSWORD
require_real_secret JANUS_2001_PASSWORD
require_real_secret JANUS_2002_PASSWORD
require_real_secret JANUS_2003_PASSWORD
require_real_secret JANUS_2004_PASSWORD

command -v envsubst >/dev/null 2>&1 || {
  echo "envsubst is required. Install gettext-base on Debian/Ubuntu." >&2
  exit 1
}

ASTERISK_LOCAL_NET_LINES=""
for net in $ASTERISK_LOCAL_NETS; do
  ASTERISK_LOCAL_NET_LINES="${ASTERISK_LOCAL_NET_LINES}local_net=${net}
"
done
export PUBLIC_DOMAIN PUBLIC_IP INTERNAL_IP JANUS_CONTAINER_IP STUN_SERVER ASTERISK_LOCAL_NET_LINES
export ASTERISK_RTP_PORT_START ASTERISK_RTP_PORT_END JANUS_RTP_PORT_START JANUS_RTP_PORT_END
export TURN_PORT TURN_TLS_PORT TURN_MIN_PORT TURN_MAX_PORT TURN_REALM TURN_USERNAME TURN_PASSWORD
export JANUS_ADMIN_SECRET WEBRTC_1001_PASSWORD WEBRTC_1002_PASSWORD
export JANUS_2001_PASSWORD JANUS_2002_PASSWORD JANUS_2003_PASSWORD JANUS_2004_PASSWORD
export DOLLAR='$'

mkdir -p "$ROOT_DIR/deploy/generated/asterisk" "$ROOT_DIR/deploy/generated/janus" "$ROOT_DIR/deploy/generated/coturn" "$ROOT_DIR/deploy/generated/nginx"

envsubst < "$ROOT_DIR/deploy/templates/asterisk/pjsip.conf.tpl" > "$ROOT_DIR/deploy/generated/asterisk/pjsip.conf"
envsubst < "$ROOT_DIR/deploy/templates/asterisk/http.conf.tpl" > "$ROOT_DIR/deploy/generated/asterisk/http.conf"
envsubst < "$ROOT_DIR/deploy/templates/asterisk/rtp.conf.tpl" > "$ROOT_DIR/deploy/generated/asterisk/rtp.conf"
envsubst < "$ROOT_DIR/deploy/templates/janus/janus.jcfg.tpl" > "$ROOT_DIR/deploy/generated/janus/janus.jcfg"
envsubst < "$ROOT_DIR/deploy/templates/janus/janus.transport.websockets.jcfg.tpl" > "$ROOT_DIR/deploy/generated/janus/janus.transport.websockets.jcfg"
envsubst < "$ROOT_DIR/deploy/templates/janus/janus.plugin.sip.jcfg.tpl" > "$ROOT_DIR/deploy/generated/janus/janus.plugin.sip.jcfg"
envsubst < "$ROOT_DIR/deploy/templates/coturn/turnserver.conf.tpl" > "$ROOT_DIR/deploy/generated/coturn/turnserver.conf"
envsubst < "$ROOT_DIR/deploy/templates/nginx/softphone-https.conf.tpl" > "$ROOT_DIR/deploy/generated/nginx/softphone-https.conf"

echo "Generated deploy configs for ${PUBLIC_DOMAIN} (${PUBLIC_IP})."
