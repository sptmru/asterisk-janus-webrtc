server {
  listen 443 ssl http2;
  server_name ${PUBLIC_DOMAIN};

  ssl_certificate /etc/letsencrypt/live/${PUBLIC_DOMAIN}/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/${PUBLIC_DOMAIN}/privkey.pem;
  ssl_protocols TLSv1.2 TLSv1.3;
  ssl_prefer_server_ciphers off;
  ssl_session_cache shared:softphone_ssl:10m;
  ssl_session_timeout 1d;

  add_header Strict-Transport-Security "max-age=31536000" always;
  add_header X-Content-Type-Options nosniff always;
  add_header Referrer-Policy no-referrer always;

  location / {
    proxy_pass http://janus-softphone:80;
    proxy_http_version 1.1;
    proxy_set_header Host ${DOLLAR}host;
    proxy_set_header X-Real-IP ${DOLLAR}remote_addr;
    proxy_set_header X-Forwarded-For ${DOLLAR}proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto https;
  }
}
