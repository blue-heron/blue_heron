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

## Upgrading from 0.4.x

The [0.5.0 release](https://github.com/blue-heron/blue_heron/releases/tag/v0.5.0) brought with it a bunch of updates. The most notable one
is the addition of a supervision tree. Upgrading to this release requires a few steps.

1) remove `:blue_heron_transport_uart` from your `mix.exs`. Transport code was consolidated in the 0.5 release.
2) Update your `config.exs` with the same parameters as the Transport options. For example, on a RPI0, you would
   change 
   ```elixir
    config = %BlueHeronTransportUART{
      device: "/dev/ttyS0",
      uart_opts: [
        speed: 115_200,
      ]
    }
    {:ok, ctx} = BlueHeron.transport(config)
   ```
   into a config.exs entry: 
   ```elixir
   config :blue_heron,
    transport: [
      device: "/dev/ttyS0",
      speed: 115_200,
      flow_control: :hardware
    ]
   ```
3) Remove `BlueHeron.Peripheral.start_link/2` calls. The Peripheral
   server is now started as part of BlueHeron's supervision tree.
4) Remove any modules that have `@behaviour BlueHeron.GATT.Server`. Services
   are now registered with `BlueHeron.Peripheral.register_service/1`. The
   data structure remains the same.
5) Update any calls to `BlueHeron.Peripheral.set_advertising_data/1` and similar
   to use the new `BlueHeron.Broadcaster.set_advertising_data/1`. The data to
   those calls is the same.

## Getting started

Below are examples of the roles supported by BlueHeron currently.

### Broadcaster Role

