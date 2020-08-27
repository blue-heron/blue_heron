# Bluetooth Examples

## GoveeBTLed

Sample ATT application that can control
the Govee LED Light Bulb
They can be found [here](https://www.amazon.com/MINGER-Dimmable-Changing-Equivalent-Multi-Color/dp/B07CL2RMR7/)

## USB

```elixir
{:ok, pid} = BlueHeron.Example.GoveeBTLed.start_link(:usb, vid: 0x0bda, pid: 0xb82c)
:ok = BlueHeron.Example.GoveeBTLed.set_color(pid, 0xFFFF40)
```

## UART

```elixir
{:ok, pid} = BlueHeron.Example.GoveeBTLed.start_link(:uart, device: "ttyACM0")
:ok = BlueHeron.Example.GoveeBTLed.set_color(pid, 0xFFFF40)
```
