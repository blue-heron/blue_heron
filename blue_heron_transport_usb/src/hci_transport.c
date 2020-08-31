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

#include <errno.h>
#include <stdarg.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <stdbool.h>
#include <poll.h>
#include "erlcmd.h"
#include "btusb.h"
#include "hci_transport.h"

#define NUM_POLLFD_ENTRIES 32
#define FIRST_USB_POLLFD_ENTRY 1

static struct erlcmd handler;
static struct pollfd fdset[NUM_POLLFD_ENTRIES];
static int num_pollfds = 0;

/**
 * Send a log message to Erlang
 *
 * These are intended as a debug aide. See hci_transport.h to enable/disable
 * more messages.
 */
void send_log(char level, const char *fmt, ...)
{
    // Send the event to Elixir to be logged
    uint8_t message[256];

    va_list ap;
    va_start(ap, fmt);
    int size = vsnprintf((char *) &message[4], sizeof(message) - 4, fmt, ap);
    va_end(ap);

    if (size > 0) {
        message[2] = LOG_MESSAGE_PACKET;
        message[3] = level;
        erlcmd_send(message, size + 4);
    }
}

void report_event(uint8_t packet_type, const uint8_t *buffer, size_t buffer_size)
{
    uint8_t response[buffer_size + 3];
    response[2] = packet_type;
    memcpy(&response[3], buffer, buffer_size);
    erlcmd_send(response, buffer_size + 3);
}

static void pollfd_added(int fd, short events, void *user_data)
{
    if (num_pollfds == NUM_POLLFD_ENTRIES)
        fatal("raise the number of pollfds");

    fdset[num_pollfds].fd = fd;
    fdset[num_pollfds].events = events;
    fdset[num_pollfds].revents = 0;

    num_pollfds++;
}

static void pollfd_removed(int fd, void *user_data)
{
    for (int i = FIRST_USB_POLLFD_ENTRY; i < NUM_POLLFD_ENTRIES; i++) {
        if (fdset[i].fd == fd) {
            memmove(&fdset[i], &fdset[i + 1], (num_pollfds - i - 1) * sizeof(fdset[0]));
            num_pollfds--;

            // Set obviously invalid fd on newly freed entry to make debugging less confusing.
            fdset[num_pollfds].fd = -1;
            return;
        }
    }
    fatal("pollfd_removed unexpected fd=%d", fd);
}

static void hci_handle_request(const uint8_t *buffer, size_t length, void *cookie)
{
    debug("hci_handle_request: len=%lu, event=%u", length, buffer[2]);
    switch (buffer[2]) {
    case HCI_COMMAND_PACKET:
        btusb_send_cmd_packet(&buffer[3], length - 1);
        break;
    case HCI_ACL_DATA_PACKET:
        btusb_send_acl_packet(&buffer[3], length - 1);
        break;
    default:
        fatal("hci_handle_request: unexpected packet type %u", buffer[2]);
    }
}

static void hci_transport_init()
{
    // erlcmd_init must be called first, since log messages get sent through it
    erlcmd_init(&handler, hci_handle_request, NULL);

    // Initialize the file descriptor set for polling
    memset(fdset, -1, sizeof(fdset));
    fdset[0].fd = STDIN_FILENO;
    fdset[0].events = POLLIN;
    fdset[0].revents = 0;
    num_pollfds = 1;
}

struct acceptance_criteria {
    uint16_t vid;
    uint16_t pid;
    uint8_t bus_number;
    uint8_t device_number;
};

static bool accept_by_vid_pid(struct libusb_device *dev, const struct libusb_device_descriptor *desc, void *cookie)
{
    const struct acceptance_criteria *c = (const struct acceptance_criteria *) cookie;

    return c->vid == desc->idVendor && c->pid == desc->idProduct;
}

static bool accept_by_location(struct libusb_device *dev, const struct libusb_device_descriptor *desc, void *cookie)
{
    const struct acceptance_criteria *c = (const struct acceptance_criteria *) cookie;

    return c->bus_number == libusb_get_bus_number(dev) && c->device_number == libusb_get_device_address(dev);
}

static bool accept_first(struct libusb_device *dev, const struct libusb_device_descriptor *desc, void *cookie)
{
    return true;
}

int main(int argc, char const *argv[])
{
    hci_transport_init();

    acceptable_device_cb acceptable_device;
    struct acceptance_criteria ac;

    if (argc == 4 && strcmp(argv[1], "open_by_vid_pid") == 0) {
        ac.vid = (uint16_t) strtoul(argv[2], 0, 0);
        ac.pid = (uint16_t) strtoul(argv[3], 0, 0);
        acceptable_device = accept_by_vid_pid;
    } else if (argc == 4 && strcmp(argv[1], "open_by_bus") == 0) {
        ac.bus_number = (uint8_t) strtoul(argv[2], 0, 0);
        ac.device_number = (uint8_t) strtoul(argv[3], 0, 0);
        acceptable_device = accept_by_location;
    } else {
        acceptable_device = accept_first;
    }

    btusb_init(pollfd_added, pollfd_removed, NULL);

    if (btusb_open(acceptable_device, &ac))
        fatal("btusb_open failed");

    for (;;) {
        for (int i = 0; i < num_pollfds; i++)
            fdset[i].revents = 0;

        // Skipping libusb_get_next_timeout(). See check in btusb_init() that
        // guarantees that this is ok to do.
        int rc = poll(fdset, num_pollfds, -1);
        if (rc < 0) {
            // Retry if EINTR
            if (errno == EINTR)
                continue;

            fatal("poll failed with %d", errno);
        }

        if (fdset[0].revents & (POLLIN | POLLHUP))
            erlcmd_process(&handler);

        btusb_process();
    }

    btusb_exit();
    exit(EXIT_SUCCESS);
}
