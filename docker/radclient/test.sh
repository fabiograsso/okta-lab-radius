#!/bin/bash
#
# Author: Fabio Grasso <fabio.grasso@okta.com>
# License: Apache-2.0
# Version: 1.0.0
# Description: Script to test a RADIUS authentication within the Okta RADIUS Agent,
#              using radclient CLI, and parsing the response to ask additional input
#              if requested by the RADIUS server (i.e. choose the MFA factor)
#
# Usage: ./test.sh [username] [password] [server] [secret] [port] [ip]
#        if args are omitted then:
#        1. Uses .env variables: TEST_USERNAME, TEST_PASSWORD, RADIUS_SERVER, RADIUS_SECRET, RADIUS_PORT
#        2. Prompt the user
#
# -----------------------------------------------------------------------------

echo ""
echo "############################ RADIUS Test Client ##############################"
echo "#                                                                             #"
echo "# This script sends a RADIUS authentication request using radclient.          #"
echo "#                                                                             #"
echo "###############################################################################"
echo ""

# 1. Try command line arguments ($1, $2, ...)
# 2. If arguments are empty, try environment variables (e.g., $TEST_USERNAME, $TEST_PASSWORD, ...)
# 3. If still empty, prompt the user

# TEST_USERNAME
if [[ -n "$1" ]]; then                    # Option 1: Argument provided
  TEST_USERNAME="$1"
  echo "User-Name: $TEST_USERNAME"
elif [[ -n "${TEST_USERNAME}" ]]; then    # Option 2: Environment variable provided
  TEST_USERNAME="${TEST_USERNAME}"
  echo "User-Name: $TEST_USERNAME"
else                                      # Option 3: No argument or env var, ask the user with a default
  : "${TEST_USERNAME:=testuser@atko.email}"
  read -p "User-Name [$TEST_USERNAME]: " input
  TEST_USERNAME=${input:-$TEST_USERNAME}
fi

# TEST_PASSWORD
if [[ -n "$2" ]]; then                    # Option 1: Argument provided
  TEST_PASSWORD="$2"
  echo "User-Password: $TEST_PASSWORD"
elif [[ -n "${TEST_PASSWORD}" ]]; then    # Option 2: Environment variable provided
  TEST_PASSWORD="${TEST_PASSWORD}"
  echo "User-Password: $TEST_PASSWORD"
else                                      # Option 3: No argument or env var, ask the user with a default
  : "${TEST_PASSWORD:=testpassword}"
  read -p "User-Password [$TEST_PASSWORD]: " input
  TEST_PASSWORD=${input:-$TEST_PASSWORD}
fi

# RADIUS_SERVER
if [[ -n "$3" ]]; then                    # Option 1: Argument provided
  RADIUS_SERVER="$3"
  echo "Radius Server Address: $RADIUS_SERVER"
elif [[ -n "${RADIUS_SERVER}" ]]; then    # Option 2: Environment variable provided
  RADIUS_SERVER="${RADIUS_SERVER}"
  echo "Radius Server Address: $RADIUS_SERVER"
else                                      # Option 3: No argument or env var, ask the user with a default
  : "${RADIUS_SERVER:=okta-radius-agent}"
  read -p "Radius Server Address [$RADIUS_SERVER]: " input
  RADIUS_SERVER=${input:-$RADIUS_SERVER}
fi

# RADIUS_SECRET
if [[ -n "$4" ]]; then                    # Option 1: Argument provided
  RADIUS_SECRET="$4"
  echo "Radius Server Secret: $RADIUS_SECRET"
elif [[ -n "${RADIUS_SECRET}" ]]; then    # Option 2: Environment variable provided
  RADIUS_SECRET="${RADIUS_SECRET}"
  echo "Radius Server Secret: $RADIUS_SECRET"
else                                      # Option 3: No argument or env var, ask the user with a default
  : "${RADIUS_SECRET:=test123}"
  read -p "Radius Server Secret [$RADIUS_SECRET]: " input
  RADIUS_SECRET=${input:-$RADIUS_SECRET}
fi

# RADIUS_PORT
if [[ -n "$5" ]]; then                    # Option 1: Argument provided
  RADIUS_PORT="$5"
  echo "Radius Server Port: $RADIUS_PORT"
