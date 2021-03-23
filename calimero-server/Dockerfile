ARG BUILD_FROM
FROM $BUILD_FROM as build

ENV LANG C.UTF-8

# https://stackoverflow.com/a/57145029 --> explicitly add jmods
RUN apk update \
    && apk add --no-cache openjdk11-jdk openjdk11-jmods wget unzip zip build-base linux-headers lockdev

RUN /usr/lib/jvm/java-11-openjdk/bin/jlink \
    --verbose \
    --add-modules java.base \
    --compress 2 \
    --strip-debug \
    --no-header-files \
    --no-man-pages \
    --output /opt/jdk

# download jars and recompile serial library for Alpine musl
RUN mkdir -p /opt/calimero/ \
    && cd /opt/calimero/ \
    && wget https://oss.sonatype.org/service/local/repositories/releases/content/com/github/calimero/calimero-server/2.5-M1/calimero-server-2.5-M1.jar \
    && wget https://oss.sonatype.org/service/local/repositories/releases/content/com/github/calimero/calimero-core/2.5-M1/calimero-core-2.5-M1.jar \
    && wget https://oss.sonatype.org/service/local/repositories/releases/content/com/github/calimero/calimero-device/2.5-M1/calimero-device-2.5-M1.jar \
    && wget https://oss.sonatype.org/service/local/repositories/releases/content/com/github/calimero/calimero-rxtx/2.5-M1/calimero-rxtx-2.5-M1.jar \
    && wget https://github.com/NeuronRobotics/nrjavaserial/releases/download/5.2.1/nrjavaserial-5.2.1.jar \
    && wget https://oss.sonatype.org/service/local/repositories/releases/content/org/slf4j/slf4j-api/1.8.0-beta4/slf4j-api-1.8.0-beta4.jar \
    && wget https://oss.sonatype.org/service/local/repositories/releases/content/org/slf4j/slf4j-simple/1.8.0-beta4/slf4j-simple-1.8.0-beta4.jar \
    && wget https://github.com/NeuronRobotics/nrjavaserial/archive/refs/tags/5.2.1.zip -O nrjavaserial.zip \
    && unzip nrjavaserial.zip \
    && cd nrjavaserial-5.2.1/src/main/c \
    && mkdir build \
    && mkdir -p /opt/calimero/native/linux/ARM_64/ \
    && gcc -I./include -I./include/target -I/usr/lib/jvm/java-11-openjdk/include -I/usr/lib/jvm/java-11-openjdk/include/linux -O3 -Wall -c -fmessage-length=0 -fPIC -MMD -MP src/fixup.c -o build/fixup.o \
    && gcc -I./include -I./include/target -I/usr/lib/jvm/java-11-openjdk/include -I/usr/lib/jvm/java-11-openjdk/include/linux -O3 -Wall -c -fmessage-length=0 -fPIC -MMD -MP src/fuserImp.c -o build/fuserImp.o \
    && gcc -I./include -I./include/target -I/usr/lib/jvm/java-11-openjdk/include -I/usr/lib/jvm/java-11-openjdk/include/linux -O3 -Wall -c -fmessage-length=0 -fPIC -MMD -MP src/SerialImp.c -o build/SerialImp.o \
    && g++ -shared -fPIC -nostdlib -o"/opt/calimero/native/linux/ARM_64/libNRJavaSerialv8.so" build/fixup.o build/fuserImp.o build/SerialImp.o \
    && cd ../../../../ \
    && rm -R nrjavaserial-5.2.1 \
    && zip -u nrjavaserial-5.2.1.jar native/linux/ARM_64/libNRJavaSerialv8.so

ARG BUILD_FROM
FROM $BUILD_FROM

ENV LANG C.UTF-8
        
COPY --from=build /opt/jdk /opt/jdk
COPY --from=build /opt/calimero /opt/calimero

COPY run.sh /
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]