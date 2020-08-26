/*
 * Much of this code was found in the great BluetoothStack project:
 * https://github.com/bluekitchen/btstack/blob/master/platform/libusb/hci_transport_h2_libusb.c
 */

#include <libusb-1.0/libusb.h>
#include <err.h>
#include <errno.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <stdbool.h>
#include <poll.h>

#define ACL_IN_BUFFER_COUNT    3
#define EVENT_IN_BUFFER_COUNT  3
#define HCI_ACL_BUFFER_SIZE 255
#define HCI_INCOMING_PRE_BUFFER_SIZE 2

#define ASYNC_POLLING_INTERVAL_MS 1

#define COMMS_IN_FD 3
#define COMMS_OUT_FD 4

#define DEBUG

#ifdef DEBUG
#define log_location stderr
//#define LOG_PATH "/tmp/circuits_gpio.log"
#define debug(...) do { fprintf(log_location, __VA_ARGS__); fprintf(log_location, "\r\n"); fflush(log_location); } while(0)
#define error(...) do { debug(__VA_ARGS__); } while (0)
#define start_timing() ErlNifTime __start = enif_monotonic_time(ERL_NIF_USEC)
#define elapsed_microseconds() (enif_monotonic_time(ERL_NIF_USEC) - __start)
#else
#define debug(...)
#define error(...) do { fprintf(stderr, __VA_ARGS__); fprintf(stderr, "\n"); } while(0)
#define start_timing()
#define elapsed_microseconds() 0
#endif

typedef enum {
    LIB_USB_CLOSED = 0,
    LIB_USB_OPENED,
    LIB_USB_DEVICE_OPENDED,
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

// incoming buffer for HCI Events and ACL Packets
static uint8_t
hci_event_in_buffer[EVENT_IN_BUFFER_COUNT][HCI_ACL_BUFFER_SIZE]; // bigger than largest packet
static uint8_t hci_acl_in_buffer[ACL_IN_BUFFER_COUNT][HCI_INCOMING_PRE_BUFFER_SIZE +
                                                      HCI_ACL_BUFFER_SIZE];

// For (ab)use as a linked list of received packets
static struct libusb_transfer *handle_packet;

// endpoint addresses
static int event_in_addr;
static int acl_in_addr;
static int acl_out_addr;

static int usb_command_active = 0;
static int usb_acl_out_active = 0;

static void queue_transfer(struct libusb_transfer *transfer);
static int usb_close(void);

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
        debug("-> Transfer stalled, trying again");
        r = libusb_clear_halt(handle, transfer->endpoint);
        if (r) {
            debug("Error clearing halt %d", r);
        }
        r = libusb_submit_transfer(transfer);
        if (r) {
            debug("Error re-submitting transfer %d", r);
        }
    } else {
        debug("async_callback. not data -> resubmit transfer, endpoint %x, status %x, length %u",
              transfer->endpoint, transfer->status, transfer->actual_length);
        // No usable data, just resubmit packet
        r = libusb_submit_transfer(transfer);
        if (r) {
            debug("Error re-submitting transfer %d", r);
        }
    }
    // debug("end async_callback");
}

static void handle_completed_transfer(struct libusb_transfer *transfer)
{

    int resubmit = 0;
    int signal_done = 0;
    unsigned char outbuf[transfer->actual_length + 1];

    // debug("handle_completed_transfer endpoint %x %x, %x", transfer->endpoint, acl_in_addr, transfer->endpoint == acl_in_addr);

    if (transfer->endpoint == event_in_addr) {
        outbuf[0] = (unsigned char)0x4; // same as UART
        memcpy(&outbuf[1], transfer->buffer, transfer->actual_length);
        write(COMMS_OUT_FD, outbuf, transfer->actual_length + 1);
        resubmit = 1;
    } else if (transfer->endpoint == acl_in_addr) {
        debug("-> acl");
        outbuf[0] = (unsigned char)0x02; // same as UART
        memcpy(&outbuf[1], transfer->buffer, transfer->actual_length);
        write(COMMS_OUT_FD, outbuf, transfer->actual_length + 1);
        resubmit = 1;
    } else if (transfer->endpoint == 0) {
        // debug("command done, size %u", transfer->actual_length);
        usb_command_active = 0;
        signal_done = 1;
    } else if (transfer->endpoint == acl_out_addr) {
        // debug("acl out done, size %u", transfer->actual_length);
        usb_acl_out_active = 0;
        signal_done = 1;
    } else {
        debug("usb_process_ds endpoint unknown %x", transfer->endpoint);
    }

    // if (signal_done){}

    if (libusb_state != LIB_USB_TRANSFERS_ALLOCATED) return;

    if (resubmit) {
        // Re-submit transfer
        transfer->user_data = NULL;
        int r = libusb_submit_transfer(transfer);
        if (r) {
            debug("Error re-submitting transfer %d", r);
        }
    }
}

