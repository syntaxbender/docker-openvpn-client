#!/bin/sh

set -eu

SQUID_AUTH_USER=${SQUID_AUTH_USER:-squiduser}
SQUID_AUTH_PASS=${SQUID_AUTH_PASS:-123456}
cleanup() {
    kill TERM "$openvpn_pid"
    exit 0
}
create_dir() {
  directory="$1"
  if [ ! -d "$directory" ]; then
    mkdir -p "$directory"
  fi
  chown -R "$SQUID_USER:$SQUID_USER" "$directory"
  chmod 750 "$directory"
}

# create_missing_certs() {
#   if [ ! -f "${SQUID_DIR_SSL}/squid.crt" ]; then
#     echo ""
#     echo "### CREATING CERTIFICATES ###"
# #     openssl req -x509 -newkey rsa:4096 \
# #       -keyout "${SQUID_DIR_SSL}/bump.key" \
# #       -out "${SQUID_DIR_SSL}/bump.crt" \
# #       -sha256 -days 3650 -nodes -subj "$SQUID_CERT_CN"
#     openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 -subj "$SQUID_CERT_CN" -keyout "${SQUID_DIR_SSL}/bump.key" -out "${SQUID_DIR_SSL}/bump.crt"
#     openssl dhparam -outform PEM -out "${SQUID_DIR_SSL}/bump.dh.pem" "$SQUID_DH_SIZE"
#   fi
# }

# create_missing_ssldb() {
#   if [ ! -f "${SQUID_DIR_SSLDB}/index.txt" ]; then
#     echo ""
#     echo "### CREATING SSL-DB ###"
#     rm -rf "$SQUID_DIR_SSLDB"
#     /usr/lib/squid/security_file_certgen -c -s "$SQUID_DIR_SSLDB" -M "$SQUID_SSLDB_SIZE"
#     chown -R "$SQUID_USER:$SQUID_USER" "${SQUID_DIR_SSLDB}"
#     chmod 750 "$SQUID_DIR_SSLDB"
#   fi
# }

create_missing_logfile() {
  logfile="${SQUID_DIR_LOG}/$1"
  if [ ! -f "$logfile" ]; then
    touch "$logfile"
    chown "$SQUID_USER:$SQUID_USER" "$logfile"
    chmod 640 "$logfile"
  fi
}

create_dir "$SQUID_DIR_LOG"
create_dir "$SQUID_DIR_CACHE"
# create_dir "$SQUID_DIR_SSL"
create_dir "$SQUID_DIR_LIB"
# create_missing_certs
# create_missing_ssldb

# Eğer şifre environment'tan gelmemişse, interaktif iste
# if [ -z "$SQUID_AUTH_PASS" ]; then
#   echo -n "🧩 Şifre gir (${SQUID_AUTH_USER}): "
#   stty -echo
#   read SQUID_AUTH_PASS
#   stty echo
#   echo ""
# fi

echo ""
echo "### CREATING SQUID PASSWORD FILE..."
htpasswd -bc "$PASSWD_FILE" "$SQUID_AUTH_USER" "$SQUID_AUTH_PASS"
chown squid:squid "$PASSWD_FILE"
chmod 640 "$PASSWD_FILE"

# docker logs
if [ "${SQUID_DOCKER_LOGS}" = "yes" ]; then
  create_missing_logfile "access.log"
  create_missing_logfile "error.log"
  tail -F "${SQUID_DIR_LOG}/access.log" 2>/dev/null &
  tail -F "${SQUID_DIR_LOG}/error.log" 2>/dev/null &
  if [ "${SQUID_DOCKER_LOGS_CACHE}" = "yes" ]; then
    create_missing_logfile "cache.log"
    create_missing_logfile "store.log"
    tail -F "${SQUID_DIR_LOG}/cache.log" 2>/dev/null &
    tail -F "${SQUID_DIR_LOG}/store.log" 2>/dev/null &
  fi
fi

SQUID="$(command -v squid)"
CONFIG="${SQUID_DIR_CONF}/squid.conf"

echo ""
echo "### DEBUG INFO ###"
echo "LIB DIR: '${SQUID_DIR_LIB}'"
# echo "SSL DIR: '${SQUID_DIR_SSL}'"
# echo "SSL-DB DIR: '${SQUID_DIR_SSLDB}'"
echo "LOG DIR: '${SQUID_DIR_LOG}'"
echo "CACHE DIR: '${SQUID_DIR_CACHE}'"
apk info squid 2>/dev/null || echo "squid not installed"
"$SQUID" -v

echo ""
echo "### CREATING MISSING CACHE DIRECTORIES ###"
"$SQUID" -N -f "$CONFIG" -z

echo ""
echo "### CHECKING CONFIG ###"
"$SQUID" -f "$CONFIG" -k parse

echo ""
echo "### STARTING SQUID ###"

exec "$SQUID" -f "$CONFIG" -NYCd 1 &
squid_pid=$!
trap cleanup TERM

wait $squid_pid