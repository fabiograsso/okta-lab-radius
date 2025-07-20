FROM ubuntu:24.04

# Set environment variables to avoid tzdata prompt
ENV DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC
# avoid tput warnings
ENV TERM=xterm

# Install necessary packages for Radlogin v4 to run
RUN apt-get update && \
    apt-get install -y curl python3 python3-pip  && \
    rm -rf /var/lib/apt/lists/*


WORKDIR /tmp/radius/

RUN curl -k -o radlogin4_linux_x64.tar.gz "https://www.iea-software.com/ftp/radiusv5/linux/radlogin4_linux_x64.tar.gz"  && \
    tar -xf radlogin4_linux_x64.tar.gz && \
    printf "C\n" | ./install.pl && \
    rm -rf /tmp/radius

WORKDIR /usr/local/radius/

COPY <<EOF /usr/local/radius/radiusd.ini
[RadiusNT]
continue=>> Continue
rlthreads=10
rlmonitorrefresh=3
rlsmtp=mail
rlastapi=0
rldefaultserver=okta-radius-agent
rldefaultprof=Authentication
rldateformat=7
rldatesep=/
rlport=8020
rlmailsubject=[RADLOGIN] \$\$name is \$\$status
Mode=1
CacheRootDirectory=/usr/local/radius/cache
AcctDirectory=/usr/local/radius/acct
DataDirectory=/usr/local/radius
LogDir=/usr/local/radius/log
AuthPort=1812
AcctPort=1813
EOF

# Expose the default web interface port
EXPOSE 8020

CMD ["/bin/sh", "-c", "/usr/local/radius/radlogin && tail -f /dev/null"]
#tail --retry --follow "$LOGFILE" &

# Copy radlogin/radlogin -> /usr/local/radius/radlogin (radlogin server) [OK]
# Copy radlogin/radiusd.ini -> /usr/local/radius/radiusd.ini (Configuration file) [OK]
# Copy radlogin/radloginv4.pdf -> /usr/local/radius/radloginv4.pdf (Documentation) [OK]
# Copy radlogin/dictionary -> /usr/local/radius/dictionary (RADIUS Dictionary) [OK]
# Copy radlogin/radlogin_init -> /etc/init.d/radlogin (Startup script) [OK]
# Copy radlogin/radlogin.service -> /etc/init.d/radlogin.service (Startup script) [OK]
