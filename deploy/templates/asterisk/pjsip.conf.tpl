[global]
type=global
user_agent=janus-softphone-asterisk

[transport-udp]
type=transport
protocol=udp
bind=0.0.0.0:${ASTERISK_SIP_PORT}
${ASTERISK_LOCAL_NET_LINES}

[transport-wss]
type=transport
protocol=wss
bind=0.0.0.0:${ASTERISK_WSS_PORT}
external_media_address=${PUBLIC_IP}
external_signaling_address=${PUBLIC_DOMAIN}
${ASTERISK_LOCAL_NET_LINES}

[webrtc-endpoint](!)
type=endpoint
context=webrtc
transport=transport-wss
disallow=all
allow=opus
allow=ulaw
allow=alaw
webrtc=yes
direct_media=no
force_rport=yes
rewrite_contact=yes
rtp_symmetric=yes
ice_support=yes
media_use_received_transport=yes
rtcp_mux=yes
dtls_auto_generate_cert=yes
dtls_verify=fingerprint
dtls_setup=actpass
dtls_rekey=0
send_pai=yes
send_rpid=yes
trust_id_inbound=yes
trust_id_outbound=yes
moh_suggest=default

[janus-endpoint](!)
type=endpoint
context=webrtc
transport=transport-udp
disallow=all
allow=opus
allow=g722
allow=ulaw
allow=alaw
codec_prefs_incoming_offer=prefer:configured,operation:intersect,keep:first,transcode:allow
codec_prefs_outgoing_answer=prefer:configured,operation:intersect,keep:first,transcode:allow
direct_media=no
force_rport=yes
rewrite_contact=yes
rtp_symmetric=yes
dtmf_mode=rfc4733
send_pai=yes
send_rpid=yes
trust_id_inbound=yes
trust_id_outbound=yes
moh_suggest=default

[1001](webrtc-endpoint)
auth=1001
aors=1001
callerid=WebRTC 1001 <1001>

[1001]
type=auth
auth_type=userpass
username=1001
password=${WEBRTC_1001_PASSWORD}

[1001]
type=aor
max_contacts=1
remove_existing=yes
qualify_frequency=0

[1002](webrtc-endpoint)
auth=1002
aors=1002
callerid=WebRTC 1002 <1002>

[1002]
type=auth
auth_type=userpass
username=1002
password=${WEBRTC_1002_PASSWORD}

[1002]
type=aor
max_contacts=1
remove_existing=yes
qualify_frequency=0

[2001](janus-endpoint)
auth=2001
aors=2001
callerid=Janus 2001 <2001>

[2001]
type=auth
auth_type=userpass
username=2001
password=${JANUS_2001_PASSWORD}

[2001]
type=aor
max_contacts=2
remove_existing=yes
qualify_frequency=0

[2002](janus-endpoint)
auth=2002
aors=2002
callerid=Janus 2002 <2002>

[2002]
type=auth
auth_type=userpass
username=2002
password=${JANUS_2002_PASSWORD}

[2002]
type=aor
max_contacts=2
remove_existing=yes
qualify_frequency=0

[2003](janus-endpoint)
auth=2003
aors=2003
callerid=Janus 2003 <2003>

[2003]
type=auth
auth_type=userpass
username=2003
password=${JANUS_2003_PASSWORD}

[2003]
type=aor
max_contacts=2
remove_existing=yes
qualify_frequency=0

[2004](janus-endpoint)
auth=2004
aors=2004
callerid=Janus 2004 <2004>

[2004]
type=auth
auth_type=userpass
username=2004
password=${JANUS_2004_PASSWORD}

[2004]
type=aor
max_contacts=2
remove_existing=yes
qualify_frequency=0
