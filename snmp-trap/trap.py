#!/usr/bin/python

# based on https://pysnmp.readthedocs.io/en/latest/examples/v3arch/asyncio/manager/ntfrcv/transport-tweaks.html
# install https://www.piwheels.org/ to run on a dietpi/pi os 

import os
import asyncio
import requests
import json
from pysnmp.entity import engine, config
from pysnmp.carrier.asyncio.dgram import udp
from pysnmp.entity.rfc3413 import ntfrcv

# get config from ENV vars
hassHost = "http://supervisor/core/api"
hassBearer = os.getenv('SUPERVISOR_TOKEN')       
port = os.getenv('PORT')
communityString = os.getenv('COMMUNITY_STRING')

# parameters for calling hass
url = hassHost + "/events/snmp_trap"
headers = {
    "Authorization": "Bearer " + hassBearer,
    "content-type": "application/json"
}

# Get the event loop for this thread
loop = asyncio.new_event_loop()
asyncio.set_event_loop(loop)

# Create SNMP engine with autogenernated engineID and pre-bound
# to socket transport dispatcher
snmpEngine = engine.SnmpEngine()

# Transport setup: UDP over IPv4
config.addTransport(
    snmpEngine,
    udp.domainName + (1,),
    udp.UdpTransport().openServerMode(('0.0.0.0', port))
)

# SNMPv1/2c setup

# SecurityName <-> CommunityName mapping
config.addV1System(snmpEngine, 'my-area', communityString)

# Callback function for receiving notifications
# noinspection PyUnusedLocal
def cbFun(snmpEngine, stateReference, contextEngineId,
          contextName, varBinds, cbCtx):

    transportDomain, transportAddress = snmpEngine.msgAndPduDsp.getTransportInfo(stateReference)

    #print('Notification from %s, SNMP Engine %s, '
    #      'Context %s' % (transportAddress, contextEngineId.prettyPrint(),
    #                      contextName.prettyPrint()))

    data = {'_source': transportAddress[0]}

    for name, val in varBinds:
        #print('%s = %s' % (name.prettyPrint(), val.prettyPrint()))
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

# Run asyncio main loop
loop.run_forever()