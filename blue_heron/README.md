# BlueHeron

BlueHeron is a new Elixir Bluetooth LE Library that communicates directly with
Bluetooth modules via HCI. It is VERY much under construction, and we expect the
user API to change completely.

On the plus side, BlueHeron has no dependencies on Linux's `bluez` stack so if
you either can't use `bluez`, don't want to, or have a simple BLE use case,
please join us in building this out! We gather on the [Elixir Lang
slack](https://elixir-slackin.herokuapp.com/) in the `#nerves-bluetooth`
channel.

## Goals

BlueHeron development was started since SmartRent had a need for a very simple
BLE interface on one of its Nerves devices.
The existing Elixir BLE library, [Harald](https://github.com/verypossible-labs/harald),
didn't have enough functionality and we made so many modifications that it no
longer felt like the library followed the spirit of what Harald wanted to be.

Our goals here are to make a one-stop BLE library with support for the
following:

* Scan for and connect to BLE peripheral devices (BlueHeron takes on the central
  role like a smartphone)
* GATT client support
* Work with USB and UART-based Bluetooth modules
* Support BLE beacons
* BLE peripheral and GATT server support

The current focus is on filling out the central role. The API is quite unstable
at the moment and is intended to look more like high level BLE APIs from other
languages. Currently, the raw API is helping us learn and iron out quirks
quickly.

If you are interested in adding support for the other roles, please let us know
either here or on Slack. While we're very interested in part of this library for
work, we're also having fun with BLE and figure that we might as well see if we
can hit some Nerves use cases too.

## Getting started

TBD

## Transports

### LibUSB Transport

BlueHeron partially implements Volume 3 Part B of the Bluetooth spec. This
should make it work with any off-the-shelf Bluetooth USB dongle.

You will need to know the USB VID/PID of your Bluetooth device since BlueHeron
doesn't know how to automatically detect it yet. On Linux, use `lsusb` to find
it.

```elixir
config = %BlueHeron.HCI.Transport.LibUSB{
  vid: 0x0bda, pid: 0xb82c
}
{:ok, ctx} = BlueHeron.transport(config)
```

### UART Transport

BlueHeron also supports UART-based Bluetooth modules. Currently, this ONLY
includes the Cypress Semiconductor
[BCM43438](https://www.cypress.com/part/cychpset-p62s143438-1). This part is on
the Raspberry Pi Zero W and the Raspberry Pi 3 B. It is NOT on the 3 B+.

```elixir
config = %BlueHeron.HCI.Transport.UART{
  device: "/dev/ttyACM0",
  uart_opts: [speed: 115200],
}
{:ok, ctx} = BlueHeron.transport(config)
```

## HCI Logging

This project includes a Logger backend to dump PKTLOG format. This is the same format
that Android, IOS, btstack, hcidump, and bluez use.

Add the backend to debug all data to/from the HCI transport:

```elixir
iex> Logger.add_backend(BlueHeron.HCIDump.Logger)
BlueHeron.HCIDump.Logger
```

This will produce a file `/tmp/hcidump.pklg` that can be loaded into Wireshark.

**NOTE** This project configures logger so it is always enabled by default.

The `BlueHeron.HCIDump.Logger` module implements a superset of Elixir's builtin logger and
all non-HCI data is forwarded directly to Elixir's Logger.

```elixir
iex> require BlueHeron.HCIDump.Logger, as: Logger
BlueHeron.HCIDump.Logger
iex> Logger.debug("sample data")

16:43:46.496 [debug] sample data

iex>
```

## License

This project is coverd by Apache-2.0 unless otherwise noted in the source file header.
Importantly some files are Copyright 2019 Very.
