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

#include <string.h>

#define USB_TRANSFERS_PER_ENDPOINT 4

// This looks like it's bigger than necessary, but I'm having trouble
// nailing down the max size in the spec.
#define HCI_MAX_BUFFER_SIZE 256

struct usb_endpoint {
    int address;
    size_t buffer_size;
    uint8_t *buffer_memory;
    struct libusb_transfer *transfers[USB_TRANSFERS_PER_ENDPOINT];
    struct libusb_transfer *free_list;
};

static struct usb_endpoint cmd_endpoint;
static struct usb_endpoint event_endpoint;
static struct usb_endpoint acl_in_endpoint;
static struct usb_endpoint acl_out_endpoint;

static libusb_device_handle *handle;

static void push_free_list(struct usb_endpoint *endpoint, struct libusb_transfer *transfer)
{
    transfer->user_data = endpoint->free_list;
    endpoint->free_list = transfer;
}

static struct libusb_transfer *pop_free_list(struct usb_endpoint *endpoint)
{
    struct libusb_transfer *transfer = endpoint->free_list;
    if (transfer)
        endpoint->free_list = (struct libusb_transfer *) transfer->user_data;
    return transfer;
}

static void event_callback(struct libusb_transfer *transfer)
{
    switch (transfer->status) {
    case LIBUSB_TRANSFER_COMPLETED:
        report_event(HCI_EVENT_PACKET, transfer->buffer, transfer->actual_length);
        break;

    case LIBUSB_TRANSFER_STALL:
        warn("Transfer stalled, trying again");
        libusb_clear_halt(handle, transfer->endpoint);
        break;

    case LIBUSB_TRANSFER_NO_DEVICE:
        fatal("Device removed");

    default:
        debug("unexpected status. endpoint %x, status %x, length %u",
              transfer->endpoint, transfer->status, transfer->actual_length);
        break;
    }

    int rc = libusb_submit_transfer(transfer);
    if (rc != LIBUSB_SUCCESS)
        fatal("libusb_submit_transfer failed: rc=%d", rc);
}

static void acl_in_callback(struct libusb_transfer *transfer)
{
    switch (transfer->status) {
    case LIBUSB_TRANSFER_COMPLETED:
        report_event(HCI_ACL_DATA_PACKET, transfer->buffer, transfer->actual_length);
        break;

    case LIBUSB_TRANSFER_STALL:
        warn("Transfer stalled, trying again");
        libusb_clear_halt(handle, transfer->endpoint);
        break;

    case LIBUSB_TRANSFER_NO_DEVICE:
        fatal("Device removed");

    default:
        debug("unexpected status. endpoint %x, status %x, length %u",
              transfer->endpoint, transfer->status, transfer->actual_length);
        break;
    }

    int rc = libusb_submit_transfer(transfer);
    if (rc != LIBUSB_SUCCESS)
        fatal("libusb_submit_transfer failed: rc=%d", rc);
}

static void command_out_callback(struct libusb_transfer *transfer)
{
    switch (transfer->status) {
    case LIBUSB_TRANSFER_COMPLETED:
        push_free_list(&cmd_endpoint, transfer);
        break;

    case LIBUSB_TRANSFER_STALL:
        warn("Transfer stalled, trying again");
        libusb_clear_halt(handle, transfer->endpoint);

        int rc = libusb_submit_transfer(transfer);
        if (rc != LIBUSB_SUCCESS)
            fatal("libusb_submit_transfer failed to submit command: rc=%d", rc);
        break;

    case LIBUSB_TRANSFER_NO_DEVICE:
        fatal("Device removed");

    default:
        debug("unexpected status. endpoint %x, status %x, length %u",
              transfer->endpoint, transfer->status, transfer->actual_length);
        push_free_list(&cmd_endpoint, transfer);
        break;
    }
}

