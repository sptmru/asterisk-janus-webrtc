FROM nginx:1.27-alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY sip.html /usr/share/nginx/html/sip.html
COPY jssip.min.js /usr/share/nginx/html/jssip.min.js
COPY softphone.html /usr/share/nginx/html/softphone.html
COPY janus.js /usr/share/nginx/html/janus.js
COPY adapter.js /usr/share/nginx/html/adapter.js
