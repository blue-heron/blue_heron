#ifndef HCI_TRANSPORT_H
#define HCI_TRANSPORT_H

#include <stdint.h>
#include <stdlib.h>

// Erlang <-> C communication protocol
//
// <packet length> <type> <payload>
//
// packet length - 2 byte packet length in big endian
// type - 1 byte type field
//
// Packet types match UART HCI packet types for convenience.

#define HCI_COMMAND_PACKET          0x01
#define HCI_ACL_DATA_PACKET         0x02
#define HCI_SYNCHRONOUS_DATA_PACKET 0x03
#define HCI_EVENT_PACKET            0x04
#define LOG_MESSAGE_PACKET          0xfc // custom

//#define DEBUG
#ifdef DEBUG
#define debug(...) do { send_log(2, __VA_ARGS__); } while(0)
#else
#define debug(...)
#endif
#define warn(...) do { send_log(1, __VA_ARGS__); } while (0)
#define fatal(...) do { send_log(0, __VA_ARGS__); exit(EXIT_FAILURE); } while (0)

void send_log(char level, const char *fmt, ...);
void report_event(uint8_t packet_type, const uint8_t *buffer, size_t buffer_size);

#endif
