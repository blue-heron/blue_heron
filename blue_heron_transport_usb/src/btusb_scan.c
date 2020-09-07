// Copyright 2020 SmartRent.com, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#include "btusb.h"
#include "hci_transport.h"

#include <stdbool.h>

static bool possible_bt_device(const struct libusb_device_descriptor *desc)
{
    // Standalone BT device
    if (desc->bDeviceClass == LIBUSB_CLASS_WIRELESS &&
        desc->bDeviceSubClass == 1 /* Radio Frequency */ &&
        desc->bDeviceProtocol == 1 /* Bluetooth */)
        return true;

    // Multi-function device so this is a maybe.
    if (desc->bDeviceClass == 239 /* Miscellaneous Device */ &&
        desc->bDeviceSubClass == 2 /*  */ &&
        desc->bDeviceProtocol == 1 /* Interface Association */)
        return true;

    // Vendor-specific. Maybe??
    if (desc->bDeviceClass == 255 /* Vendor-specific */)
        return true;

    return false;
}

static bool has_expected_endpoints(const struct libusb_interface_descriptor *idesc)
{
    // Other code is hardcoded to this config, so check that it's what is expected.
    if (idesc->bNumEndpoints < 3)
        return false;

    bool has_interrupt_in = false;
    bool has_bulk_in = false;
    bool has_bulk_out = false;

    for (int i = 0; i < idesc->bNumEndpoints; i++) {
        switch (idesc->endpoint[i].bEndpointAddress) {
        case 0x81:
            has_interrupt_in = true;
            break;
        case 0x02:
            has_bulk_out = true;
            break;
        case 0x82:
            has_bulk_in = true;
            break;
        default:
            break;
        }
    }
    return has_interrupt_in && has_bulk_in && has_bulk_out;
}

static int find_bt_interface(struct libusb_device *dev)
{
    struct libusb_config_descriptor *config;
    if (libusb_get_active_config_descriptor(dev, &config) == LIBUSB_SUCCESS) {
        for (int j = 0; j < config->bNumInterfaces; j++) {
            const struct libusb_interface *iface = &config->interface[j];
            const struct libusb_interface_descriptor *idesc = iface->altsetting;

            if (idesc->bInterfaceClass == LIBUSB_CLASS_WIRELESS &&
                idesc->bInterfaceSubClass == 1 &&
                idesc->bInterfaceProtocol == 1 &&
                has_expected_endpoints(idesc)) {
                return j;
            } else if (idesc->bInterfaceClass == 255 &&
                       has_expected_endpoints(idesc)) {
                return j;
            }
        }
        libusb_free_config_descriptor(config);
    }
    return -1;
}

/**
 * Find a Bluetooth device and return it and the USB interface to use
 */
int btusb_find_bt_device(libusb_device **device, int *interface, acceptable_device_cb acceptable_device, void *cookie)
{
    struct libusb_device **devs;
    ssize_t count = libusb_get_device_list(NULL, &devs);
    if (count < 0)
        return -1;

    int rc = -1;
    for (int i = 0; i < count; i++) {
        struct libusb_device* dev = devs[i];

        // Skip anything that's not a possible BT device or not acceptable to
        // the caller.
        struct libusb_device_descriptor desc;
        if (libusb_get_device_descriptor(dev, &desc) != LIBUSB_SUCCESS ||
            !possible_bt_device(&desc))
            continue;

        *interface = find_bt_interface(dev);

        if (*interface >= 0) {
            if (acceptable_device(dev, &desc, cookie)) {
                // Return the first on that's acceptable by both us and the caller
                warn("Using BT device at bus %d, device %d: ID %04x:%04x",
                    libusb_get_bus_number(dev), libusb_get_device_address(dev), desc.idVendor, desc.idProduct);

                libusb_ref_device(dev);
                *device = dev;
                rc = 0;
                break;
            } else {
                warn("Skipping BT device at bus %d, device %d: ID %04x:%04x",
                    libusb_get_bus_number(dev), libusb_get_device_address(dev), desc.idVendor, desc.idProduct);
            }

        }
    }

    libusb_free_device_list(devs, 1);
    return rc;
}
