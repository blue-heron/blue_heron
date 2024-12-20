# BlueHeron

[![Hex version](https://img.shields.io/hexpm/v/blue_heron.svg "Hex version")](https://hex.pm/packages/blue_heron)
[![API docs](https://img.shields.io/hexpm/v/blue_heron.svg?label=hexdocs "API docs")](https://hexdocs.pm/blue_heron/BlueHeron.html)
[![mix test](https://github.com/blue-heron/blue_heron/actions/workflows/elixir.yaml/badge.svg)](https://github.com/blue-heron/blue_heron/actions/workflows/elixir.yaml)

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
at the moment, but we're aiming for a high level API so that most users don't
need to become Bluetooth experts. Currently, the raw API is helping us learn and
iron out quirks quickly. See [Rationale](#Rationale) for more about why we're
doing building this library.

If you are interested in adding support for the other roles, please let us know
either here or on Slack. While we're very interested in part of this library for
work, we're also having fun with BLE and figure that we might as well see if we
can hit some Nerves use cases too.

## Hardware compatibility

We have only tested BlueHeron with a limited number of Bluetooth adapters.
Here's what's known:

| Bluetooth module or chipset            | Connection | Works? | Firmware               | Notes
| -------------------------------------- | ---------- | ------ | ---------------------- | -----
| Realtek WiFi/BT combo (EDUP EP-AC1681) | USB        | Yes    | rtl_bt/rtl8822b_fw.bin | BlueHeron doesn't need to load the firmware for this one to work.
| Cypress CYW43438 (RPi0W and RPi 3B)    | UART       | Yes    | ?                      | BlueHeron doesn't need to load the firmware for this one to work.
| Cypress CYW43455 (RPi 3A+ and 3B+)     | UART       | No     | ?                      | Retry when #21 is fixed

## Getting started

See the [examples](https://github.com/blue-heron/blue_heron/tree/main/examples) for the time being.

## Transports

BlueHeron interacts with Bluetooth modules via transports. Transport
implementations are not part of this library since they are hardware-specific.
See
[BlueHeronTransportUART](https://github.com/blue-heron/blue_heron_transport_uart)
and
[BlueHeronTransportUSB](https://github.com/blue-heron/blue_heron_transport_usb)
for examples.

## Helpful docs

* [Bluetooth Core Specification v5.2](https://www.bluetooth.org/docman/handlers/downloaddoc.ashx?doc_id=478726)

## Rationale

This library will likely feel like a whole lot of reinvention of the wheel for
anyone familiar with Bluetooth stacks in embedded Linux. It took around three
years for one of us to get to this point of starting a new library, so it's
worth sketching out why.

The obvious approach is to use Linux's `bluez` stack. It certainly worked, but
was complicated for most people to set up when using Nerves. Consequently, it
was hard to debug and a thankless task for anyone attempting to support Nerves
users. It was far easier to use `bluez` on a batteries-included OS distribution
like Raspbian.

The next approach was to use a smart Bluetooth module like an Adafruit Bluefruit
module or a Roving Networks (now Microchip) Bluetooth module. These have an `AT`
style command set for doing common Bluetooth things (for example,
see
[here](https://learn.adafruit.com/introducing-adafruit-ble-bluetooth-low-energy-friend/command-mode)),
and are fairly easy to use once you got used to the interface. Not everyone
wanted to use these for various reasons (cost being a big one).

A good alternative was to use a C Bluetooth stack that talks directly to a
Bluetooth module via UART or USB using the HCI protocol. These are
typically marketed towards microcontroller users, but can be made to work on
minimal Linux configurations too. Some of the options have good documentation
and are commercially supported.

Integrating the C stack still required work, and since our needs were so simple,
we simultaneously looked at an Elixir implementation. Elixir has a way of making
dull work surprisingly enjoyable, and it's especially suited to communication
protocols. When the proof-of-concept started working in not much time, we
decided that we'd much rather spend our time in Elixir than anywhere else.

Will this library have more features than `bluez`? Not even close. Will it do
what we need? Yes. Will it have fewer bugs, be more robust, etc.? Don't know,
but its small size and few parts is easier to get our heads around and debug
when issues come up. Is it fun to work on? Yes, so we got permission to
open-source it, so we could use it for hobby projects too.

## Support

We provide best-effort support via the [Elixir Forum](https://elixirforum.com/)
and the [#nerves-bluetooth channel on the Elixir
Slack](https://elixir-slackin.herokuapp.com/). If you need more immediate
support or feature additions, commercial support is provided by [Binary
Noggin](https://binarynoggin.com).

## License

The source code is released under Apache License 2.0.

Check [NOTICE](NOTICE) and [LICENSE](LICENSE) files for more information.
