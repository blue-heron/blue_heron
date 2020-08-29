# GoveeBulb

This is a sample ATT application that can control a [Govee LED Light
Bulb](https://www.amazon.com/MINGER-Dimmable-Changing-Equivalent-Multi-Color/dp/B07CL2RMR7/).

## USB

On a Linux PC where `bluetoothd` immediately grabs the Bluetooth USB module as
soon as it's inserted, here's the current procedure: (yes, this isn't ideal)

```sh
$ sudo systemctl stop bluetooth

$ mix deps.get
$ mix compile

# The "easiest" way of giving the port process low level access to the USB
# port is to setuid root it. This needs to be done on every recompile, so
# if you're suddenly find that you don't have access, try running the following
# again.
$ sudo chown root:root ./_build/dev/lib/blue_heron_transport_libusb/priv/hci_transport
$ sudo chmod +s ./_build/dev/lib/blue_heron_transport_libusb/priv/hci_transport

# Run Elixir interactively
$ iex -S mix
iex> {:ok, pid} = GoveeBulb.start_link(:usb, vid: 0x0bda, pid: 0xb82c)
iex> GoveeBulb.set_color(pid, 0xFFFF40)
```

## UART

See [this
gist](https://gist.github.com/fhunleth/fae46998609814ae4a8abd44f6f08188#setting-up-a-test-environment)
for making a Raspberry Pi Zero W into a Bluetooth UART module for your laptop.

```elixir
{:ok, pid} = GoveeBulb.start_link(:uart, device: "ttyACM0")
GoveeBulb.set_color(pid, 0xFFFF40)
```
