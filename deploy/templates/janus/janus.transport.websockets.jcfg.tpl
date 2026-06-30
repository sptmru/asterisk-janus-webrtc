general: {
	json = "indented"
	ws = true
	ws_port = 8188
	wss = true
	wss_port = 8989
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
