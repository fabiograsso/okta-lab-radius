FROM openvpn/openvpn-as:latest

LABEL maintainer="Fabio Gasso <fabio.grasso@okta.com>"
LABEL org.opencontainers.image.authors="Fabio Gasso <fabio.grasso@okta.com>"
LABEL org.opencontainers.image.version="1.0.0"
LABEL org.opencontainers.image.licenses="Apache-2.0"
LABEL org.opencontainers.image.source="https://github.com/fabiograsso-okta/lab-radius"
LABEL org.opencontainers.image.description="Modified OpenLDAP to auto-configure RADIUS settings"

# Copy custom init script
COPY ./init-radius.sh /init-radius.sh

# Ensure it's executable
RUN chmod +x /init-radius.sh

RUN ln /var/log/openvpnas.log /var/log/openvpn/openvpnas.log

# Set default CMD that starts init in background and then OpenVPN
CMD ["/bin/bash", "-c", "/init-radius.sh & exec /usr/local/openvpn_as/scripts/openvpnas --nodaemon --pidfile=/ovpn/tmp/openvpn.pid"]
