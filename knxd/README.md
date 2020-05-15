# knxd Hass.io Add-On

knxd is an advanced router/gateway which runs on any Linux computer; it can talk to all known KNX interfaces. 
This knxd hass.io add-on can be used for accessing the KNX bus via FT1.2, TPUART or USB bus adapters.

Important note: knxd/the container only starts if the KNX bus is already powered!

## Add-On Configuration

The add-on requires the following configuration:
```
{
	"knxd_address": "1.1.1",
	"client_address_start": "1.1.2",
	"client_address_length": 5,
	"driver": "ft12cemi",
	"device": "/dev/ttyAMA0",
	"tcp": false,
	"debug": false,
	"trace_mask": "0xffe"
}
```
	
Driver can be one of:
* `ft12cemi` for e.g. the [KNX BAOS Module 838 kBerry](https://www.weinzierl.de/index.php/en/all-knx/knx-module-en/knx-baos-module-838-en) 
* `tpuart` for e.g. [TPUART USB Modul](http://shop.busware.de/product_info.php/products_id/59)
* `usb` for a standard KNX USB interface

## KNX BAOS Module 838 kBerry on Raspberry Pi
 
In order to use the KNX BAOS Module 838 kBerry the serial port on the Raspberry Pi needs to be enabled.

Required configuration changes:
* add `enable_uart=1` into `config.txt`
* add `dtoverlay=pi3-disable-bt` into `config.txt`

Important: only group communication works if the single filter is not set for the driver in knxd.ini
https://github.com/knxd/knxd/blob/master/doc/inifile.rst#single
https://github.com/knxd/knxd/issues/227

## Monitor Container State

https://github.com/aschamberger/hassio-addons/blob/master/sensor.command_line/docker_state.py

```
  - platform: command_line
    name: docker_state_knxd
    command: "python3 /config/sensor.command_line/docker_state.py local_knxd"
    scan_interval: 5
```

## Restart Container Automation

```
- id: knxd_watchdog
  alias: KNXD Watchdog
  trigger:
  - platform: time_pattern
    minutes: '/5'
  condition:
  - condition: template
    value_template: '{{ states.sensor.docker_state_knxd.state != "started" }}'
  action:
  - service: hassio.addon_start
    data:
      addon: local_knxd
```

## Links

* Doc for knxd ini options: https://github.com/knxd/knxd/blob/master/doc/inifile.rst
* Dockerfile example from here: https://knx-user-forum.de/forum/projektforen/knxd/1081901-knxd-auf-alpine-linux?p=1084515#post1084515
* Enable SSH access to the host: https://developers.home-assistant.io/docs/en/hassio_debugging.html
* knxd basics in German: https://knx-user-forum.de/forum/projektforen/knxd/1049547-grundlagen-zum-knxd-mit-installationsanleitung-vor-dem-schreiben-lesen