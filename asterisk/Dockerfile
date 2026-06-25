FROM ubuntu:22.04

RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    asterisk \
    asterisk-moh-opsound-wav \
    ca-certificates \
    curl \
  && rm -rf /var/lib/apt/lists/*

RUN set -eux; \
  curl -fsSL https://downloads.digium.com/pub/telephony/codec_opus/asterisk-18.0/x86-64/codec_opus-18.0_current-x86_64.tar.gz \
    | tar -xz -C /tmp; \
  cp /tmp/codec_opus-18.0_1.3.0-x86_64/codec_opus.so /usr/lib/x86_64-linux-gnu/asterisk/modules/codec_opus.so; \
  mkdir -p /var/lib/asterisk/documentation/thirdparty; \
  mkdir -p /usr/share/asterisk/documentation/thirdparty; \
  cp /tmp/codec_opus-18.0_1.3.0-x86_64/codec_opus_config-en_US.xml /var/lib/asterisk/documentation/thirdparty/; \
  cp /tmp/codec_opus-18.0_1.3.0-x86_64/codec_opus_config-en_US.xml /usr/share/asterisk/documentation/thirdparty/; \
  rm -rf /tmp/codec_opus-18.0_1.3.0-x86_64

COPY config/ /etc/asterisk/

EXPOSE 5060/udp 5060/tcp 8088/tcp 8089/tcp 10000-10100/udp

CMD ["asterisk", "-f", "-vvv"]
