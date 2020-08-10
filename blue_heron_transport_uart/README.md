# BlueHeronTransportUART

[![Hex version](https://img.shields.io/hexpm/v/blue_heron_transport_uart.svg "Hex version")](https://hex.pm/packages/blue_heron_transport_uart)
[![API docs](https://img.shields.io/hexpm/v/blue_heron_transport_uart.svg?label=hexdocs "API docs")](https://hexdocs.pm/blue_heron_transport_uart/BlueHeronTransportUART.html)

BlueHeron supports UART-based Bluetooth modules. Currently, this ONLY includes
the Cypress Semiconductor
[BCM43438](https://www.cypress.com/part/cychpset-p62s143438-1). This part is on
the Raspberry Pi Zero W and the Raspberry Pi 3 B. It is NOT on the 3 B+.

To use, add `:blue_heron_transport_uart` to your `mix.exs` dependencies and
adapt the following to initialize a transport context.

```elixir
config = %BlueHeron.HCI.Transport.UART{
  device: "/dev/ttyACM0",
  uart_opts: [speed: 115200],
}
{:ok, ctx} = BlueHeron.transport(config)
```

## License

The source code is released under the MIT license.

Check [NOTICE](NOTICE) and [LICENSE](LICENSE) files for more information.