static void usb_process()
{

    if (libusb_state != LIB_USB_TRANSFERS_ALLOCATED) return;

    // debug("begin usb_process");
    // always handling an event as we're called when data is ready
    struct timeval tv;
    memset(&tv, 0, sizeof(struct timeval));
    libusb_handle_events_timeout(NULL, &tv);

    // Handle any packet in the order that they were received
    while (handle_packet) {
        // debug("handle packet %p, endpoint %x, status %x", handle_packet, handle_packet->endpoint, handle_packet->status);

        // pop next transfer
        struct libusb_transfer *transfer = handle_packet;
        handle_packet = (struct libusb_transfer *) handle_packet->user_data;

        // handle transfer
        handle_completed_transfer(transfer);

        // handle case where libusb_close might be called by hci packet handler
        if (libusb_state != LIB_USB_TRANSFERS_ALLOCATED) return;
    }
    // debug("end usb_process");
}

static int prepare_device(libusb_device_handle *aHandle)
{
    debug("prepare device\r\n");

    libusb_device *device = libusb_get_device(aHandle);
    int r;
    int kernel_driver_detached = 0;

    // Detach OS driver (not possible for OS X, FreeBSD, and WIN32)
#if !defined(__APPLE__) && !defined(_WIN32) && !defined(__FreeBSD__)
    r = libusb_kernel_driver_active(aHandle, 0);
    if (r < 0) {
        debug("libusb_kernel_driver_active error %d", r);
        libusb_close(aHandle);
        return r;
    }

    if (r == 1) {
        r = libusb_detach_kernel_driver(aHandle, 0);
        if (r < 0) {
            debug("libusb_detach_kernel_driver error %d", r);
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
        debug("Error %d claiming interface 0", r);
        if (kernel_driver_detached) {
            libusb_attach_kernel_driver(aHandle, 0);
        }
        libusb_close(aHandle);
        return r;
    }
    return 0;
}

static libusb_device_handle *try_open_device()
{
    int r;

    libusb_device_handle *dev_handle;
    dev_handle = libusb_open_device_with_vid_pid(NULL, 0x0bda, 0xb82c);

    if (!dev_handle) {
        debug("libusb_open failed!");
        dev_handle = NULL;
        return NULL;
    }

    debug("libusb open %d, handle %p", r, dev_handle);

    // reset device (Not currently possible under FreeBSD 11.x/12.x due to usb framework)
    r = libusb_reset_device(dev_handle);
    if (r < 0) {
        debug("libusb_reset_device failed!");
        libusb_close(dev_handle);
        return NULL;
    }
    return dev_handle;
}

static int usb_open(void)
{
    int r;

    handle_packet = NULL;

    // default endpoint addresses
    event_in_addr = 0x81; // EP1, IN interrupt
    acl_in_addr =   0x82; // EP2, IN bulk
    acl_out_addr =  0x02; // EP2, OUT bulk

    // USB init
    r = libusb_init(NULL);
    if (r < 0) return -1;

    libusb_state = LIB_USB_OPENED;

    // configure debug level
    libusb_set_option(NULL, LIBUSB_OPTION_LOG_LEVEL, LIBUSB_LOG_LEVEL_WARNING);

    libusb_device *dev = NULL;

    // Scan system for an appropriate devices
    libusb_device **devices;
    ssize_t num_devices;

    debug("Scanning for USB Bluetooth device");
    num_devices = libusb_get_device_list(NULL, &devices);
    if (num_devices < 0) {
        usb_close();
        return -1;
    }

    handle = try_open_device();
    if (!handle) {
        debug("Failed to open device\r\n");
        return -1;
    }

    r = prepare_device(handle);

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
        r = libusb_submit_transfer(event_in_transfer[c]);
        debug("interrupt xfer usb_open \r\n");
        if (r) {
            debug("Error submitting interrupt transfer %d", r);
            usb_close();
            return r;
        }
    }

    for (c = 0 ; c < ACL_IN_BUFFER_COUNT ; c++) {
        // configure acl_in handlers
        libusb_fill_bulk_transfer(acl_in_transfer[c], handle, acl_in_addr,
                                  hci_acl_in_buffer[c] + HCI_INCOMING_PRE_BUFFER_SIZE, HCI_ACL_BUFFER_SIZE, async_callback, NULL, 0) ;
        r = libusb_submit_transfer(acl_in_transfer[c]);
        if (r) {
            debug("Error submitting bulk in transfer %d", r);
            usb_close();
            return r;
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
                debug("Not all transfers cancelled, leaking a bit.");
                break;
            }

            struct timeval tv;
            memset(&tv, 0, sizeof(struct timeval));
            libusb_handle_events_timeout(NULL, &tv);
            // check if all done
            completed = 1;
            for (c = 0; c < EVENT_IN_BUFFER_COUNT; c++) {
                if (event_in_transfer[c]) {
                    debug("event_in_transfer[%u] still active (%p)", c, event_in_transfer[c]);
                    completed = 0;
                    break;
                }
            }

            if (!completed) continue;
        }

        // finally release interface
        libusb_release_interface(handle, 0);
        debug("Libusb shutdown complete");

    case LIB_USB_DEVICE_OPENDED:
        libusb_close(handle);

    case LIB_USB_OPENED:
        libusb_exit(NULL);
    }

    libusb_state = LIB_USB_CLOSED;
    handle = NULL;
    return 0;
}

