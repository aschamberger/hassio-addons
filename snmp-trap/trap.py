#!/usr/bin/python

# based on 
# * https://github.com/lextudio/pysnmp/blob/main/examples/v3arch/asyncio/manager/ntfrcv/multiple-network-transports-incl-ipv4-and-ipv6.py
# * https://github.com/lextudio/pysnmp/blob/main/examples/v3arch/asyncio/manager/ntfrcv/determine-peer-network-address.py#L53

import os
import requests
import json

from pysnmp.entity import engine, config
from pysnmp.carrier.asyncio.dgram import udp, udp6
from pysnmp.entity.rfc3413 import ntfrcv

# get config from ENV vars
hass_host = "http://supervisor/core/api"
hass_bearer = os.getenv('SUPERVISOR_TOKEN')       
port = os.getenv('PORT')
community_string = os.getenv('COMMUNITY_STRING')

# parameters for calling hass
url = hass_host + "/events/snmp_trap"
headers = {
    "Authorization": "Bearer " + hass_bearer,
    "content-type": "application/json"
}

# Create SNMP engine with autogenernated engineID and pre-bound
# to socket transport dispatcher
snmpEngine = engine.SnmpEngine()

# Transport setup

# UDP over IPv4
config.add_transport(
    snmpEngine, udp.DOMAIN_NAME, udp.UdpTransport().open_server_mode(("127.0.0.1", port))
)

# UDP over IPv6
config.add_transport(
    snmpEngine, udp6.DOMAIN_NAME, udp6.Udp6Transport().open_server_mode(("::1", port))
)

# SNMPv1/2c setup

# SecurityName <-> CommunityName mapping
config.add_v1_system(snmpEngine, "my-area", community_string)

# Callback function for receiving notifications
# noinspection PyUnusedLocal,PyUnusedLocal,PyUnusedLocal
def cbFun(snmpEngine, stateReference, contextEngineId, contextName, varBinds, cbCtx):
    # Get an execution context...
    execContext = snmpEngine.observer.getExecutionContext(
        "rfc3412.receiveMessage:request"
    )
    
    # ... and use inner SNMP engine data to figure out peer address
    print(
        'Notification from {}, ContextEngineId "{}", ContextName "{}"'.format(
            "@".join([str(x) for x in execContext["transportAddress"]]),
            contextEngineId.prettyPrint(),
            contextName.prettyPrint(),
        )
    )

    data = {'_source': execContext["transportAddress"]}

    for name, val in varBinds:
        #print(f"{name.prettyPrint()} = {val.prettyPrint()}")
        name = name.prettyPrint()
        if (name == '1.3.6.1.2.1.1.3.0'):
            name = '_uptime'
        elif (name == '1.3.6.1.6.3.1.1.4.1.0'):
            name = '_trap_oid'           
        data[name] = val.prettyPrint()

    data = json.dumps(data)
    print(data)
    print(requests.post(url, headers=headers, data=data))

# Register SNMP Application at the SNMP engine
ntfrcv.NotificationReceiver(snmpEngine, cbFun)

snmpEngine.transport_dispatcher.job_started(1)  # this job would never finish

# Run I/O dispatcher which would receive queries and send confirmations
try:
    snmpEngine.open_dispatcher()
except:
    snmpEngine.close_dispatcher()
    raise