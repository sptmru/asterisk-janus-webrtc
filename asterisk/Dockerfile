FROM ubuntu:22.04

RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    asterisk \
    ca-certificates \
  && rm -rf /var/lib/apt/lists/*

COPY config/ /etc/asterisk/

EXPOSE 5060/udp 5060/tcp 8088/tcp 8089/tcp 10000-10100/udp

CMD ["asterisk", "-f", "-vvv"]
