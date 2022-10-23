ARG BUILD_FROM
FROM $BUILD_FROM

ENV LANG C.UTF-8

RUN apk update \
    && apk add --no-cache python3 py3-pip
    
RUN pip install -f https://wheels.home-assistant.io/musllinux/ pysnmplib

COPY trap.py /
RUN chmod a+x /trap.py
COPY run.sh /
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]