static void acl_out_callback(struct libusb_transfer *transfer)
{
    switch (transfer->status) {
    case LIBUSB_TRANSFER_COMPLETED:
        push_free_list(&acl_out_endpoint, transfer);
        break;

    case LIBUSB_TRANSFER_STALL:
        warn("Transfer stalled, trying again");
        libusb_clear_halt(handle, transfer->endpoint);

        int rc = libusb_submit_transfer(transfer);
        if (rc != LIBUSB_SUCCESS)
            fatal("libusb_submit_transfer failed to submit command: rc=%d", rc);
        break;

    default:
        debug("unexpected status. endpoint %x, status %x, length %u",
              transfer->endpoint, transfer->status, transfer->actual_length);
        break;
    }
}

/**
 * Call into libusb to process any pending USB events
 */
void btusb_process()
{
    struct timeval tv;
    memset(&tv, 0, sizeof(struct timeval));
    int rc = libusb_handle_events_timeout_completed(NULL, &tv, NULL);
    if (rc != LIBUSB_SUCCESS)
        fatal("libusb_handle_events_timeout_completed returned %d", rc);
}

static void initialize_endpoint(struct usb_endpoint *endpoint,
                                unsigned char address,
                                size_t buffer_size,
                                unsigned char transfer_type,
                                libusb_transfer_cb_fn callback)
{
    endpoint->address = address;
    endpoint->buffer_size = buffer_size;
    endpoint->buffer_memory = malloc(buffer_size * USB_TRANSFERS_PER_ENDPOINT);
    endpoint->free_list = NULL;

    uint8_t *buffer = endpoint->buffer_memory;
    for (int i = 0; i < USB_TRANSFERS_PER_ENDPOINT; i++) {
        struct libusb_transfer *transfer = libusb_alloc_transfer(0);
        if (transfer == NULL)
            fatal("libusb_alloc_transfer failed");

        transfer->dev_handle = handle;
        transfer->endpoint = address;
        transfer->type = transfer_type;
        transfer->timeout = 0;
        transfer->buffer = buffer;
        transfer->length = buffer_size;
        transfer->user_data = endpoint->free_list;
        endpoint->free_list = transfer;
        transfer->callback = callback;

        buffer += buffer_size;
    }
}

static void submit_free_list(struct usb_endpoint *endpoint)
{
    for (;;) {
        struct libusb_transfer *transfer = pop_free_list(&event_endpoint);
        if (transfer == NULL)
            return;
        int rc = libusb_submit_transfer(transfer);
        if (rc != LIBUSB_SUCCESS)
            fatal("Error submitting transfer for endpoint %d: %d", transfer->endpoint, rc);
    }
}

void btusb_init(libusb_pollfd_added_cb added_cb, libusb_pollfd_removed_cb removed_cb, void *user_data)
{
    int rc = libusb_init(NULL);
    if (rc < 0)
        fatal("libusb_init failed %d", rc);

    libusb_set_option(NULL, LIBUSB_OPTION_LOG_LEVEL, LIBUSB_LOG_LEVEL_WARNING);

    libusb_set_pollfd_notifiers(NULL, added_cb, removed_cb, NULL);

    const struct libusb_pollfd **initial_pollfds = libusb_get_pollfds(NULL);
    for (int i = 0; initial_pollfds[i] != NULL; i++)
        added_cb(initial_pollfds[i]->fd, initial_pollfds[i]->events, NULL);
    libusb_free_pollfds(initial_pollfds);

    if (libusb_pollfds_handle_timeouts(NULL) == 0)
        fatal("Platform missing timerfd support. Need to implement timer handling...");
}

