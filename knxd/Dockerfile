ARG BUILD_FROM
FROM $BUILD_FROM

ENV LANG C.UTF-8

# Install requirements for add-on
# example from here: https://knx-user-forum.de/forum/projektforen/knxd/1081901-knxd-auf-alpine-linux?p=1084515#post1084515
RUN set -xe \
    && apk update \
    && apk add --no-cache jq git build-base abuild automake autoconf cmake dev86 libtool argp-standalone linux-headers libstdc++ libev-dev libusb-dev \
    && mkdir -p /usr/local/src \
	&& cd /usr/local/src \
    && git clone --branch 0.14.37 --depth 1 https://github.com/knxd/knxd.git \
    && cd knxd \
    && ./bootstrap.sh \
    && ./configure --disable-systemd --enable-ft12 --enable-tpuart --enable-usb --enable-eibnetipserver --enable-eibnetip --enable-eibnetserver --enable-eibnetiptunnel \
    && mkdir -p src/include/sys \
    && ln -s /usr/lib/bcc/include/sys/cdefs.h src/include/sys \
    && make \
    && make install \
    && cd .. \
    && rm -rf knxd \
    && apk del git build-base abuild automake autoconf cmake dev86 libtool argp-standalone linux-headers

# Copy data for add-on
COPY run.sh /
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]