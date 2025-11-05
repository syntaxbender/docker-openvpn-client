#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

cleanup() {
    kill TERM "$openvpn_pid"
    exit 0
}

mask() {
  local var="$1"
  echo "${var:0:1}$(printf '%*s' $((${#var}-1)) '' | tr ' ' '*')"
}

is_enabled() {
    [[ ${1,,} =~ ^(true|t|yes|y|1|on|enable|enabled)$ ]]
}
echo ""
echo ""

# Either a specific file name or a pattern.
if [[ -z "${CONFIG_FILE:-}" || ! -f "${CONFIG_FILE:-}" ]]; then
    echo "config: ${CONFIG_FILE:-}"
    echo "### OPENVPN CONFIGURATION FILE NOT FOUND! EXITING!" >&2
    exit 1
else
    echo "### USING OPENVPN CONFIGURATION FILE: ${CONFIG_FILE}"
fi

openvpn_args=(
    "--config" "$CONFIG_FILE"
)

if [[ -z "$OVPN_USER" || -z "$OVPN_PASS" ]]; then
    echo "### OPENVPN CREDENTIALS NOT PROVIDED. TRYING WITHOUT CREDENTIALS..." >&2
else
    echo "### USING OPENVPN CREDENTIALS ARE PROVIDED."
    echo "User: $(mask "$OVPN_USER")"
    echo "Pass: $(mask "$OVPN_PASS")"
    CRED_FILE=$(mktemp)
    echo "$OVPN_USER" > "$CRED_FILE"
    echo "$OVPN_PASS" >> "$CRED_FILE"
    openvpn_args+=("--auth-user-pass" "$CRED_FILE")
fi
if is_enabled "$KILL_SWITCH"; then
    echo "### KILLSWITCH ENABLED"
    openvpn_args+=("--route-up" "/usr/local/bin/killswitch.sh $ALLOWED_SUBNETS")
else
    echo "### KILLSWITCH DISABLED"
fi
echo "### STARTING OVPN CLIENT"
echo ""
echo ""
openvpn --version

openvpn "${openvpn_args[@]}" &
openvpn_pid=$!
trap cleanup TERM
wait $openvpn_pid
