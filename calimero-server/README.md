# Home Assistant Add-On: Calimero Server

A KNXnet/IP server (https://github.com/calimero-project/calimero-server) for running your own KNXnet/IP server in software. This add-on can be used for accessing the KNX bus via FT1.2/TPUART serial adapters or USB KNX devices. 

The minimum required runtime environment is Java SE 11 (java.base). A custom Java runtime is created via jlink. Note: Java 11 is only available for AArch64 on ARM. nrjavaserial+usb4java needs to be compiled for Alpine with musl, the release jar is updated with this binary.

## Add-On Configuration

The add-on requires the following configuration:
```
knx_address: 1.1.0
client_address_start: 1.1.101
client_address_count: 5
interface_type: ft12-cemi
device: /dev/ttyAMA0
routing: true
knx_source_override: true
```

`knx_address` of the service container, will be visible in e.g. ETS-tool. If routing is activated, requires a coupler/backbone address (x.y.0 or x.0.0).

`client_address_start` Start address of KNX individual addresses, which are assigned to KNXnet/IP tunneling connections.

`client_address_count` number of KNX individual addresses/possible tunneling connections.

`interface_type` can be one of:
* `ft12-cemi` for e.g. the [KNX BAOS Module 838 kBerry](https://www.weinzierl.de/index.php/en/all-knx/knx-module-en/knx-baos-module-838-en) 
* `tpuart` for e.g. [TPUART USB Modul](http://shop.busware.de/product_info.php/products_id/59)
* `usb`

`serial_device` uart device name

`usb_device` specify the vendorId:productId or vendor name, e.g. siemens; if USB device identifier is left empty, the first found KNX USB device is used

`routing` if true activate KNX IP routing, if false routing is disabled

`knx_source_override` if true activate static default source address assignment (required for devices that don't like the source address to be changed or set, e.g. for the Weinzierl kBerry)

`loglevel` is optional and can be one of the slf4j log levels. It logs everything to standard output. 

`expose_date` Cyclically transmit date (11.001) to this group address using the default time zone

`expose_time` Cyclically transmit time (10.001) to this group address using the default time zone

`expose_datetime` Cyclically transmit date+time (19.001) to this group address using the default time zone

`timeserver_expiration` Expiration timeout specifies tx cycle in seconds, e.g., 1 min = 60, 1 hour = 3600, 12 hours = 43200 

## Configure serial communication 

### Raspberry Pi 3 / 4
 
In order to use the KNX BAOS Module 838 kBerry the serial port on the Raspberry Pi needs to be enabled in `config.txt` (which is by default occupied by the bluetooth module).

Raspberry Pi 3
```
dtoverlay=pi3-disable-bt
```

[Raspberry Pi 4](https://github.com/knxd/knxd/issues/469#issuecomment-723936998)

```
dtoverlay=disable-bt
dtoverlay=uart0
[all]
uart0=on
```

### ODROID C4

The correct device for the serial port is '/dev/ttyAML1' (the device is pin compatible to the Raspberry Pi)

ODROID support required to add a property to the run command for the serial port 'detection' to work.
```
java -Dgnu.io.rxtx.SerialPorts=/dev/ttyAMA0 ...
```

## Links

* Enable SSH access to the host: https://developers.home-assistant.io/docs/operating-system/debugging/
* Add RXTX unkown UART device names via property: https://angryelectron.com/rxtx-on-raspbian/                                                                                           
* usb4java also needs to be compiled for musl on Alpine: http://usb4java.org/nativelibs.html