static int usb_send_cmd_packet(uint8_t *packet, int size)
{
    int r;

    if (libusb_state != LIB_USB_TRANSFERS_ALLOCATED) return -1;

    // async
    libusb_fill_control_setup(hci_cmd_buffer, LIBUSB_REQUEST_TYPE_CLASS | LIBUSB_RECIPIENT_INTERFACE, 0,
                              0, 0, size);
    memcpy(hci_cmd_buffer + LIBUSB_CONTROL_SETUP_SIZE, packet, size);

    // prepare transfer
    int completed = 0;
    libusb_fill_control_transfer(command_out_transfer, handle, hci_cmd_buffer, async_callback,
                                 &completed, 0);
    command_out_transfer->flags = LIBUSB_TRANSFER_FREE_BUFFER;

    // update state before submitting transfer
    usb_command_active = 1;

    // submit transfer
    r = libusb_submit_transfer(command_out_transfer);

    if (r < 0) {
        usb_command_active = 0;
        debug("Error submitting cmd transfer %d", r);
        return -1;
    }

    return 0;
}

static int usb_send_acl_packet(uint8_t *packet, int size)
{
    int r;

    if (libusb_state != LIB_USB_TRANSFERS_ALLOCATED) return -1;

    debug("usb_send_acl_packet enter, size %u", size);

    // prepare transfer
    int completed = 0;
    libusb_fill_bulk_transfer(acl_out_transfer, handle, acl_out_addr, packet, size,
                              async_callback, &completed, 0);
    acl_out_transfer->type = LIBUSB_TRANSFER_TYPE_BULK;

    debug("fill complete");

    // update state before submitting transfer
    usb_acl_out_active = 1;

    r = libusb_submit_transfer(acl_out_transfer);
    debug("submit complete");
    if (r < 0) {
        usb_acl_out_active = 0;
        debug("Error submitting acl transfer, %d", r);
        return -1;
    }
    debug("sent ACL packet");

    return 0;
}

static int elixir_process()
{
    int amount = HCI_ACL_BUFFER_SIZE;
    uint8_t *buffer = malloc(amount);
    memset(buffer, 0, amount);
    ssize_t amount_read = read(COMMS_IN_FD, buffer, amount);
    if (amount_read < 0) {
        /* EINTR is ok to get, since we were interrupted by a signal. */
        if (errno == EINTR)
            return -1;

        /* Everything else is unexpected. */
        err(EXIT_FAILURE, "read");
    } else if (amount_read == 0) {
        /* EOF. Erlang process was terminated. This happens after a release or if there was an error. */
        exit(EXIT_SUCCESS);
    }
    debug("elixir_process event=%u", buffer[0]);
    switch (buffer[0]) {
    case 0x0:
        return usb_send_cmd_packet(&buffer[1], amount_read - 1);
    case 0x2:
        return usb_send_acl_packet(&buffer[1], amount_read - 1);
    default:
        error("Unknown message from elixir %u", buffer[0]);
        err(EXIT_FAILURE, "unknown_packet_type");
    }
}

int main(int argc, char const *argv[])
{
    if (usb_open()) {
        debug("error opening usb port");
        return -1;
    }

    for (;;) {
        int rc;

        const struct libusb_pollfd **libusb_pollfd = libusb_get_pollfds(NULL);
        int num_pollfds;
        for (num_pollfds = 1 ; libusb_pollfd[num_pollfds] ; num_pollfds++);

        struct pollfd fdset[num_pollfds];
        fdset[0].fd = COMMS_IN_FD;
        fdset[0].events = POLLIN;
        fdset[0].revents = 0;
        for (int r = 1 ; r < num_pollfds ; r++) {
            fdset[r].fd = libusb_pollfd[r]->fd;
            fdset[r].events = libusb_pollfd[r]->events;
        }

        rc = poll(fdset, num_pollfds, -1);
        if (rc < 0) {
            // Retry if EINTR
            if (errno == EINTR)
                continue;

            err(EXIT_FAILURE, "poll");
        }

        // data from Elixir
        if (fdset[0].revents & (POLLIN | POLLHUP)) {
            debug("handling data from elixir");
            rc = elixir_process();
            if (rc) {
                debug("Error sending packet %x\r\n", rc);
            }
        }

        int usb_activity = 0;
        for (int r = 1 ; r < num_pollfds ; r++) {
            if (fdset[r].revents)
                usb_activity = 1;
        }
        if (usb_activity) {
            //   debug("usb poll complete");
            usb_process();
        }

        libusb_free_pollfds(libusb_pollfd);
    }
    return 0;
}
