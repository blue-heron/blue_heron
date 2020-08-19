# Elixir Bluetooth

Rewrite Therapy for an Elixir Bluetooth Library.

## Motivation

[Harald](https://github.com/smartrent/harald/) is unmaintained, and only
implements the lowest layer of the Bluetooth stack. This project currently uses
it's partial HCI decoding/encoding functionality.

## HCI Logging

This project includes a Logger backend to dump PKTLOG format. This is the same format
that Android, IOS, btstack, hcidump, and bluez use.

Add the backend to debug all data to/from the HCI transport:

```elixir
iex> Logger.add_backend(Bluetooth.HCIDump.Logger)
Bluetooth.HCIDump.Logger
```

This will produce a file `/tmp/hcidump.pklg` that can be loaded into Wireshark.

**NOTE** This project configures logger so it is always enabled by default.

The `Bluetooth.HCIDump.Logger` module implements a superset of Elixir's builtin logger and
all non-HCI data is forwarded directly to Elixir's Logger.

```elixir
iex> require Bluetooth.HCIDump.Logger, as: Logger
Bluetooth.HCIDump.Logger
iex> Logger.debug("sample data")

16:43:46.496 [debug] sample data

iex>
```

## Usage

Currently only the HCI transport layer is implemented. See below for examples.

### LibUSB Transport

Partially implements Volume 3 Part B of the Bluetooth spec

```elixir
alias Harald.HCI.{
  ControllerAndBaseband,
  InformationalParameters,
  LinkPolicy
}
config = %Bluetooth.HCI.Transport.LibUSB{
  vid: 0x0bda, pid: 0xb82c,
  init_commands: [
    ControllerAndBaseband.reset(),
    InformationalParameters.read_local_version(),
    ControllerAndBaseband.read_local_name(),
    InformationalParameters.read_local_supported_commands(),
    InformationalParameters.read_bd_addr(),
    InformationalParameters.read_buffer_size(),
    InformationalParameters.read_local_supported_features(),
    ControllerAndBaseband.set_event_mask(<<0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x3F>>),
    ControllerAndBaseband.write_simple_pairing_mode(true),
    ControllerAndBaseband.write_page_timeout(0x60),
    LinkPolicy.write_default_link_policy_settings(0x00),
    ControllerAndBaseband.write_class_of_device(0x0C027A),
    ControllerAndBaseband.write_local_name("Bluetooth Test"),
    ControllerAndBaseband.write_extended_inquiry_response(false, <<0x1A, 0x9, 0x42, 0x54, 0x73, 0x74, 0x61, 0x63, 0x6B, 0x20, 0x45, 0x20, 0x38, 0x3A, 0x34, 0x45, 0x3A, 0x30, 0x36, 0x3A, 0x38, 0x31, 0x3A, 0x41, 0x34, 0x3A, 0x35, 0x30, 0x20>>),
    ControllerAndBaseband.write_inquiry_mode(0x0),
    ControllerAndBaseband.write_secure_connections_host_support(true),
    <<0x1A, 0x0C, 0x01, 0x00>>,
    <<0x2F, 0x0C, 0x01, 0x01>>,
    <<0x5B, 0x0C, 0x01, 0x01>>,
    <<0x02, 0x20, 0x00>>,
    <<0x6D, 0x0C, 0x02, 0x01, 0x00>>,
    <<0x0F, 0x20, 0x00>>,
    <<0x0B, 0x20, 0x07, 0x01, 0x30, 0x00, 0x30, 0x00, 0x00, 0x00>>
  ]
}
Bluetooth.HCI.Transport.start_link(config)
```

### UART Transport

```elixir
alias Harald.HCI.{
  ControllerAndBaseband,
  InformationalParameters,
  LinkPolicy
}
config = %Bluetooth.HCI.Transport.UART{
  device: "/dev/ttyACM0",
  uart_opts: [speed: 115200],
  init_commands: [
    ControllerAndBaseband.reset(),
    InformationalParameters.read_local_version(),
    ControllerAndBaseband.read_local_name(),
    InformationalParameters.read_local_supported_commands(),
    InformationalParameters.read_bd_addr(),
    InformationalParameters.read_buffer_size(),
    InformationalParameters.read_local_supported_features(),
    ControllerAndBaseband.set_event_mask(<<0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x3F>>),
    ControllerAndBaseband.write_simple_pairing_mode(true),
    ControllerAndBaseband.write_page_timeout(0x60),
    LinkPolicy.write_default_link_policy_settings(0x00),
    ControllerAndBaseband.write_class_of_device(0x0C027A),
    ControllerAndBaseband.write_local_name("Bluetooth Test"),
    ControllerAndBaseband.write_extended_inquiry_response(false, <<0x1A, 0x9, 0x42, 0x54, 0x73, 0x74, 0x61, 0x63, 0x6B, 0x20, 0x45, 0x20, 0x38, 0x3A, 0x34, 0x45, 0x3A, 0x30, 0x36, 0x3A, 0x38, 0x31, 0x3A, 0x41, 0x34, 0x3A, 0x35, 0x30, 0x20>>),
    ControllerAndBaseband.write_inquiry_mode(0x0),
    ControllerAndBaseband.write_secure_connections_host_support(true),
    <<0x1A, 0x0C, 0x01, 0x00>>,
    <<0x2F, 0x0C, 0x01, 0x01>>,
    <<0x5B, 0x0C, 0x01, 0x01>>,
    <<0x02, 0x20, 0x00>>,
    <<0x6D, 0x0C, 0x02, 0x01, 0x00>>,
    <<0x0F, 0x20, 0x00>>,
    <<0x0B, 0x20, 0x07, 0x01, 0x30, 0x00, 0x30, 0x00, 0x00, 0x00>>
  ]
}
Bluetooth.HCI.Transport.start_link(config)
```

### NULL Transport

Useful transport for testing and development

```elixir
config = %Bluetooth.HCI.Transport.NULL{
  init_commands: [
    Harald.HCI.ControllerAndBaseband.reset()
  ],
  replies: %{
    Harald.HCI.ControllerAndBaseband.reset() => "\x0e\x04\x03\x03\x0c\x00"
  }
}
Bluetooth.HCI.Transport.start_link(config)
```
