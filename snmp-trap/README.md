# Home Assistant Add-On: SNMP Trap Reciever

A SNMP trap reciever that will publish them as events to Home Assisstant via HTTP API based on the [pysnmp](https://github.com/pysnmp/pysnmp) python library.

In Home Assisstant the traps can be used in an automation. Each event has a JSON payload like this:
```
{"_source": "127.0.0.1", "_uptime": "123", "_trap_oid": "1.3.6.1.6.3.1.1.5.3", "1.3.6.1.2.1.2.2.1.1.5": "5"}
```

OIDs for my switch:
* "1.3.6.1.6.3.1.1.5.3" = link down
* "1.3.6.1.6.3.1.1.5.4" = link up
* "1.3.6.1.2.1.2.2.1.1.x" = port x

Blueprint for deactivating the LAN port on link down: 
https://gist.github.com/aschamberger/0ab0bd03561288cbb2ab079cad8f8a86

## Add-On Configuration

The add-on requires the following configuration:
```
port: 162
community_string: public
```

`port` The port the reciever listens on (default: 162).

`community_string` SNMP community string name (default: public).

## Testing

Sending traps via `snmptrap` from a Linux system:
```
sudo apt-get install snmp
snmptrap -v2c -c public homeassistant:162 123 1.3.6.1.6.3.1.1.5.3 1.3.6.1.2.1.2.2.1.1.5 i 5
```
The command above sends a link down for port 5.

## Links

* supervisor token for HTTP API access: https://developers.home-assistant.io/docs/add-ons/communication/
* based on https://pysnmp.readthedocs.io/en/latest/examples/v3arch/asyncio/manager/ntfrcv/transport-tweaks.html