int btusb_open(acceptable_device_cb acceptable_device, void *cookie)
{
    libusb_device *device;
    int interface;
    if (btusb_find_bt_device(&device, &interface, acceptable_device, cookie) < 0) {
        warn("No acceptable Bluetooth modules found");
        return -1;
    }

    int rc = libusb_open(device, &handle);
    if (rc != LIBUSB_SUCCESS) {
        warn("libusb_open failed %d", rc);
        return -1;
    }

    rc = libusb_kernel_driver_active(handle, interface);
    if (rc == 1) {
    	// Kernel driver attached.  Disconnect it.
    	libusb_detach_kernel_driver(handle, interface);
    }

    rc = libusb_reset_device(handle);
    if (rc < 0)
        warn("libusb_reset_device failed. Ignoring");

    rc = libusb_claim_interface(handle, interface);
    if (rc != LIBUSB_SUCCESS) {
        warn("libusb_claim_interface failed %d", rc);
        return -1;
    }

    // Control endpoint
    initialize_endpoint(&cmd_endpoint, 0x00, HCI_MAX_BUFFER_SIZE + LIBUSB_CONTROL_SETUP_SIZE, LIBUSB_TRANSFER_TYPE_CONTROL, command_out_callback);

    // EP1, IN interrupt
    initialize_endpoint(&event_endpoint, 0x81, HCI_MAX_BUFFER_SIZE, LIBUSB_TRANSFER_TYPE_INTERRUPT, event_callback);
    submit_free_list(&event_endpoint);

    // EP2, IN bulk
    initialize_endpoint(&acl_in_endpoint, 0x82, HCI_MAX_BUFFER_SIZE, LIBUSB_TRANSFER_TYPE_BULK, acl_in_callback);
    submit_free_list(&acl_in_endpoint);

    // EP2, OUT bulk
    initialize_endpoint(&acl_out_endpoint, 0x02, HCI_MAX_BUFFER_SIZE, LIBUSB_TRANSFER_TYPE_BULK, acl_out_callback);

    return 0;
}

void btusb_exit()
{
    // The strategy here is let the OS clean up rather than try.
    //
    // The following code isn't particularly tested and probably crashes, but since
    // the OS has to be able to clean up anyway, why bother? Feel free to delete lines
    // if this causes confusing log messages.
    libusb_release_interface(handle, 0);
    libusb_close(handle);
    libusb_exit(NULL);
}

int btusb_send_cmd_packet(const uint8_t *packet, size_t size)
{
    debug("btusb_send_cmd_packet enter, size %lu", size);

    if (LIBUSB_CONTROL_SETUP_SIZE + size > cmd_endpoint.buffer_size) {
        warn("cmd packet too large (%d > %d)", size, cmd_endpoint.buffer_size - LIBUSB_CONTROL_SETUP_SIZE);
        return -1;
    }

    struct libusb_transfer *transfer = pop_free_list(&cmd_endpoint);
    if (transfer == NULL) {
        warn("Out of cmd transfer buffers. Dropping.");
        return -1;
    }

    uint8_t *buffer = transfer->buffer;
    libusb_fill_control_setup(buffer, LIBUSB_REQUEST_TYPE_CLASS | LIBUSB_RECIPIENT_INTERFACE, 0,
                              0, 0, size);
    memcpy(buffer + LIBUSB_CONTROL_SETUP_SIZE, packet, size);
    transfer->length = (int) (LIBUSB_CONTROL_SETUP_SIZE + size);

    int rc = libusb_submit_transfer(transfer);
    if (rc < 0) {
        warn("Error submitting cmd transfer %d", rc);
        return -1;
    }

    return 0;
}

int btusb_send_acl_packet(const uint8_t *packet, size_t size)
{
    debug("btusb_send_acl_packet enter, size %lu", size);

    if (size > acl_out_endpoint.buffer_size) {
        warn("ACL packet too large (%d > %d)", size, acl_out_endpoint.buffer_size);
        return -1;
    }

    struct libusb_transfer *transfer = pop_free_list(&acl_out_endpoint);
    if (transfer == NULL) {
        warn("Out of acl out transfer buffers. Dropping.");
        return -1;
    }

    memcpy(transfer->buffer, packet, size);
    transfer->length = size;

    int rc = libusb_submit_transfer(transfer);
    if (rc < 0) {
        warn("Error submitting acl transfer, %d", rc);
        return -1;
    }
    debug("sent ACL packet");

    return 0;
}
