#!/bin/bash
#
# Author: Fabio Grasso <fabio.grasso@okta.com>
# License: Apache-2.0
# Version: 1.0.0
# Description: Entrypoint docker script to handle the startup or the Okta RADIUS Agent
#
# Usage: ./entrypoint.sh
#
# -----------------------------------------------------------------------------
set -e

JAVA_BIN="/opt/okta/ragent/jre/linux/bin/java"
JAR="/opt/okta/ragent/bin/OKTARadiusAgent.jar"
CONFIG="/opt/okta/ragent/user/config/radius/config.properties"
LOGFILE="/opt/okta/ragent/logs/okta_radius.log"
LOG4J="/opt/okta/ragent/user/config/radius/log4j2.xml"
DEFCONFDIR="/usr/local/share/okta_radius_defaults/"

# If config files don't exist, copy them
if [ ! -f "$CONFIG" ]; then
  echo "Missing config.properties. Copying from /tmp..."
  cp "$DEFCONFDIR/config.properties" "$CONFIG"
  chown OktaRadiusService:OktaRadiusService "$CONFIG"
fi

if [ ! -f "$LOG4J" ]; then
  echo "Missing log4j2.xml. Copying from /tmp..."
  cp "$DEFCONFDIR/log4j2.xml" "$LOG4J"
  chown OktaRadiusService:OktaRadiusService "$LOG4J"
fi

# Trap termination signals to properly stop Java when container stops
trap 'echo "Stopping RADIUS agent..."; kill $JAVA_PID; wait $JAVA_PID' SIGTERM SIGINT

# Start the RADIUS agent in the background
"$JAVA_BIN" -Dlog4j.configurationFile="$LOG4J" -jar "$JAR" "$CONFIG" &
JAVA_PID=$!

# Wait for the log file to appear before tailing
while [ ! -f "$LOGFILE" ]; do
  echo "Waiting for log file to appear at $LOGFILE..."
  sleep 1
done

# Tail the log file to keep the container alive and show output
tail --retry --follow "$LOGFILE" &
TAIL_PID=$!

# Wait for the Java process to exit
wait $JAVA_PID
