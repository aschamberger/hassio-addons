#!/usr/bin/python3
import os
import sys
import requests

if len(sys.argv) == 2:
    url = "http://{0}/addons/{1}/info".format(os.environ.get('HASSIO'), sys.argv[1])
    headers = {'X-Hassio-Key': os.environ.get('HASSIO_TOKEN', "")}
    response = requests.get(url, headers=headers)
	
    if response.status_code in (200, 400):
        info = response.json()
        print(info['data']['state'])
    else:
        print('unknown')