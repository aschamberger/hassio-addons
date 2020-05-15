#!/bin/bash
set -e

CONFIG_PATH=/data/options.json

KNXD_ADDRESS=$(jq --raw-output ".knxd_address" $CONFIG_PATH)
CLIENT_ADDRESS_START=$(jq --raw-output ".client_address_start" $CONFIG_PATH)
CLIENT_ADDRESS_LENGTH=$(jq --raw-output ".client_address_length" $CONFIG_PATH)
DRIVER=$(jq --raw-output ".driver" $CONFIG_PATH)
DEVICE=$(jq --raw-output ".device" $CONFIG_PATH)
TCP=$(jq --raw-output ".tcp" $CONFIG_PATH)
DEBUG=$(jq --raw-output ".debug" $CONFIG_PATH)
TRACE_MASK=$(jq --raw-output ".trace_mask" $CONFIG_PATH)

# doc for ini options: https://github.com/knxd/knxd/blob/master/doc/inifile.rst
KNXD_INI="[A.single]
address = 15.15.255
filter = single
[B.interface]
driver = $DRIVER
device = $DEVICE
filters = A.single"
if [ "$TCP" = "true" ]; then
KNXD_INI="$KNXD_INI
[C.tcp]
server = knxd_tcp"
fi
if [ "$DEBUG" = "true" ]; then
KNXD_INI="$KNXD_INI
[debug-main]
error-level = 0x9
trace-mask = $TRACE_MASK"
fi
KNXD_INI="$KNXD_INI
[debug-server]
name = mcast:knxd
[main]
addr = $KNXD_ADDRESS
client-addrs = $CLIENT_ADDRESS_START:$CLIENT_ADDRESS_LENGTH
connections = server,B.interface"
if [ "$TCP" = "true" ]; then
KNXD_INI="$KNXD_INI,C.tcp"
fi
KNXD_INI="$KNXD_INI
logfile = /dev/stdout"
if [ "$DEBUG" = "true" ]; then
KNXD_INI="$KNXD_INI
debug = debug-main"
fi
KNXD_INI="$KNXD_INI
[server]
debug = debug-server
discover = true
server = ets_router
router = router
tunnel = tunnel"

echo "$KNXD_INI" >> /etc/knxd.ini
 
exec knxd /etc/knxd.ini
