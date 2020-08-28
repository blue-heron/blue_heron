#ifndef BTUSB_H
#define BTUSB_H

#include <libusb-1.0/libusb.h>
#include <stdint.h>

void btusb_init(libusb_pollfd_added_cb added_cb, libusb_pollfd_removed_cb removed_cb, void *user_data);
void btusb_exit(void);
int btusb_open(uint16_t vid, uint16_t pid);
void btusb_process(void);

int btusb_send_cmd_packet(const uint8_t *packet, size_t size);
int btusb_send_acl_packet(const uint8_t *packet, size_t size);


#endif // BTUSB_H