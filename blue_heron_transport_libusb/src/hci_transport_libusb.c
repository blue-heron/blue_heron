/*
 * Much of this code was found in the great BluetoothStack project:
 * https://github.com/bluekitchen/btstack/blob/master/platform/libusb/hci_transport_h2_libusb.c
 */

#include <libusb-1.0/libusb.h>
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

// Match the UART HCI packet types for convenience.
#define HCI_COMMAND_PACKET          0x01
#define HCI_ACL_DATA_PACKET         0x02
#define HCI_SYNCHRONOUS_DATA_PACKET 0x03
#define HCI_EVENT_PACKET            0x04
#define LOG_MESSAGE_PACKET          0xfc // custom

#define ACL_IN_BUFFER_COUNT    3
#define EVENT_IN_BUFFER_COUNT  3
#define HCI_ACL_BUFFER_SIZE 255
#define HCI_INCOMING_PRE_BUFFER_SIZE 2

#define ASYNC_POLLING_INTERVAL_MS 1

#define DEBUG
#ifdef DEBUG
#define debug(...) do { send_log(__VA_ARGS__); } while(0)
#else
#define debug(...)
#endif
#define warn(...) do { send_log(__VA_ARGS__); } while (0)
#define fatal(...) do { send_log(__VA_ARGS__); exit(EXIT_FAILURE); } while (0)

typedef enum {
    LIB_USB_CLOSED = 0,
    LIB_USB_OPENED,
    LIB_USB_DEVICE_OPENED,
    LIB_USB_INTERFACE_CLAIMED,
    LIB_USB_TRANSFERS_ALLOCATED
} libusb_state_t;

static libusb_state_t libusb_state = LIB_USB_CLOSED;
static libusb_device_handle *handle;

static struct libusb_transfer *command_out_transfer;
static struct libusb_transfer *acl_out_transfer;
static struct libusb_transfer *event_in_transfer[EVENT_IN_BUFFER_COUNT];
static struct libusb_transfer *acl_in_transfer[ACL_IN_BUFFER_COUNT];

// outgoing buffer for HCI Command packets
static uint8_t hci_cmd_buffer[3 + 256 + LIBUSB_CONTROL_SETUP_SIZE];
static uint8_t hci_acl_out_buffer[HCI_ACL_BUFFER_SIZE];

// incoming buffer for HCI Events and ACL Packets
static uint8_t hci_event_in_buffer[EVENT_IN_BUFFER_COUNT][HCI_ACL_BUFFER_SIZE]; // bigger than largest packet
static uint8_t hci_acl_in_buffer[ACL_IN_BUFFER_COUNT][HCI_INCOMING_PRE_BUFFER_SIZE +
                                                      HCI_ACL_BUFFER_SIZE];

// For (ab)use as a linked list of received packets
static struct libusb_transfer *handle_packet;

// endpoint addresses
static int event_in_addr;
static int acl_in_addr;
static int acl_out_addr;

static void queue_transfer(struct libusb_transfer *transfer);
static int usb_close(void);

static void send_log(const char *fmt, ...)
{
    // Send the event to Elixir to be logged
    uint8_t message[256];

    va_list ap;
    va_start(ap, fmt);
    int size = vsnprintf((char *) &message[3], sizeof(message) - 3, fmt, ap);
    va_end(ap);

    if (size > 0) {
        message[2] = LOG_MESSAGE_PACKET;
        erlcmd_send(message, size + 3);
    }
}

static void queue_transfer(struct libusb_transfer *transfer)
{
    // debug("queue_transfer %p, endpoint %x size %u", transfer, transfer->endpoint, transfer->actual_length);
    transfer->user_data = NULL;

    // insert first element
    if (handle_packet == NULL) {
        handle_packet = transfer;
        return;
    }

    // Walk to end of list and add current packet there
    struct libusb_transfer *temp = handle_packet;
    while (temp->user_data) {
        temp = (struct libusb_transfer *)temp->user_data;
    }
    temp->user_data = transfer;
}


