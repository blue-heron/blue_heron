# Changelog

## v0.5.3

* Enhancements
  * Updated ex_doc and property_table (Thanks @fhunleth ❤️)
  * Updated CI to build for Elixir 1.18 and 1.17 (Thanks @fhunleth ❤️)

## v0.5.2

* Enhancements
  * Changed the Elixir version requirement to match Nerves.
  This fixes an unneeded warning on Elixir versions older than 1.18.

## v0.5.1

* Enhancements
  * Added `BlueHeron.HCI.Transport.transport_ready?/0`
* Bugfixes
  * Fixed issue where transport would fail to initialize due to garbage data needing
    to be flushed

## v0.5.0

* Enhancements
  * `:blue_heron` is now it's own application
  * Rewrote `BlueHeron.HCI.Transport` to support the new supervision structure
  * Enable SMP by default
  * Persist GATT into a `PropertyTable` to allow for better error handling
  * Creating a Peripheral is now a little simpler and supervised
  * Added Broadcaster role
* Depreciations
  * Removed `BlueHeron.Context`
  * Removed `BlueHeronTransportUART` and `BlueHeronTransportUSB`

## v0.4.2

* Bugfixes
  * Fixed ACL messages not being delivered to parent process (Thanks @acadeau ❤️)

## v0.4.1

* Enhancements
  * Added `set_scan_response_data` HCI command and Peripheral function
    * This allows for an additional 31 bytes of advertising data to be used

## v0.4.0

* Enhancements
  * Added initial implementation of SMP (Thanks @markushutzler ❤️)
  * Added flow control for ACL data
  * Added new HCI commands required for SMP
* Bugfixes
  * Fixed errors in GATT

## v0.3.0

* Enhancements
  * Added initial implementation of GATT (Thanks @trarbr ❤️)

## v0.2.1

* Enhancements
  * Added HCI commands for GATT (Thanks @trarbr ❤️)

## v0.2.0

* Potential breaking changes
  There was quite a bit of internal adjustments and refactoring to cleanup
  implementation, although no core functions were changed. You should see
  no difference when updating but it was worth watching your implementation
  after updating in case something was missed in the cleanup

* Enhancements
  * Add new Address module to simplify the different address interpretations
  * Allow disabling logging to /tmp/hcidump.pklg file (Thanks @axelson!)
  * Lots of HCI Commands added to better support default behavior (Thanks @trarbr!)

* Fixes
  * fix/workaround for the rpi3 (Thanks @axelson!)
  * Fixed dmesg output display in govee example readme (Thanks @kevinansfield!)

## v0.1.1

* Bugfixes
  * Disconnecting from an ATT client works now
  * Reconnect now works
  * Sending a `connection_create` cmd when a device is unavailable
    retries now
  * `connection_complete` event now uses the correct address
  * Multiple ATT clients can now be started simultaneously
  * HCI and ACL calls will now timeout rather than hang forever
    endianness
  * Transport now supports having multiple commands in flight
* Enhancements
  * Added `btsnoop` parser

## v0.1.0

Initial release
