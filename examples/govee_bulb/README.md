# GoveeBulb

This is a sample ATT application that can control a [Govee LED Light
Bulb](https://www.amazon.com/MINGER-Dimmable-Changing-Equivalent-Multi-Color/dp/B07CL2RMR7/).

## USB

```elixir
{:ok, pid} = GoveeBulb.start_link(:usb, vid: 0x0bda, pid: 0xb82c)
:ok = GoveeBulb.set_color(pid, 0xFFFF40)
```

## UART

```elixir
{:ok, pid} = GoveeBulb.start_link(:uart, device: "ttyACM0")
:ok = GoveeBulb.set_color(pid, 0xFFFF40)
```
