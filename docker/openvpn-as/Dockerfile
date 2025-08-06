FROM openvpn/openvpn-as:latest

LABEL maintainer="Fabio Gasso <fabio.grasso@okta.com>"
LABEL org.opencontainers.image.authors="Fabio Gasso <fabio.grasso@okta.com>"
LABEL org.opencontainers.image.version="1.0.0"
LABEL org.opencontainers.image.licenses="Apache-2.0"
LABEL org.opencontainers.image.source="https://github.com/fabiograsso/okta-lab-radius"
LABEL org.opencontainers.image.description="Modified OpenLDAP to auto-configure RADIUS settings and radclient"

RUN apt-get update -qq && apt-get install -qq -y net-tools freeradius-utils curl jq && rm -rf /var/lib/apt/lists/* && rm -rf /var/log/apt && rm -rf /var/log/dpkg.log

# Copy custom scripts
COPY ./init-radius.sh /usr/local/bin/init-radius.sh

# Ensure executable
RUN chmod +x /usr/local/bin/init-radius.sh && \
    mkdir -p /var/log/openvpn && \
    ln -sf /var/log/openvpnas.log /var/log/openvpn/openvpnas.log

# Set default CMD that starts init in background and then OpenVPN
CMD ["/bin/bash", "-c", "/usr/local/bin/init-radius.sh & \
                         exec /usr/local/openvpn_as/scripts/openvpnas --nodaemon --pidfile=/ovpn/tmp/openvpn.pid"]
