# Bluetooth Examples

## LEScanConnect

## USB

```elixir
config = %Bluetooth.HCI.Transport.LibUSB{
  vid: 0x0bda, pid: 0xb82c,
  init_commands: []
}
Bluetooth.Example.LEScanConnect.start_link(config)
```

## UART

```elixir
config = %Bluetooth.HCI.Transport.UART{
  device: "ttyACM0",
  uart_opts: [speed: 115200],
  init_commands: []
}
Bluetooth.Example.LEScanConnect.start_link(config)
```
