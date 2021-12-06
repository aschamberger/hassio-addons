ARG BUILD_FROM
FROM $BUILD_FROM as build

ENV LANG C.UTF-8

# https://stackoverflow.com/a/57145029 --> explicitly add jmods
RUN apk update \
    && apk add --no-cache openjdk11-jdk openjdk11-jmods wget unzip zip build-base linux-headers lockdev cmake libusb-dev eudev-dev

RUN /usr/lib/jvm/java-11-openjdk/bin/jlink \
    --verbose \
    --add-modules java.base,java.xml \
    --compress 2 \
    --strip-debug \
    --no-header-files \
    --no-man-pages \
    --output /opt/jdk

# download jars and recompile serial and usb library for Alpine musl
RUN mkdir -p /opt/calimero/
RUN cd /opt/calimero/ \
    && wget https://repo1.maven.org/maven2/org/slf4j/slf4j-api/1.8.0-beta4/slf4j-api-1.8.0-beta4.jar \
    && wget https://repo1.maven.org/maven2/org/slf4j/slf4j-simple/1.8.0-beta4/slf4j-simple-1.8.0-beta4.jar
RUN cd /opt/calimero/ \
    && wget https://github.com/NeuronRobotics/nrjavaserial/releases/download/5.2.1/nrjavaserial-5.2.1.jar \
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
    && zip -u nrjavaserial-5.2.1.jar native/linux/ARM_64/libNRJavaSerialv8.so \
    && rm -R native
RUN cd /opt/calimero/ \
    && wget https://repo1.maven.org/maven2/org/usb4java/usb4java-javax/1.3.0/usb4java-javax-1.3.0.jar \
    && wget https://repo1.maven.org/maven2/org/usb4java/usb4java/1.3.0/usb4java-1.3.0.jar \
    && wget https://repo1.maven.org/maven2/javax/usb/usb-api/1.0.2/usb-api-1.0.2.jar \
    && wget https://repo1.maven.org/maven2/org/apache/commons/commons-lang3/3.8.1/commons-lang3-3.8.1.jar \
    && wget https://github.com/usb4java/libusb4java/archive/refs/tags/libusb4java-1.3.0.zip -O libusb4java.zip \
    && unzip libusb4java.zip \
    && cd libusb4java-libusb4java-1.3.0 \
    && mkdir build \
    && mkdir -p /opt/calimero/org/usb4java/linux-aarch64/ \
    && cd build \
    && export JAVA_HOME=/usr/lib/jvm/java-11-openjdk/ \
    && cmake .. \
    && make install/strip \
    && cp /usr/local/lib/libusb4java.so /opt/calimero/org/usb4java/linux-aarch64/ \
    && cd ../../ \
    && rm -R libusb4java-libusb4java-1.3.0 \
    && zip libusb4java-1.3.0-linux-aarch64.jar org/usb4java/linux-aarch64/libusb4java.so \
    && rm -R org
RUN cd /opt/calimero/ \
    && wget https://repo1.maven.org/maven2/com/github/calimero/calimero-rxtx/2.5/calimero-rxtx-2.5.jar \
    && wget https://repo1.maven.org/maven2/com/github/calimero/calimero-core/2.5/calimero-core-2.5.jar \
    && wget https://repo1.maven.org/maven2/com/github/calimero/calimero-device/2.5/calimero-device-2.5.jar \
    && wget https://repo1.maven.org/maven2/com/github/calimero/calimero-server/2.5/calimero-server-2.5.jar
    
ARG BUILD_FROM
FROM $BUILD_FROM

ENV LANG C.UTF-8

RUN apk update \
    && apk add --no-cache libusb eudev
        
COPY --from=build /opt/jdk /opt/jdk
COPY --from=build /opt/calimero /opt/calimero

COPY run.sh /
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]