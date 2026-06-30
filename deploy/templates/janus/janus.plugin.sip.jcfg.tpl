general: {
	local_ip = "${JANUS_CONTAINER_IP}"
	local_media_ip = "${JANUS_CONTAINER_IP}"
	sdp_ip = "${JANUS_CONTAINER_IP}"
	keepalive_interval = 120
	behind_nat = true
	user_agent = "janus-softphone-sip"
	register_ttl = 3600
	rtp_port_range = "${JANUS_RTP_PORT_START}-${JANUS_RTP_PORT_END}"
	sip_timer_t1x64 = 32000
}