LIBUSB_CALL static void async_callback(struct libusb_transfer *transfer)
{
    int c;

    if (libusb_state != LIB_USB_TRANSFERS_ALLOCATED) {
        debug("shutdown, transfer %p", transfer);
    }

    if (libusb_state != LIB_USB_TRANSFERS_ALLOCATED) {
        for (c = 0; c < EVENT_IN_BUFFER_COUNT; c++) {
            if (transfer == event_in_transfer[c]) {
                libusb_free_transfer(transfer);
                event_in_transfer[c] = 0;
                return;
            }
        }
        for (c = 0; c < ACL_IN_BUFFER_COUNT; c++) {
            if (transfer == acl_in_transfer[c]) {
                libusb_free_transfer(transfer);
                acl_in_transfer[c] = 0;
                return;
            }
        }
        return;
    }

    int r;
    if (transfer->status == LIBUSB_TRANSFER_COMPLETED) {
        // debug("-> Transfer complete");
        queue_transfer(transfer);
    } else if (transfer->status == LIBUSB_TRANSFER_STALL) {
        warn("-> Transfer stalled, trying again");
        r = libusb_clear_halt(handle, transfer->endpoint);
        if (r) {
            warn("Error clearing halt %d", r);
        }
        r = libusb_submit_transfer(transfer);
        if (r) {
            warn("Error re-submitting transfer %d", r);
        }
    } else {
        debug("async_callback. not data -> resubmit transfer, endpoint %x, status %x, length %u",
              transfer->endpoint, transfer->status, transfer->actual_length);
        // No usable data, just resubmit packet
        r = libusb_submit_transfer(transfer);
        if (r) {
            warn("Error re-submitting transfer %d", r);
        }
    }
    // debug("end async_callback");
}

static void report_event(uint8_t packet_type, const uint8_t *buffer, size_t buffer_size)
{
    uint8_t response[buffer_size + 3];
    response[2] = packet_type;
    memcpy(&response[3], buffer, buffer_size);
    erlcmd_send(response, buffer_size + 3);
}

static void handle_completed_transfer(struct libusb_transfer *transfer)
{
    int resubmit = 0;

    // debug("handle_completed_transfer endpoint %x %x, %x", transfer->endpoint, acl_in_addr, transfer->endpoint == acl_in_addr);
    if (transfer->endpoint == event_in_addr) {
        report_event(HCI_EVENT_PACKET, transfer->buffer, transfer->actual_length);
        resubmit = 1;
    } else if (transfer->endpoint == acl_in_addr) {
        report_event(HCI_ACL_DATA_PACKET, transfer->buffer, transfer->actual_length);
        resubmit = 1;
    } else if (transfer->endpoint == 0) {
        // debug("command done, size %u", transfer->actual_length);
    } else if (transfer->endpoint == acl_out_addr) {
        // debug("acl out done, size %u", transfer->actual_length);
    } else {
        warn("usb_process_ds endpoint unknown %x", transfer->endpoint);
    }

    if (libusb_state == LIB_USB_TRANSFERS_ALLOCATED && resubmit) {
        // Re-submit transfer
        transfer->user_data = NULL;
        int r = libusb_submit_transfer(transfer);
        if (r) {
            warn("Error re-submitting transfer %d", r);
        }
    }
}

static void usb_process()
{
    // debug("begin usb_process");
    // always handling an event as we're called when data is ready
    struct timeval tv;
    memset(&tv, 0, sizeof(struct timeval));
    int rc = libusb_handle_events_timeout_completed(NULL, &tv, NULL);
    if (rc != LIBUSB_SUCCESS)
        fatal("libusb_handle_events_timeout_completed returned %d", rc);

    // Handle any packet in the order that they were received
    while (handle_packet && libusb_state == LIB_USB_TRANSFERS_ALLOCATED) {
        // debug("handle packet %p, endpoint %x, status %x", handle_packet, handle_packet->endpoint, handle_packet->status);

        // pop next transfer
        struct libusb_transfer *transfer = handle_packet;
        handle_packet = (struct libusb_transfer *) handle_packet->user_data;

        // handle transfer
        handle_completed_transfer(transfer);
    }
    // debug("end usb_process");
}

