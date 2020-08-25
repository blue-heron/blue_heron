# Bluetooth Examples

## GoveBTLED

## USB

```elixir
Bluetooth.Example.GoveBTLED.start_link(:usb, vid: 0x0bda, pid: 0xb82c)
Bluetooth.Example.GoveBTLED.set_color(pid, 0xFFFF40)
```

## UART

```elixir
Bluetooth.Example.GoveBTLED.start_link(:uart, device: "ttyACM0")
Bluetooth.Example.GoveBTLED.set_color(pid, 0xFFFF40)
```
