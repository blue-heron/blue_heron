#ifndef BTUSB_H
#define BTUSB_H

#include <libusb-1.0/libusb.h>
#include <stdbool.h>
#include <stdint.h>

typedef bool (*acceptable_device_cb)(struct libusb_device *dev, const struct libusb_device_descriptor *desc, void *cookie);

void btusb_init(libusb_pollfd_added_cb added_cb, libusb_pollfd_removed_cb removed_cb, void *user_data);
void btusb_exit(void);
int btusb_open(acceptable_device_cb acceptable_device, void *cookie);
void btusb_process(void);

int btusb_find_bt_device(libusb_device **device, int *interface, acceptable_device_cb acceptable_device, void *cookie);

int btusb_send_cmd_packet(const uint8_t *packet, size_t size);
int btusb_send_acl_packet(const uint8_t *packet, size_t size);


#endif // BTUSB_H