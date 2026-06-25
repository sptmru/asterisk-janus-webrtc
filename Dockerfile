FROM nginx:1.27-alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY softphone.html /usr/share/nginx/html/softphone.html
COPY janus.js /usr/share/nginx/html/janus.js
COPY adapter.js /usr/share/nginx/html/adapter.js