The simplest role to implement is a BLE Broadcaster. This is a device that doesn't *do* anything by itself,
but broadcasts it's information publically. A good example of this role is Apple's [iBeacon](https://en.wikipedia.org/wiki/IBeacon).

```elixir
iex(1)> flags_ad = BlueHeron.AdvertisingData.flags([le_general_discoverable_mode: true, br_edr_not_supported: true])
<<2, 1, 6>>
iex(2)> uuid = <<0xF018E00E0ECE45B09617B744833D89BA::128>>
<<240, 24, 224, 14, 14, 206, 69, 176, 150, 23, 183, 68, 131, 61, 137, 186>>
iex(3)> major = 1
1
iex(4)> minor = 0
0
iex(5)> tx_power = -60
iex(6)> ibeacon = BlueHeron.AdvertisingData.IBeacon.new(uuid, major, minor, tx_power)
<<76, 0, 2, 21, 240, 24, 224, 14, 14, 206, 69, 176, 150, 23, 183, 68, 131, 61,
  137, 186, 0, 1, 0, 0, 196>>
iex(7)> ibeacon_ad = BlueHeron.AdvertisingData.manufacturer_specific_data(ibeacon)
<<26, 255, 76, 0, 2, 21, 240, 24, 224, 14, 14, 206, 69, 176, 150, 23, 183, 68,
  131, 61, 137, 186, 0, 1, 0, 0, 196>>
BlueHeron.Broadcaster.set_advertising_data(flags_ad <> BlueHeron.AdvertisingData.manufacturer_specific_data(ibeacon))
:ok
iex(8)> BlueHeron.Broadcaster.start_advertising()
:ok
```

### Peripheral

A Peripheral is a Broadcaster that allows a connection via the GATT and GAP Service Discovery protocols. This allows a device
to *do* something. To setup a Peripheral, first we need to enable the Broadcaster role so our device can be found.

```elixir
# stop advertising while we change the payload.
iex(1)> BlueHeron.Broadcaster.stop_advertising()
:ok
# flags will be the same as before.
iex(2)> flags_ad = BlueHeron.AdvertisingData.flags([le_general_discoverable_mode: true, br_edr_not_supported: true])
<<2, 1, 6>>
iex(3)> short_name = "nerves"
"nerves"
iex(4)> short_name_ad = BlueHeron.AdvertisingData.short_name(short_name)
"\a\bnerves"
iex(5)> incomplete_list_of_service_ids = BlueHeron.AdvertisingData.incomplete_list_of_service_uuids([0xF018E00E0ECE45B09617B744833D89BA])
<<17, 6, 186, 137, 61, 131, 68, 183, 23, 150, 176, 69, 206, 14, 14, 224, 24,
  240>>
iex(6)> BlueHeron.Broadcaster.set_advertising_data(flags_ad <> short_name_ad <> incomplete_list_of_service_ids)
:ok
iex(7)> BlueHeron.Broadcaster.start_advertising()
:ok
```

This will set the scanned name to be `nerves`. 

Since the AdvertisingData payload is limited to only 31 bytes, if we want to set additional information, we
can put it in the `ScanResponseData`. This is an additional payload that is scanned and usually cached on
Central devices. For example setting the long name can be done with:

```elixir
# stop advertising while we change the payload.
iex(1)> BlueHeron.Broadcaster.stop_advertising()
:ok
# flags will be the same as before.
iex(2)> flags_ad = BlueHeron.AdvertisingData.flags([le_general_discoverable_mode: true, br_edr_not_supported: true])
<<2, 1, 6>>
iex(3)> long_name = "nerves-" <> Nerves.Runtime.serial_number()
"nerves-00000000b5f1bea0"
iex(4)> long_name_ad = BlueHeron.AdvertisingData.complete_name(long_name)
<<24, 9, 110, 101, 114, 118, 101, 115, 45, 48, 48, 48, 48, 48, 48, 48, 48, 98,
  53, 102, 49, 98, 101, 97, 48>>
iex(5)> BlueHeron.Broadcaster.set_scan_response_data(long_name_ad)
:ok
iex(6)> BlueHeron.Broadcaster.start_advertising()
:ok
```

Now that the device is advertising, we need to implement the service we listed: `0xF018E00E0ECE45B09617B744833D89BA`, as well as
implement the `GAP` and `GATT` profiles. 

```elixir
iex(7)> gap_service = BlueHeron.GATT.Service.new(%{
...(7)>   id: :gap,
...(7)>   type: 0x1800,
...(7)>   characteristics: [
...(7)>     BlueHeron.GATT.Characteristic.new(%{
...(7)>       id: {:gap, :device_name},
...(7)>       type: 0x2A00,
...(7)>       properties: 0b0000010
...(7)>     }),
...(7)>     BlueHeron.GATT.Characteristic.new(%{
...(7)>       id: {:gap, :appearance},
...(7)>       type: 0x2A01,
...(7)>       properties: 0b0000010
...(7)>     })
...(7)>   ],
...(7)>   read: fn 
...(7)>     {:gap, :device_name} -> 
...(7)>       "nerves-" <> Nerves.Runtime.serial_number()
...(7)>     {:gap, :appearance} ->
...(7)>       <<0x008D::little-16>>
...(7)>   end
...(7)> })
%BlueHeron.GATT.Service{
  id: :gap,
  type: 6144,
  characteristics: [
    %BlueHeron.GATT.Characteristic{
      id: {:gap, :device_name},
      type: 10752,
      properties: 2,
      permissions: nil,
      descriptor: nil,
      handle: nil,
      value_handle: nil,
      descriptor_handle: nil
    },
    %BlueHeron.GATT.Characteristic{
      id: {:gap, :appearance},
      type: 10753,
      properties: 2,
      permissions: nil,
      descriptor: nil,
      handle: nil,
      value_handle: nil,
      descriptor_handle: nil
    }
  ],
  handle: nil,
  end_group_handle: nil,
  read: #Function<42.39164016/1 in :erl_eval.expr/6>,
  write: #Function<3.104805658/2 in BlueHeron.GATT.Service.default_write_callback>,
  subscribe: #Function<5.104805658/1 in BlueHeron.GATT.Service.default_subscribe_callback>,
  unsubscribe: #Function<7.104805658/1 in BlueHeron.GATT.Service.default_unsubscribe_callback>
}
iex(8)> gatt_service = BlueHeron.GATT.Service.new(%{
...(8)>   id: :gatt,
...(8)>   type: 0x1801,
...(8)>   characteristics: [
...(8)>     BlueHeron.GATT.Characteristic.new(%{
...(8)>       id: {:gatt, :service_changed}, 
...(8)>       type: 0x2A05,
...(8)>       properties: 0b100000
...(8)>     })
...(8)>   ]
...(8)> })
%BlueHeron.GATT.Service{
  id: :gatt,
  type: 6145,
  characteristics: [
    %BlueHeron.GATT.Characteristic{
      id: {:gatt, :service_changed},
      type: 10757,
      properties: 32,
      permissions: nil,
      descriptor: nil,
      handle: nil,
      value_handle: nil,
      descriptor_handle: nil
    }
  ],
  handle: nil,
  end_group_handle: nil,
  read: #Function<1.104805658/1 in BlueHeron.GATT.Service.default_read_callback>,
  write: #Function<3.104805658/2 in BlueHeron.GATT.Service.default_write_callback>,
  subscribe: #Function<5.104805658/1 in BlueHeron.GATT.Service.default_subscribe_callback>,
  unsubscribe: #Function<7.104805658/1 in BlueHeron.GATT.Service.default_unsubscribe_callback>
}
iex(9)> custom_service = BlueHeron.GATT.Service.new(%{
...(9)>   id: :test,
...(9)>   type: 0xF018E00E0ECE45B09617B744833D89BA,
...(9)>   characteristics: [
...(9)>     BlueHeron.GATT.Characteristic.new(%{
...(9)>       id: {:test, :char_1},
...(9)>       type: 0x2e0f8e717a7d4690998377626bc6b657,
...(9)>       properties: 0b0000010,
...(9)>       permissions: [:read_auth]
...(9)>     }),
...(9)>     BlueHeron.GATT.Characteristic.new(%{
...(9)>       id: {:test, :char_2},
...(9)>       type: 0x3e0f8e717a7d4690998377626bc6b657,
...(9)>       properties: 0b0001000,
...(9)>       permissions: [:write_auth]
...(9)>     }),
...(9)>   ],
...(9)>   read: fn 
...(9)>     {:test, :char_1} -> 
...(9)>       "hello, world"
...(9)>   end,
...(9)>   write: fn
...(9)>     {:test, :char_2}, value ->
...(9)>       require Logger
...(9)>       Logger.info("write #{inspect(value)}")
...(9)>   end
...(9)> })
%BlueHeron.GATT.Service{
  id: :test,
  type: 319143878486512296490943150958665632186,
  characteristics: [
    %BlueHeron.GATT.Characteristic{
      id: {:test, :char_1},
      type: 61225261351838855375776121692935861847,
      properties: 2,
      permissions: [:read_auth],
      descriptor: nil,
      handle: nil,
      value_handle: nil,
      descriptor_handle: nil
    },
    %BlueHeron.GATT.Characteristic{
      id: {:test, :char_2},
      type: 82492909284397509342237034657421375063,
      properties: 8,
      permissions: [:write_auth],
      descriptor: nil,
      handle: nil,
      value_handle: nil,
      descriptor_handle: nil
    }
  ],
  handle: nil,
  end_group_handle: nil,
  read: #Function<42.39164016/1 in :erl_eval.expr/6>,
  write: #Function<41.39164016/2 in :erl_eval.expr/6>,
  subscribe: #Function<5.104805658/1 in BlueHeron.GATT.Service.default_subscribe_callback>,
  unsubscribe: #Function<7.104805658/1 in BlueHeron.GATT.Service.default_unsubscribe_callback>
}
iex(10)> BlueHeron.Peripheral.add_service(gap_service)
:ok
iex(11)> BlueHeron.Peripheral.add_service(gatt_service)
:ok
iex(12)> BlueHeron.Peripheral.add_service(encrypted_service)
:ok
```

Once completed, you should be able to connect to the `nerves` BLE device, it will do a encrypted `Bonding` procedure, and finally allow
you to `read` and `write` the implemented services.

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

## Debugging

It can be a chore to debug Bluetooth. Errors can happen at a few different
layers from the baseband all the way up to the high level software. Below are
some useful pieces of hardware and software that can be used to debug issues
in BlueHeron or generally snoop on BLE devices.

### Nordic Semiconductor BLE Sniffer

This is a custom firmware for devboards that can be used to sniff BLE packets.
More info can be found on [Nordic's website](https://docs.nordicsemi.com/bundle/nrfutil_ble_sniffer_pdf/resource/nRF_Sniffer_BLE_UG_v4.0.0.pdf)

* [Adafruit BLE Sniffer](https://www.adafruit.com/product/2269)
* [Nordic nrf52840 dongle](https://www.nordicsemi.com/Products/Development-hardware/nrf52840-dongle)

## Support

We provide best-effort support via the [Elixir Forum](https://elixirforum.com/)
and the [#nerves-bluetooth channel on the Elixir
Slack](https://elixir-slackin.herokuapp.com/). If you need more immediate
support or feature additions, commercial support is provided by [Binary
Noggin](https://binarynoggin.com).

## License

The source code is released under Apache License 2.0.

Check [NOTICE](NOTICE) and [LICENSE](LICENSE) files for more information.
