general: {
	configs_folder = "/usr/local/etc/janus"
	plugins_folder = "/usr/local/lib/janus/plugins"
	transports_folder = "/usr/local/lib/janus/transports"
	events_folder = "/usr/local/lib/janus/events"
	loggers_folder = "/usr/local/lib/janus/loggers"

	log_to_stdout = true
	debug_level = 4
	admin_secret = "${JANUS_ADMIN_SECRET}"
}

certificates: {
}

media: {
	rtp_port_range = "${JANUS_RTP_PORT_START}-${JANUS_RTP_PORT_END}"
}

nat: {
	nice_debug = false
	nat_1_1_mapping = "${PUBLIC_IP}"
	ice_ignore_list = "vmnet"
}

plugins: {
}

transports: {
}

loggers: {
}

events: {
}
