# Changelog

## v0.2.0

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
