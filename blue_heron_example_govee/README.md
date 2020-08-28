# BlueHeronExampleGovee

Sample ATT application that can control
the Govee LED Light Bulb
They can be found [here](https://www.amazon.com/MINGER-Dimmable-Changing-Equivalent-Multi-Color/dp/B07CL2RMR7/)

## USB

```elixir
{:ok, pid} = BlueHeronExampleGovee.start_link(:usb, vid: 0x0bda, pid: 0xb82c)
:ok = BlueHeronExampleGovee.set_color(pid, 0xFFFF40)
```

## UART

```elixir
{:ok, pid} = BlueHeronExampleGovee.start_link(:uart, device: "ttyACM0")
:ok = BlueHeronExampleGovee.set_color(pid, 0xFFFF40)
```
