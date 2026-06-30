listening-port=${TURN_PORT}
tls-listening-port=${TURN_TLS_PORT}
listening-ip=${INTERNAL_IP}
relay-ip=${INTERNAL_IP}
external-ip=${PUBLIC_IP}/${INTERNAL_IP}

realm=${TURN_REALM}
server-name=${PUBLIC_DOMAIN}
fingerprint
lt-cred-mech
user=${TURN_USERNAME}:${TURN_PASSWORD}

min-port=${TURN_MIN_PORT}
max-port=${TURN_MAX_PORT}

cert=/etc/letsencrypt/live/${PUBLIC_DOMAIN}/fullchain.pem
pkey=/etc/letsencrypt/live/${PUBLIC_DOMAIN}/privkey.pem

no-cli
no-loopback-peers
no-multicast-peers
no-tcp-relay
log-file=stdout
simple-log
