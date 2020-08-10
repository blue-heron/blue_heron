# BlueHeron

[![Hex version](https://img.shields.io/hexpm/v/blue_heron.svg "Hex version")](https://hex.pm/packages/blue_heron)
[![API docs](https://img.shields.io/hexpm/v/blue_heron.svg?label=hexdocs "API docs")](https://hexdocs.pm/blue_heron/BlueHeron.html)

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

See the examples for the time being.

## Transports

BlueHeron interacts with Bluetooth modules via transports. Transport
implementations are not part of this library since they are hardware-specific.
See
[BlueHeronTransportUART](https://github.com/smartrent/blue_heron/tree/main/blue_heron_transport_uart)
and
[BlueHeronTransportUSB](https://github.com/smartrent/blue_heron/tree/main/blue_heron_transport_usb)
for examples.

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

## Helpful docs

* [Bluetooth Core Specification v5.2](https://www.bluetooth.org/docman/handlers/downloaddoc.ashx?doc_id=478726)

## License

The source code is released under Apache License 2.0.

Check [NOTICE](NOTICE) and [LICENSE](LICENSE) files for more information.
