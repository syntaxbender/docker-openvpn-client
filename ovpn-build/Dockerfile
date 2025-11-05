FROM alpine:latest

RUN apk add --no-cache \
    bash \
    bind-tools \
    iptables \
    ip6tables \
    openvpn

COPY ./files /usr/local/bin

ENV KILL_SWITCH=on

ENTRYPOINT [ "entrypoint.sh" ]
