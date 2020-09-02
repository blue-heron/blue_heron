# BlueHeron

[![CircleCI](https://circleci.com/gh/smartrent/blue_heron.svg?style=svg)](https://circleci.com/gh/smartrent/blue_heron)

BlueHeron is a new Elixir Bluetooth LE Library that communicates directly with
Bluetooth modules via HCI. It is VERY much under construction, and we expect the
user API to change as we're able to simplify and improve it.

This is the main repository. Most information is in one of the following
directories:

* [blue_heron](blue_heron) - The main BlueHeron library
* [blue_heron_transport_uart](blue_heron_transport_uart) - Transport for
  Bluetooth modules connected via a UART
* [blue_heron_transport_usb](blue_heron_transport_usb) - Transport for
  USB Bluetooth modules
* [examples](examples) - Look here for example code

If you're new to BlueHeron, we recommend skimming the main `blue_heron` project
first and then checking out the examples.

## Support

We provide best-effort support via the [Elixir Forum](https://elixirforum.com/)
and the [#nerves-bluetooth channel on the Elixir
Slack](https://elixir-slackin.herokuapp.com/). If you need more immediate
support or feature additions, commercial support is provided by [Binary
Noggin](https://binarynoggin.com).

## Licensing

The majority of the code in this project is covered by the Apache 2 license. See
subdirectories for details.

