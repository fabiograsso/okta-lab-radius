FROM ubuntu:24.04

LABEL maintainer="Fabio Gasso <fabio.grasso@okta.com>"
LABEL org.opencontainers.image.authors="Fabio Gasso <fabio.grasso@okta.com>"
LABEL org.opencontainers.image.version="1.0.0"
LABEL org.opencontainers.image.licenses="Apache-2.0"
LABEL org.opencontainers.image.source="https://github.com/fabiograsso-okta/lab-radius"
LABEL org.opencontainers.image.description="Simple Ubuntu servr with freeradius-utils (radclient)"

RUN apt-get update && apt-get install -y freeradius-utils curl && rm -rf /var/lib/apt/lists/*

COPY ./test.sh /usr/local/bin/test
RUN chmod +x /usr/local/bin/test

CMD ["/usr/local/bin/test"]