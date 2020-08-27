# BlueHeron

Elixir Bluetooth Library.

## Motivation

[Harald](https://github.com/smartrent/harald/) is unmaintained, and only
implements the lowest layer of the Bluetooth stack.

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

### LibUSB Transport

Partially implements Volume 3 Part B of the Bluetooth spec

```elixir
config = %BlueHeron.HCI.Transport.LibUSB{
  vid: 0x0bda, pid: 0xb82c
}
{:ok, ctx} = BlueHeron.transport(config)
```

### UART Transport

```elixir
config = %BlueHeron.HCI.Transport.UART{
  device: "/dev/ttyACM0",
  uart_opts: [speed: 115200],
}
{:ok, ctx} = BlueHeron.transport(config)
```
