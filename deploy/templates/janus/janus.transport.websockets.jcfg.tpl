general: {
	json = "indented"
	ws = true
	ws_port = ${JANUS_WS_PORT}
	wss = true
	wss_port = ${JANUS_WSS_PORT}
}

admin: {
	admin_ws = false
	admin_wss = false
}

cors: {
}

certificates: {
	cert_pem = "/etc/letsencrypt/live/${PUBLIC_DOMAIN}/fullchain.pem"
	cert_key = "/etc/letsencrypt/live/${PUBLIC_DOMAIN}/privkey.pem"
}