static int prepare_device(libusb_device_handle *aHandle)
{
    debug("prepare device");

    libusb_device *device = libusb_get_device(aHandle);
    int r;
    int kernel_driver_detached = 0;

    // Detach OS driver (not possible for OS X, FreeBSD, and WIN32)
#if !defined(__APPLE__) && !defined(_WIN32) && !defined(__FreeBSD__)
    r = libusb_kernel_driver_active(aHandle, 0);
    if (r < 0) {
        warn("libusb_kernel_driver_active error %d", r);
        libusb_close(aHandle);
        return r;
    }

    if (r == 1) {
        r = libusb_detach_kernel_driver(aHandle, 0);
        if (r < 0) {
            warn("libusb_detach_kernel_driver error %d", r);
            libusb_close(aHandle);
            return r;
        }
        kernel_driver_detached = 1;
    }
    debug("libusb_detach_kernel_driver");
#endif

    const int configuration = 1;
    debug("setting configuration %d...", configuration);
    r = libusb_set_configuration(aHandle, configuration);
    if (r < 0) {
        debug("Error libusb_set_configuration: %d", r);
        if (kernel_driver_detached) {
            libusb_attach_kernel_driver(aHandle, 0);
        }
        libusb_close(aHandle);
        return r;
    }

    // reserve access to device
    debug("claiming interface 0...");
    r = libusb_claim_interface(aHandle, 0);
    if (r < 0) {
        warn("Error %d claiming interface 0", r);
        if (kernel_driver_detached) {
            libusb_attach_kernel_driver(aHandle, 0);
        }
        libusb_close(aHandle);
        return r;
    }
    return 0;
}

static libusb_device_handle *try_open_device(uint16_t vid, uint16_t pid)
{
    libusb_device_handle *dev_handle = libusb_open_device_with_vid_pid(NULL, vid, pid);
    if (!dev_handle) {
        warn("libusb_open failed!");
        dev_handle = NULL;
        return NULL;
    }

    debug("libusb open handle %p", dev_handle);

    // reset device (Not currently possible under FreeBSD 11.x/12.x due to usb framework)
    int rc = libusb_reset_device(dev_handle);
    if (rc < 0) {
        warn("libusb_reset_device failed!");
        libusb_close(dev_handle);
        return NULL;
    }
    return dev_handle;
}

#define NUM_POLLFD_ENTRIES 32
#define FIRST_USB_POLLFD_ENTRY 1

static struct pollfd fdset[NUM_POLLFD_ENTRIES];
static int num_pollfds = 0;

static void pollfd_added(int fd, short events, void *user_data)
{
    debug("pollfd_added %d %d", fd, events);
    if (num_pollfds == NUM_POLLFD_ENTRIES)
        fatal("raise the number of pollfds");

    fdset[num_pollfds].fd = fd;
    fdset[num_pollfds].events = events;
    fdset[num_pollfds].revents = 0;

    num_pollfds++;
}

