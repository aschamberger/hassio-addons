#!/usr/bin/with-contenv bashio

DISCOVERY_NAME=$(bashio::config 'discovery_name')
KNX_ADDRESS=$(bashio::config 'knx_address')
CLIENT_ADDRESS_START=$(bashio::config 'client_address_start')
CLIENT_ADDRESS_COUNT=$(bashio::config 'client_address_count')
INTERFACE_TYPE=$(bashio::config 'interface_type')
SERIAL_DEVICE=$(bashio::config 'serial_device')
USB_DEVICE=$(bashio::config 'usb_device')
ROUTING=$(bashio::config 'routing')

# try to handle missing serial device config
if bashio::config.is_empty 'serial_device'; then
    echo "serial device config missing!\n"
    # Raspberry Pi 3 / 4
    if [ -e "/dev/ttyAMA0" ]; then
        SERIAL_DEVICE="/dev/ttyAMA0"
    # ODROID C4 / Asus Tinker Board S
    elif [ -e "/dev/ttyS1" ]; then
        SERIAL_DEVICE=="/dev/ttyS1"
    else
        echo "fix config an restart!\n"
        exit
    fi
    echo "trying with: $SERIAL_DEVICE\n"
fi

ADD_KNX_SOURCE_OVERRIDE=""
if bashio::config.true 'knx_source_override'; then
    ADD_KNX_SOURCE_OVERRIDE=" knxAddress=\"0\""
fi

ADD_TIMESERVER_EXPIRATION=""
if bashio::config.exists 'timeserver_expiration'; then
    ADD_TIMESERVER_EXPIRATION="
				<expiration timeout=\"$(bashio::config 'timeserver_expiration')\" />"
fi

CONFIG_XML="<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<!-- Calimero server settings (required for startup) -->
<knxServer name=\"knx-server\" friendlyName=\"$DISCOVERY_NAME\">
	<!-- KNXnet/IP search & discovery -->
	<discovery listenNetIf=\"all\" outgoingNetIf=\"all\" activate=\"true\" />
	<!-- Provides the KNXnet/IP-side configuration for access to one KNX subnet -->
	<serviceContainer activate=\"true\" routing=\"$ROUTING\" networkMonitoring=\"true\"
		udpPort=\"3671\" listenNetIf=\"end0\">
		<knxAddress type=\"individual\">$KNX_ADDRESS</knxAddress>"
if [ "$INTERFACE_TYPE" = "ft12-cemi" ]; then
CONFIG_XML="$CONFIG_XML
		<knxSubnet type=\"ft12\" medium=\"tp1\" format=\"cemi\"$ADD_KNX_SOURCE_OVERRIDE>$SERIAL_DEVICE</knxSubnet>"
fi
if [ "$INTERFACE_TYPE" = "tpuart" ]; then
CONFIG_XML="$CONFIG_XML
		<knxSubnet type=\"tpuart\" medium=\"tp1\">$SERIAL_DEVICE</knxSubnet>"
fi
if [ "$INTERFACE_TYPE" = "usb" ]; then
CONFIG_XML="$CONFIG_XML
		<knxSubnet type=\"usb\" medium=\"tp1\">$USB_DEVICE</knxSubnet>"
fi
CONFIG_XML="$CONFIG_XML
		<!-- KNX group address filter applied by the server for this service container (optional) -->
		<groupAddressFilter>
		</groupAddressFilter>
		<!-- Additional KNX individual addresses assigned to client KNXnet/IP connections (optional) -->
		<additionalAddresses>"
export KNX_ADDRESS_PREFIX=$(echo $CLIENT_ADDRESS_START|cut -d'.' -f 1-2)
export START_OCTET=$(echo $CLIENT_ADDRESS_START|cut -d'.' -f 3)
# Add new KNX Client Address elements
i=1
while [ "$i" -le $CLIENT_ADDRESS_COUNT ]; do
CURRENT_OCTET=$(expr $START_OCTET + $i - 1)
CONFIG_XML="$CONFIG_XML
			<knxAddress type=\"individual\">$KNX_ADDRESS_PREFIX.$CURRENT_OCTET</knxAddress>"
i=$(( i + 1 ))
done
CONFIG_XML="$CONFIG_XML
		</additionalAddresses>"
if bashio::config.exists 'expose_date' || bashio::config.exists 'expose_time' || bashio::config.exists 'expose_datetime'; then
    CONFIG_XML="$CONFIG_XML
		<timeServer>"
    if bashio::config.exists 'expose_date'; then
    CONFIG_XML="$CONFIG_XML
			<datapoint stateBased=\"true\" name=\"current date\" dptID=\"11.001\" priority=\"low\">
				<knxAddress type=\"group\">$(bashio::config 'expose_date')</knxAddress>$ADD_TIMESERVER_EXPIRATION
			</datapoint>"
    fi
    if bashio::config.exists 'expose_time'; then
    CONFIG_XML="$CONFIG_XML
			<datapoint stateBased=\"true\" name=\"current time\" dptID=\"10.001\" priority=\"low\">
				<knxAddress type=\"group\">$(bashio::config 'expose_time')</knxAddress>$ADD_TIMESERVER_EXPIRATION
			</datapoint>"
    fi
    if bashio::config.exists 'expose_datetime'; then
    CONFIG_XML="$CONFIG_XML
			<datapoint stateBased=\"true\" name=\"current datetime\" dptID=\"19.001\" priority=\"low\">
				<knxAddress type=\"group\">$(bashio::config 'expose_datetime')</knxAddress>$ADD_TIMESERVER_EXPIRATION
			</datapoint>"
    fi
    CONFIG_XML="$CONFIG_XML
		</timeServer>"
fi
CONFIG_XML="$CONFIG_XML
	</serviceContainer>
	<!-- Add next service container (optional) -->
</knxServer>"

echo "$CONFIG_XML" > /etc/server-config.xml

cat /etc/server-config.xml

ADD_LOGGING=""
if ! bashio::config.is_empty 'loglevel' && ! bashio::config.equals 'loglevel' 'off'; then
    ADD_LOGGING=" -Dorg.slf4j.simpleLogger.defaultLogLevel=$(bashio::config 'loglevel')"
fi

exec /opt/jdk/bin/java -XX:+UseShenandoahGC -cp "/opt/calimero/*"$ADD_LOGGING -Dgnu.io.rxtx.SerialPorts=$SERIAL_DEVICE io.calimero.server.Launcher --no-stdin /etc/server-config.xml
