#!/bin/sh
set -e

CONFIG_PATH=/data/options.json

KNX_ADDRESS=$(jq --raw-output ".knx_address" $CONFIG_PATH)
CLIENT_ADDRESS_START=$(jq --raw-output ".client_address_start" $CONFIG_PATH)
CLIENT_ADDRESS_COUNT=$(jq --raw-output ".client_address_count" $CONFIG_PATH)
INTERFACE_TYPE=$(jq --raw-output ".interface_type" $CONFIG_PATH)
DEVICE=$(jq --raw-output ".device" $CONFIG_PATH)
ROUTING=$(jq --raw-output ".routing" $CONFIG_PATH)
KNX_SOURCE_OVERRIDE=$(jq --raw-output ".knx_source_override" $CONFIG_PATH)
LOGLEVEL=$(jq --raw-output ".loglevel" $CONFIG_PATH)

ADD_KNX_SOURCE_OVERRIDE=""
if [ -n "$KNX_SOURCE_OVERRIDE" ]; then
    ADD_KNX_SOURCE_OVERRIDE=" knxAddress=\"0\""
fi

ADD_LOGGING=""
if [ -n "$LOGLEVEL" ]; then
    ADD_LOGGING=" -Dorg.slf4j.simpleLogger.defaultLogLevel=$LOGLEVEL"
fi

CONFIG_XML="<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<!-- Calimero server settings (required for startup) -->
<knxServer name=\"knx-server\" friendlyName=\"Hass OS KNXnet/IP Server\">
	<!-- KNXnet/IP search & discovery -->
	<discovery listenNetIf=\"all\" outgoingNetIf=\"all\" activate=\"true\" />
	<!-- Provides the KNXnet/IP-side configuration for access to one KNX subnet -->
	<serviceContainer activate=\"true\" routing=\"$ROUTING\" networkMonitoring=\"true\" 
		udpPort=\"3671\" listenNetIf=\"eth0\">
		<knxAddress type=\"individual\">$KNX_ADDRESS</knxAddress>"
if [ "$INTERFACE_TYPE" = "ft12-cemi" ]; then
CONFIG_XML="$CONFIG_XML
		<knxSubnet type=\"ft12-cemi\" medium=\"tp1\"$ADD_KNX_SOURCE_OVERRIDE>$DEVICE</knxSubnet>"
fi
if [ "$INTERFACE_TYPE" = "tpuart" ]; then
CONFIG_XML="$CONFIG_XML
		<knxSubnet type=\"tpuart\" medium=\"tp1\">$DEVICE</knxSubnet>"
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
		</additionalAddresses>
	</serviceContainer>
	<!-- Add next service container (optional) -->
</knxServer>"

echo "$CONFIG_XML" > /etc/server-config.xml

cat /etc/server-config.xml

exec /opt/jdk/bin/java -cp "/opt/calimero/*"$ADD_LOGGING tuwien.auto.calimero.server.Launcher --no-stdin /etc/server-config.xml
