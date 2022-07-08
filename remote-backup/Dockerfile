ARG BUILD_FROM
FROM $BUILD_FROM

# Add env
ENV LANG C.UTF-8

# Setup base
RUN apk add --no-cache jq openssh-client

# Hass.io CLI
ARG BUILD_ARCH
RUN apk add --no-cache curl \
    && curl -Lso /usr/bin/ha https://github.com/home-assistant/cli/releases/download/4.18.0/ha_${BUILD_ARCH} \
    && chmod a+x /usr/bin/ha

# Copy data
COPY run.sh /
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]
