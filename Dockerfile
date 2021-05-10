# - Server
# docker images
# docker build -t easysoft/clamav:latest .
# docker run --name "clamav" -p 3310:3310 easysoft/clamav
# docker exec -it "clamav" /usr/local/sbin/clamav-unofficial-sigs.sh
# - Client
# dotnet run

FROM alpine:3.13
LABEL maintainer="Thomas Spicer (thomas@openbridge.com)"
LABEL maintainer="Éric Louvard (e.louvard@easysoft.de)"

ENV CLAMD_DEPS \
        linux-headers
RUN set -x \
    && apk add --no-cache --virtual .persistent-deps \
        bash \
        coreutils \
        wget \
        findutils \
        perl \
        curl \
        clamav-daemon \
        clamav-libunrar \
        freshclam \
        monit \
        ncurses \
        rsync \
        bind-tools \
        git \
    && apk add --no-cache --virtual .build-deps \
        $CLAMD_DEPS \
    && chmod +x /usr/bin/ \
    && mkdir -p /var/lib/clamav /run/clamav/ \
    && chown -R clamav:clamav /var/lib/clamav/ \
    && apk del .build-deps

COPY usr/bin/crond.sh /usr/bin/cron
COPY usr/bin/clamd.sh /usr/bin/clam
COPY etc/ /etc/
COPY tests/ /tests/
COPY docker-entrypoint.sh /docker-entrypoint.sh

RUN chmod -R +x /docker-entrypoint.sh /usr/local/bin /usr/bin /tests

RUN mkdir -p /usr/local/sbin/ \
    && mkdir -p /etc/clamav-unofficial-sigs/
COPY clamav-unofficial-sigs/clamav-unofficial-sigs.sh /usr/local/sbin/clamav-unofficial-sigs.sh
COPY clamav-unofficial-sigs/config/master.conf /etc/clamav-unofficial-sigs/master.conf
COPY clamav-unofficial-sigs/config/user.conf /etc/clamav-unofficial-sigs/user.conf
COPY clamav-unofficial-sigs/config/os/os.alpine.conf /etc/clamav-unofficial-sigs/os.conf
RUN chmod 755 /usr/local/sbin/clamav-unofficial-sigs.sh
# Skript muss run in running container to update signtures
# docker exec -it 9774237a8c53 /usr/local/sbin/clamav-unofficial-sigs.sh

EXPOSE 3310

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/usr/sbin/clamd", "-c", "/etc/clamd.conf"]
