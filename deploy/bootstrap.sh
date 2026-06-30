#!/usr/bin/env sh
set -eu

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
ENV_FILE="${ENV_FILE:-$ROOT_DIR/.env}"

case "$ENV_FILE" in
  /*) ;;
  *) ENV_FILE="$ROOT_DIR/$ENV_FILE" ;;
esac

if [ ! -f "$ENV_FILE" ]; then
  echo "Env file not found: $ENV_FILE" >&2
  exit 1
fi

set -a
. "$ENV_FILE"
set +a

: "${PUBLIC_DOMAIN:?Set PUBLIC_DOMAIN in .env}"
: "${LETSENCRYPT_PATH:=/etc/letsencrypt}"

CERT_PATH="$LETSENCRYPT_PATH/live/$PUBLIC_DOMAIN/fullchain.pem"

if [ ! -f "$CERT_PATH" ]; then
  "$ROOT_DIR/deploy/issue-letsencrypt.sh"
fi

"$ROOT_DIR/deploy/render-configs.sh"
docker compose --env-file "$ENV_FILE" up -d --build
