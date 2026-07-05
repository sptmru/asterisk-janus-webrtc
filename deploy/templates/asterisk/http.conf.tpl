[general]
enabled=yes
bindaddr=0.0.0.0
bindport=${ASTERISK_HTTP_PORT}

tlsenable=yes
tlsbindaddr=0.0.0.0:${ASTERISK_WSS_PORT}
tlscertfile=/etc/letsencrypt/live/${PUBLIC_DOMAIN}/fullchain.pem
tlsprivatekey=/etc/letsencrypt/live/${PUBLIC_DOMAIN}/privkey.pem
