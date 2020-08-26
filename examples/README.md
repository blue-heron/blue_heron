# Bluetooth Examples

## GoveeBTLed

## USB

```elixir
{:ok, pid} = Bluetooth.Example.GoveeBTLed.start_link(:usb, vid: 0x0bda, pid: 0xb82c)
:ok = Bluetooth.Example.GoveeBTLed.set_color(pid, 0xFFFF40)
```

## UART

```elixir
{:ok, pid} = Bluetooth.Example.GoveeBTLed.start_link(:uart, device: "ttyACM0")
:ok = Bluetooth.Example.GoveeBTLed.set_color(pid, 0xFFFF40)
```
