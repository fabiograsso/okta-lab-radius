FROM debian:12-slim

LABEL maintainer="Fabio Gasso <fabio.grasso@okta.com>"
LABEL org.opencontainers.image.authors="Fabio Gasso <fabio.grasso@okta.com>"
LABEL org.opencontainers.image.version="1.0.0"
LABEL org.opencontainers.image.licenses="Apache-2.0"
LABEL org.opencontainers.image.source="https://github.com/fabiograsso/okta-lab-radius"
LABEL org.opencontainers.image.description="Okta RADIUS Agent"

ARG DEB_URL

RUN apt-get update -qq && apt-get install -y -qq --no-install-recommends tini net-tools freeradius-utils curl && rm -rf /var/lib/apt/lists/* && rm -rf /var/log/apt && rm -rf /var/log/dpkg.log

COPY package/ /tmp/package/
COPY ./entrypoint.sh /usr/local/bin/entrypoint.sh
COPY ./test-radius.sh /usr/local/bin/test-radius.sh

RUN \
    if [ -z "$(find /tmp/package/ -name '*.deb' -print -quit)" ]; then \
        echo "--> Local .deb not found. Downloading from ${DEB_URL}..." && \
        FILENAME=$(basename "${DEB_URL}") && \
        curl -fSL -o "/tmp/package/${FILENAME}" "${DEB_URL}"; \
    fi && \
    dpkg --unpack /tmp/package/*.deb && \
    rm /var/lib/dpkg/info/ragent.postinst -f && \
    dpkg --configure ragent && \
    mkdir /usr/local/share/okta_radius_defaults && \
    cp /opt/okta/ragent/user/config/radius/* /usr/local/share/okta_radius_defaults/ && \
    echo "ragent.mfa.timeout.seconds = 180" >> /usr/local/share/okta_radius_defaults/config.properties && \
    chmod +x /usr/local/bin/entrypoint.sh && \
    chmod +x /usr/local/bin/test-radius.sh && \
    ln -sf /usr/local/bin/test-radius.sh /usr/local/bin/test && \
    ln -sf /usr/local/bin/test-radius.sh /usr/local/bin/test-radius $$ \
    rm -rf /tmp/package/ && rm -rf /var/lib/apt/lists/* && rm -rf /var/log/apt && rm -rf /var/log/dpkg.log
    
ENTRYPOINT ["/usr/bin/tini", "--"]

EXPOSE 1812

CMD ["/usr/local/bin/entrypoint.sh"]