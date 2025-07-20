FROM ubuntu:24.04

LABEL maintainer="Fabio Gasso <fabio.grasso@okta.com>"
LABEL org.opencontainers.image.authors="Fabio Gasso <fabio.grasso@okta.com>"
LABEL org.opencontainers.image.version="1.0.0"
LABEL org.opencontainers.image.licenses="Apache-2.0"
LABEL org.opencontainers.image.source="https://github.com/fabiograsso-okta/lab-radius"
LABEL org.opencontainers.image.description="Okta RADIUS Agent"

# Install prereq
RUN apt-get update && apt-get install -y tini  && rm -rf /var/lib/apt/lists/*
# curl sudo bash-completion net-tools
# Copy the agent installer into the image
COPY OktaRadiusAgent*.deb /tmp/okta_agent.deb

# Install the agent - without running the post installation script
RUN dpkg --unpack /tmp/okta_agent.deb && \
    rm /var/lib/dpkg/info/ragent.postinst -f && \
    dpkg --configure ragent

RUN mkdir /usr/local/share/okta_radius_defaults && \
    cp /opt/okta/ragent/user/config/radius/* /usr/local/share/okta_radius_defaults/ && \
    echo "ragent.mfa.timeout.seconds = 180" >> /usr/local/share/okta_radius_defaults/config.properties
    # Increase the timeout to avoid issue during tests

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Set tini as entrypoint
ENTRYPOINT ["/usr/bin/tini", "--"]

EXPOSE 1812

# App command 
CMD ["/usr/local/bin/entrypoint.sh"]