elif [[ -n "${RADIUS_PORT}" ]]; then    # Option 2: Environment variable provided
  RADIUS_PORT="${RADIUS_PORT}"
  echo "Radius Server Port: $RADIUS_PORT"
else                                      # Option 3: No argument or env var, ask the user with a default
  : "${RADIUS_PORT:=1812}"
  read -p "Radius Server Port [$RADIUS_PORT]: " input
  RADIUS_PORT=${input:-$RADIUS_PORT}
fi

# TEST_IP
if [[ -n "$6" ]]; then                    # Option 1: Argument provided
  TEST_IP="$6"
  echo "IP Address (NAS-IP-Address): $TEST_IP"
elif [[ -n "${TEST_IP}" ]]; then    # Option 2: Environment variable provided
  TEST_IP="${TEST_IP}"
  echo "IP Address (NAS-IP-Address): $TEST_IP"
else                                      # Option 3: No argument or env var, ask the user with a default
  TEST_IP=$(curl -s http://checkip.amazonaws.com || echo "127.0.0.1")
  echo "IP Address (NAS-IP-Address): $TEST_IP"
#  read -p "IP Address (NAS-IP-Address) [$TEST_IP]: " input
#  TEST_IP=${input:-$TEST_IP}
fi

echo ""
echo "Sending RADIUS authentication request..."
echo ""

output=$(printf 'User-Name = "%s"
User-Password = "%s"
NAS-IP-Address = %s
' "$TEST_USERNAME" "$TEST_PASSWORD" "$TEST_IP" | \
  radclient -x "$RADIUS_SERVER:$RADIUS_PORT" auth "$RADIUS_SECRET")

echo -e "\n\033[1;36mRaw server response:\033[0m"
echo "$output"


# MFA Challenge loop
while echo "$output" | grep -q "Access-Challenge"; do
  echo ""
  echo -e "\n\033[1;36mOutcome:\033[0m Multi-factor challenge received."

  # Extract State
  STATE=$(echo "$output" | grep State | awk '{print $3}' | tail -n 1)

  # Extract Reply-Message (may span multiple lines)
  REPLY_MSG=$(echo "$output" | awk -F'Reply-Message = ' '/Reply-Message/ {gsub(/^"|"$/, "", $2); print $2}' | sed 's/\\n/\n/g') || true
  if [[ -n "$REPLY_MSG" ]]; then
    echo -e "\n\033[1;36mServer reply:\033[0m $REPLY_MSG\n"
  fi

  # Prompt user
  while true; do
    read -p "Enter your response based on the server's instructions: " MFA_RESPONSE
    if [[ -n "$MFA_RESPONSE" ]]; then
        break
    else
        echo "Response cannot be empty. Please try again."
    fi
  done

  echo ""
  echo "Sending RADIUS response with MFA input..."
  echo ""
  output=$(printf 'User-Name = "%s"
User-Password = "%s"
State = "%s"
NAS-IP-Address = %s
' "$TEST_USERNAME" "$MFA_RESPONSE" "$STATE" "$TEST_IP" | \
    radclient -x "$RADIUS_SERVER:$RADIUS_PORT" auth "$RADIUS_SECRET")
  echo -e "\n\033[1;36mRaw server response:\033[0m"
  echo "$output"
done

# Extract Reply-Message
REPLY_MSG=$(echo "$output" | awk -F'Reply-Message = ' '/Reply-Message/ {gsub(/^"|"$/, "", $2); print $2}' | sed 's/\\n/\n/g') || true

if [[ -n "$REPLY_MSG" ]]; then
  echo -e "\n\033[1;36mServer reply:\033[0m $REPLY_MSG"
  echo -ne "\n\033[1;36mFinal outcome:\033[0m "
  # Check final outcome
  if echo "$REPLY_MSG" | grep -qiE "authentication failed|access denied"; then
    echo -e "\033[1;31m❌ Authentication failed.\033[0m"
  elif echo "$REPLY_MSG" | grep -qi "welcome"; then
    echo -e "\033[1;32m✅ Authentication succeeded.\033[0m"
  else
    echo -e "\033[1;33m⚠️ Authentication outcome unclear.\033[0m"
  fi
else
  echo -e "\033[1;33m⚠️ No Reply-Message found in the response.\033[0m"
fi
echo ""
echo ""