static void pollfd_removed(int fd, void *user_data)
{
    debug("pollfd_removed %d", fd);

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

static void usb_init()
{
    memset(fdset, -1, sizeof(fdset));
    fdset[0].fd = STDIN_FILENO;
    fdset[0].events = POLLIN;
    fdset[0].revents = 0;
    num_pollfds = 1;

    int rc = libusb_init(NULL);
    if (rc < 0)
        fatal("libusb_init failed %d", rc);

    libusb_set_option(NULL, LIBUSB_OPTION_LOG_LEVEL, LIBUSB_LOG_LEVEL_WARNING);

    libusb_set_pollfd_notifiers(NULL, pollfd_added, pollfd_removed, NULL);

    const struct libusb_pollfd **initial_pollfds = libusb_get_pollfds(NULL);
    for (int i = 0; initial_pollfds[i] != NULL; i++)
        pollfd_added(initial_pollfds[i]->fd, initial_pollfds[i]->events, NULL);
    libusb_free_pollfds(initial_pollfds);

    if (libusb_pollfds_handle_timeouts(NULL) == 0)
        fatal("Platform missing timerfd support. Need to implement timer handling...");
}

static int usb_open(uint16_t vid, uint16_t pid)
{
    handle_packet = NULL;

    // default endpoint addresses
    event_in_addr = 0x81; // EP1, IN interrupt
    acl_in_addr =   0x82; // EP2, IN bulk
    acl_out_addr =  0x02; // EP2, OUT bulk

    libusb_state = LIB_USB_OPENED;


    libusb_device *dev = NULL;

    // Scan system for an appropriate devices
    debug("Scanning for USB Bluetooth device");
    libusb_device **devices;
    ssize_t num_devices = libusb_get_device_list(NULL, &devices);
    if (num_devices < 0) {
        usb_close();
        return -1;
    }

    handle = try_open_device(vid, pid);
    if (!handle) {
        debug("Failed to open device at 0x%04x:0x%04x", vid, pid);
        return -1;
    }

    int rc = prepare_device(handle);

    // allocate transfer handlers
    int c;
    for (c = 0 ; c < EVENT_IN_BUFFER_COUNT ; c++) {
        event_in_transfer[c] = libusb_alloc_transfer(0); // 0 isochronous transfers Events
        if (!event_in_transfer[c]) {
            usb_close();
            return LIBUSB_ERROR_NO_MEM;
        }
    }

    for (c = 0 ; c < ACL_IN_BUFFER_COUNT ; c++) {
        acl_in_transfer[c]  =  libusb_alloc_transfer(0); // 0 isochronous transfers ACL in
        if (!acl_in_transfer[c]) {
            usb_close();
            return LIBUSB_ERROR_NO_MEM;
        }
    }

    command_out_transfer = libusb_alloc_transfer(0);
    acl_out_transfer = libusb_alloc_transfer(0);

    libusb_state = LIB_USB_TRANSFERS_ALLOCATED;

    for (c = 0 ; c < EVENT_IN_BUFFER_COUNT ; c++) {
        // configure event_in handlers
        libusb_fill_interrupt_transfer(event_in_transfer[c], handle, event_in_addr,
                                       hci_event_in_buffer[c], HCI_ACL_BUFFER_SIZE, async_callback, NULL, 0) ;
        rc = libusb_submit_transfer(event_in_transfer[c]);
        debug("interrupt xfer usb_open ");
        if (rc) {
            warn("Error submitting interrupt transfer %d", rc);
            usb_close();
            return rc;
        }
    }

    for (c = 0 ; c < ACL_IN_BUFFER_COUNT ; c++) {
        // configure acl_in handlers
        libusb_fill_bulk_transfer(acl_in_transfer[c], handle, acl_in_addr,
                                  hci_acl_in_buffer[c] + HCI_INCOMING_PRE_BUFFER_SIZE, HCI_ACL_BUFFER_SIZE, async_callback, NULL, 0) ;
        rc = libusb_submit_transfer(acl_in_transfer[c]);
        if (rc) {
            warn("Error submitting bulk in transfer %d", rc);
            usb_close();
            return rc;
        }
    }
    return 0;
}

static int usb_close(void)
{
    int c;
    int completed = 0;

    debug("usb_close");

    switch (libusb_state) {
    case LIB_USB_CLOSED:
        break;

    case LIB_USB_TRANSFERS_ALLOCATED:
        libusb_state = LIB_USB_INTERFACE_CLAIMED;

    case LIB_USB_INTERFACE_CLAIMED:
        // Cancel all transfers, ignore warnings for this
        libusb_set_option(NULL, LIBUSB_OPTION_LOG_LEVEL, LIBUSB_LOG_LEVEL_ERROR);
        for (c = 0 ; c < EVENT_IN_BUFFER_COUNT ; c++) {
            if (event_in_transfer[c]) {
                debug("cancel event_in_transfer[%u] = %p", c, event_in_transfer[c]);
                libusb_cancel_transfer(event_in_transfer[c]);
            }
        }
        libusb_set_option(NULL, LIBUSB_OPTION_LOG_LEVEL, LIBUSB_LOG_LEVEL_WARNING);

        // wait until all transfers are completed - or 20 iterations
        int countdown = 20;
        while (!completed) {

            if (--countdown == 0) {
                warn("Not all transfers cancelled, leaking a bit.");
                break;
            }

            struct timeval tv;
            memset(&tv, 0, sizeof(struct timeval));
            libusb_handle_events_timeout(NULL, &tv);
            // check if all done
            completed = 1;
            for (c = 0; c < EVENT_IN_BUFFER_COUNT; c++) {
                if (event_in_transfer[c]) {
                    warn("event_in_transfer[%u] still active (%p)", c, event_in_transfer[c]);
                    completed = 0;
                    break;
                }
            }

            if (!completed) continue;
        }

        // finally release interface
        libusb_release_interface(handle, 0);
        debug("Libusb shutdown complete");

    case LIB_USB_DEVICE_OPENED:
        libusb_close(handle);

    case LIB_USB_OPENED:
        libusb_exit(NULL);
    }

    libusb_state = LIB_USB_CLOSED;
    handle = NULL;
    return 0;
}

static int usb_send_cmd_packet(const uint8_t *packet, size_t size)
{
    if (libusb_state != LIB_USB_TRANSFERS_ALLOCATED)
        return -1;

//FIXME - ALLOCATE TRANSFER AND MALLOC BUFFER AND SEND AND MARK THAT LIBUSB SHOULD FREE EVERYTHING!
//ALSO KEEP TRACK OF TRANSFERS ON THE WIRE!!!

    // async
    libusb_fill_control_setup(hci_cmd_buffer, LIBUSB_REQUEST_TYPE_CLASS | LIBUSB_RECIPIENT_INTERFACE, 0,
                              0, 0, size);
    memcpy(hci_cmd_buffer + LIBUSB_CONTROL_SETUP_SIZE, packet, size);

    // prepare transfer
    libusb_fill_control_transfer(command_out_transfer, handle, hci_cmd_buffer, async_callback, NULL, 0);
    command_out_transfer->flags = LIBUSB_TRANSFER_FREE_BUFFER;

    // submit transfer
    int rc = libusb_submit_transfer(command_out_transfer);
    if (rc < 0) {
        warn("Error submitting cmd transfer %d", rc);
        return -1;
    }

    return 0;
}

static int usb_send_acl_packet(const uint8_t *packet, size_t size)
{
    if (libusb_state != LIB_USB_TRANSFERS_ALLOCATED)
        return -1;

    debug("usb_send_acl_packet enter, size %lu", size);

    if (size > HCI_ACL_BUFFER_SIZE) {
        warn("ACL packet too large (%d > %d)", size, HCI_ACL_BUFFER_SIZE);
        return -1;
    }

//FIXME - ALLOCATE TRANSFER AND MALLOC BUFFER AND THEN FREE!!!

    // prepare transfer
    memcpy(hci_acl_out_buffer, packet, size);
    libusb_fill_bulk_transfer(acl_out_transfer, handle, acl_out_addr, hci_acl_out_buffer, size,
                              async_callback, NULL, 0);
    acl_out_transfer->type = LIBUSB_TRANSFER_TYPE_BULK;

    int rc = libusb_submit_transfer(acl_out_transfer);
    if (rc < 0) {
        warn("Error submitting acl transfer, %d", rc);
        return -1;
    }
    debug("sent ACL packet");

    return 0;
}

static void hci_handle_request(const uint8_t *buffer, size_t length, void *cookie)
{
    debug("hci_handle_request: len=%lu, event=%u", length, buffer[2]);
    switch (buffer[2]) {
    case HCI_COMMAND_PACKET:
        usb_send_cmd_packet(&buffer[3], length - 1);
        break;
    case HCI_ACL_DATA_PACKET:
        usb_send_acl_packet(&buffer[3], length - 1);
        break;
    default:
        fatal("hci_handle_request: unexpected packet type %u", buffer[2]);
    }
}

int main(int argc, char const *argv[])
{
    static struct erlcmd handler;
    erlcmd_init(&handler, hci_handle_request, NULL);

    if (argc != 4 && strcmp(argv[1], "open") == 0)
        fatal("Expecting 'open <vid> <pid>'");

    uint16_t vid = (uint16_t) strtoul(argv[2], 0, 0);
    uint16_t pid = (uint16_t) strtoul(argv[3], 0, 0);

    usb_init();

    if (usb_open(vid, pid))
        fatal("error opening USB device 0x%04x:0x%04x", vid, pid);

    for (;;) {
        for (int i = 0; i < num_pollfds; i++)
            fdset[i].revents = 0;

        // Skipping libusb_get_next_timeout(). See check in usb_init().
        int rc = poll(fdset, num_pollfds, -1);
        if (rc < 0) {
            // Retry if EINTR
            if (errno == EINTR)
                continue;

            fatal("poll failed with %d", errno);
        }

        if (fdset[0].revents & (POLLIN | POLLHUP))
            erlcmd_process(&handler);

        usb_process();
    }
    return 0;
}
