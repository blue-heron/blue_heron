# BlueHeronTransportUSB

[![Hex version](https://img.shields.io/hexpm/v/blue_heron_transport_usb.svg "Hex version")](https://hex.pm/packages/blue_heron_transport_usb)
[![API docs](https://img.shields.io/hexpm/v/blue_heron_transport_usb.svg?label=hexdocs "API docs")](https://hexdocs.pm/blue_heron_transport_usb/BlueHeronTransportUSB.html)

BlueHeronTransportUSB follows Volume 3 Part B of the Bluetooth specification.
This should make it work with any off-the-shelf Bluetooth USB dongle. Currently,
though, only Realtek USB Bluetooth adapters have been tried. Others may require
firmware to be loaded to work.

BlueHeronTransportUSB can automatically select the first Bluetooth module in the
system. If you have multiple devices, you must specify the one to use by either
passing a `:vid` and `:pid` in the configuration or by updating the Elixir code
to support bus/device address specification (that would be awesome!).

To use, add `:blue_heron_transport_usb` to your `mix.exs` dependencies and adapt
the following to initialize a transport context.

```elixir
config = %BlueHeron.HCI.Transport.LibUSB{
  vid: 0x0bda, pid: 0xb82c
}
{:ok, ctx} = BlueHeron.transport(config)
```

## License

The source code is released under Apache License 2.0.

Check [NOTICE](NOTICE) and [LICENSE](LICENSE) files for more information.
