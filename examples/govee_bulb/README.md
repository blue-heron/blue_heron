# GoveeBulb

This is a sample ATT application that can control a [Govee LED Light
Bulb](https://www.amazon.com/MINGER-Dimmable-Changing-Equivalent-Multi-Color/dp/B07CL2RMR7/).

## USB

On a Linux PC where `bluetoothd` immediately grabs the Bluetooth USB module as
soon as it's inserted, here's the current procedure: (yes, this isn't ideal)

Before you begin you need to find the vendor id (`vid`) and product id (`pid`) of your bluetooth adapter. One way of doing that is by inspecting the output of `dmesg` after plugging in your adapter:

<details>
  <summary>Example dmesg output</summary>
  ```
  [174634.130045] usb 1-9: new full-speed USB device number 8 using xhci_hcd
  [174634.453638] usb 1-9: New USB device found, idVendor=0a5c, idProduct=21e8, bcdDevice= 1.12
  [174634.453643] usb 1-9: New USB device strings: Mfr=1, Product=2, SerialNumber=3
  [174634.453645] usb 1-9: Product: BCM20702A0
  [174634.453647] usb 1-9: Manufacturer: Broadcom Corp
  [174634.453649] usb 1-9: SerialNumber: 00190E112B40
  [174634.513882] audit: type=1130 audit(1599509227.196:198): pid=1 uid=0 auid=4294967295 ses=4294967295 msg='unit=systemd-rfkill comm="systemd" exe="/usr/lib/systemd/systemd" hostname=? addr=? terminal=? res=success'
  [174634.581454] Bluetooth: hci0: BCM: chip id 63
  [174634.584453] Bluetooth: hci0: BCM: features 0x07
  [174634.602454] Bluetooth: hci0: BCM20702A
  [174634.602459] Bluetooth: hci0: BCM20702A1 (001.002.014) build 0000
  [174634.604527] Bluetooth: hci0: BCM20702A1 'brcm/BCM20702A1-0a5c-21e8.hcd' Patch
  [174636.066728] Bluetooth: hci0: Broadcom Bluetooth Device
  [174636.066733] Bluetooth: hci0: BCM20702A1 (001.002.014) build 1459
  [174639.517580] audit: type=1131 audit(1599509232.199:199): pid=1 uid=0 auid=4294967295 ses=4294967295 msg='unit=systemd-rfkill comm="systemd" exe="/usr/lib/systemd/systemd" hostname=? addr=? terminal=? res=success'
  ```

  In this example the vid is `0a5c`, and the pid is `21e8`, which can be written in elixir hex notation as `0x0a5c` and `0x21e8`.
</details>

```sh
$ sudo systemctl stop bluetooth

$ mix deps.get
$ mix compile

# The "easiest" way of giving the port process low level access to the USB
# port is to setuid root it. This needs to be done on every recompile, so
# if you suddenly find that you don't have access, try running the following
# again.
$ sudo chown root:root ./_build/dev/lib/blue_heron_transport_usb/priv/hci_transport
$ sudo chmod +s ./_build/dev/lib/blue_heron_transport_usb/priv/hci_transport

# Run Elixir interactively
$ iex -S mix
# Use the pid and vid you found earlier here:
iex> {:ok, pid} = GoveeBulb.start_link(:usb, %{vid: 0x0bda, pid: 0xb82c})
iex> GoveeBulb.set_color(pid, 0xFFFF40)
```

## UART

See [this
gist](https://gist.github.com/fhunleth/fae46998609814ae4a8abd44f6f08188#setting-up-a-test-environment)
for making a Raspberry Pi Zero W into a Bluetooth UART module for your laptop.

```elixir
# Note: your uart device may be something different than /dev/ttyACM0, in that case substitute it here
{:ok, pid} = GoveeBulb.start_link(:uart, %{device: "ttyACM0"})
GoveeBulb.set_color(pid, 0xFFFF40)
```
