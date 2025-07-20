#!/bin/bash
#
# Author: Fabio Grasso <fabio.grasso@okta.com>
# Version: 1.0.0
# License: Apache-2.0
# Description: Entrypoint docker script to apply RADIUS configuration
#              on OpenVPN AS and set the "openvpn" admin user password,
#              using environment variables as params.
#
# Usage: ./init-radius.sh
#
# -----------------------------------------------------------------------------
set -e

echo "[init] Waiting for OpenVPN Access Server to be ready..."

# Wait for sacli to respond (indicating that sockets are ready)
until /usr/local/openvpn_as/scripts/sacli Status 2>/dev/null; do
  echo "[init] Waiting for OpenVPN Access Server to be ready..."
  sleep 1
done

echo "[init] OpenVPN is ready. Applying RADIUS configuration..."

# Set default parameters
"${RADIUS_SERVER:=okta-radius-agent}"
"${RADIUS_PORT:=1812}"
"${RADIUS_SECRET:=test123}"
"${RADIUS_TIMEOUT:=180}"
"${OPENVPN_PASSWORD:=admin}"

/usr/local/openvpn_as/scripts/sacli --user openvpn --new_pass "${OPENVPN_PASSWORD}" SetLocalPassword 
/usr/local/openvpn_as/scripts/sacli --key "auth.module.type" --value "radius" ConfigPut
/usr/local/openvpn_as/scripts/sacli --key "auth.radius.0.server.0.host" --value "${RADIUS_SERVER}" ConfigPut
/usr/local/openvpn_as/scripts/sacli --key "auth.radius.0.server.0.secret" --value "${RADIUS_SECRET}" ConfigPut
/usr/local/openvpn_as/scripts/sacli --key "auth.radius.0.server.0.auth_port" --value "${RADIUS_PORT}" ConfigPut
/usr/local/openvpn_as/scripts/sacli --key "auth.radius.0.auth_method" --value "pap" ConfigPut
/usr/local/openvpn_as/scripts/sacli --key "auth.radius.0.enable" --value "True" ConfigPut
/usr/local/openvpn_as/scripts/sacli --key "auth.radius.0.name" --value "OktaRADIUS" ConfigPut
/usr/local/openvpn_as/scripts/sacli --key "auth.radius.0.per_server_timeout" --value "${RADIUS_TIMEOUT}" ConfigPut

# Commit and restart OpenVPN service
/usr/local/openvpn_as/scripts/sacli start

echo "[init] RADIUS configuration complete."


# if /usr/local/openvpn_as/scripts/sacli --user "$USERNAME" UserPropGet 2>&1 | grep -q 'No such user'; then
#  echo "User $USERNAME does not exist. Creating..."
#  /usr/local/openvpn_as/scripts/sacli --user "$USERNAME" UserPropPut
#  /usr/local/openvpn_as/scripts/sacli --user "$USERNAME" --key prop_autologin --value false UserPropPut
#else
#  echo "User $USERNAME already exists."
#fi