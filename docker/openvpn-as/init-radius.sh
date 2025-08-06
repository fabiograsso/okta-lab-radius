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
#set -e

echo "[init] ⚠️ Waiting for OpenVPN Access Server to be ready..."

# Wait for sacli to respond (indicating that sockets are ready)
/usr/local/openvpn_as/scripts/sacli Status

while [[ $(/usr/local/openvpn_as/scripts/sacli Status 2>/dev/null | jq '[.service_status[] | select(. != "on")] | length') -ne 0 ]]; do
	sleep 1
done

echo "🏁 [init] OpenVPN is ready."

if [[ -n "${OPENVPN_LICENSE}" ]]; then
	echo "[init] ℹ️ Applying license..."
	/usr/local/openvpn_as/scripts/sacli --key "activation.lic" --value "${OPENVPN_LICENSE}" ConfigPut
fi

# Prepare env vars with defaults
OPENVPN_PASSWORD="${OPENVPN_PASSWORD:-admin}"
RADIUS_SERVER="${RADIUS_SERVER:-okta-radius-agent}"
RADIUS_SECRET="${RADIUS_SECRET:-mysecret123}"
RADIUS_PORT="${RADIUS_PORT:-1812}"
RADIUS_TIMEOUT="${RADIUS_TIMEOUT:-180}"

# Set admin user and auth method
echo "[init] ℹ️ Applying openvpn admin password..."
/usr/local/openvpn_as/scripts/sacli --user "openvpn" --key "prop_superuser" --value "true" UserPropPut
/usr/local/openvpn_as/scripts/sacli --user "openvpn" --key "user_auth_type" --value "local" UserPropPut
/usr/local/openvpn_as/scripts/sacli --user "openvpn" --new_pass "$OPENVPN_PASSWORD" SetLocalPassword

# Configure RADIUS backend
echo "[init] ℹ️ Applying RADIUS configuration..."
/usr/local/openvpn_as/scripts/sacli --key "auth.module.type" --value "radius" ConfigPut
/usr/local/openvpn_as/scripts/sacli --key "auth.radius.0.server.0.host" --value "$RADIUS_SERVER" ConfigPut
/usr/local/openvpn_as/scripts/sacli --key "auth.radius.0.server.0.secret" --value "$RADIUS_SECRET" ConfigPut
/usr/local/openvpn_as/scripts/sacli --key "auth.radius.0.server.0.auth_port" --value "$RADIUS_PORT" ConfigPut
/usr/local/openvpn_as/scripts/sacli --key "auth.radius.0.auth_method" --value "pap" ConfigPut
/usr/local/openvpn_as/scripts/sacli --key "auth.radius.0.enable" --value "True" ConfigPut
/usr/local/openvpn_as/scripts/sacli --key "auth.radius.0.name" --value "OktaRADIUS" ConfigPut
/usr/local/openvpn_as/scripts/sacli --key "auth.radius.0.per_server_timeout" --value "$RADIUS_TIMEOUT" ConfigPut

echo "[init] ✅ RADIUS configuration complete."

# Commit changes and restart
/usr/local/openvpn_as/scripts/sacli Reset
