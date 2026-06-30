[general]
enabled=yes
bindaddr=0.0.0.0
bindport=8088

tlsenable=yes
tlsbindaddr=0.0.0.0:8089
tlscertfile=/etc/letsencrypt/live/${PUBLIC_DOMAIN}/fullchain.pem
tlsprivatekey=/etc/letsencrypt/live/${PUBLIC_DOMAIN}/privkey.pem
