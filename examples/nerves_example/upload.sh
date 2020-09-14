#!/bin/sh

#
# Upload new firmware to a target running nerves_firmware_ssh
#
# Usage:
#   upload.sh [destination IP] [Path to .fw file]
#
# If unspecifed, the destination is nerves.local and the .fw file is naively
# guessed
#
# You may want to add the following to your `~/.ssh/config` to avoid recording
# the IP addresses of the target:
#
# Host nerves.local
#   UserKnownHostsFile /dev/null
#   StrictHostKeyChecking no
#
# The firmware update protocol is:
#
# 1. Connect to the nerves_firmware_ssh service running on port 8989
# 2. Send "fwup:$FILESIZE,reboot\n" where `$FILESIZE` is the size of the file
#    being uploaded
# 3. Send the firmware file
# 4. The response from the device is a progress bar from fwup that can either
#    be ignored or shown to the user.
# 5. The ssh connection is closed with an exit code to indicate success or
#    failure
#
# Feel free to copy this script wherever is convenient. The template is at
# https://github.com/nerves-project/nerves_firmware_ssh/blob/main/priv/templates/script.upload.eex
#

set -e

DESTINATION=$1
FILENAME="$2"

help() {
    echo
    echo "upload.sh [destination IP] [Path to .fw file]"
    echo
    echo "Default destination IP is 'nerves.local'"
    echo "Default firmware bundle is the first .fw file in '_build/\${MIX_TARGET}_\${MIX_ENV}/nerves/images'"
    echo
    echo "MIX_TARGET=$MIX_TARGET"
    echo "MIX_ENV=$MIX_ENV"
    exit 1
}

[ -n "$DESTINATION" ] || DESTINATION=nerves.local
[ -n "$MIX_TARGET" ] || MIX_TARGET=rpi0
[ -n "$MIX_ENV" ] || MIX_ENV=dev
if [ -z "$FILENAME" ]; then
    FIRMWARE_PATH="./_build/${MIX_TARGET}_${MIX_ENV}/nerves/images"
    if [ ! -d "$FIRMWARE_PATH" ]; then
        # Try the Nerves 1.4 path if the user hasn't upgraded their mix.exs
        FIRMWARE_PATH="./_build/${MIX_TARGET}/${MIX_TARGET}_${MIX_ENV}/nerves/images"
        if [ ! -d "$FIRMWARE_PATH" ]; then
            # Try the pre-Nerves 1.4 path
            FIRMWARE_PATH="./_build/${MIX_TARGET}/${MIX_ENV}/nerves/images"
            if [ ! -d "$FIRMWARE_PATH" ]; then
                echo "Can't find the build products."
                echo
                echo "Nerves environment"
                echo "MIX_TARGET:    ${MIX_TARGET}"
                echo "MIX_ENV:       ${MIX_ENV}"
                echo
                echo "Make sure your Nerves environment is correct."
                echo
                echo "If the Nerves environment is correct make sure you have built the firmware"
                echo "using 'mix firmware'."
                echo
                echo "If you are uploading a .fw file from a custom path you can specify the"
                echo "path like so:"
                echo
                echo "  $0 <device hostname or IP address> </path/to/my/firmware.fw>"
                echo
                exit 1
            fi
        fi
    fi

    FILENAME=$(ls "$FIRMWARE_PATH/"*.fw 2> /dev/null | head -n 1)
fi

[ -n "$FILENAME" ] || (echo "Error: error determining firmware bundle."; help)
[ -f "$FILENAME" ] || (echo "Error: can't find '$FILENAME'"; help)

# Check the flavor of stat for sending the filesize
if stat --version 2>/dev/null | grep GNU >/dev/null; then
    # The QNU way
    FILESIZE=$(stat -c%s "$FILENAME")
else
    # Else default to the BSD way
    FILESIZE=$(stat -f %z "$FILENAME")
fi

FIRMWARE_METADATA=$(fwup -m -i "$FILENAME" || echo "meta-product=Error reading metadata!")
FIRMWARE_PRODUCT=$(echo "$FIRMWARE_METADATA" | grep -E "^meta-product=" -m 1 2>/dev/null | cut -d '=' -f 2- | tr -d '"')
FIRMWARE_VERSION=$(echo "$FIRMWARE_METADATA" | grep -E "^meta-version=" -m 1 2>/dev/null | cut -d '=' -f 2- | tr -d '"')
FIRMWARE_PLATFORM=$(echo "$FIRMWARE_METADATA" | grep -E "^meta-platform=" -m 1 2>/dev/null | cut -d '=' -f 2- | tr -d '"')
FIRMWARE_UUID=$(echo "$FIRMWARE_METADATA" | grep -E "^meta-uuid=" -m 1 2>/dev/null | cut -d '=' -f 2- | tr -d '"')

echo "Path: $FILENAME"
echo "Product: $FIRMWARE_PRODUCT $FIRMWARE_VERSION"
echo "UUID: $FIRMWARE_UUID"
echo "Platform: $FIRMWARE_PLATFORM"
echo
echo "Uploading to $DESTINATION..."

# Don't fall back to asking for passwords, since that won't work
# and it's easy to misread the message thinking that it's asking
# for the private key password
SSH_OPTIONS="-o PreferredAuthentications=publickey"

if [ "$(uname -s)" = "Darwin" ]; then
    DESTINATION_IP=$(arp -n $DESTINATION | sed 's/.* (\([0-9.]*\).*/\1/' || exit 0)
    if [ -z "$DESTINATION_IP" ]; then
        echo "Can't resolve $DESTINATION"
        exit 1
    fi
    TEST_DESTINATION_IP=$(printf "$DESTINATION_IP" | head -n 1)
    if [ "$DESTINATION_IP" != "$TEST_DESTINATION_IP" ]; then
        echo "Multiple destination IP addresses for $DESTINATION found:"
        echo "$DESTINATION_IP"
        echo "Guessing the first one..."
        DESTINATION_IP=$TEST_DESTINATION_IP
    fi

    IS_DEST_LL=$(echo $DESTINATION_IP | grep '^169\.254\.' || exit 0)
    if [ -n "$IS_DEST_LL" ]; then
        LINK_LOCAL_IP=$(ifconfig | grep 169.254 | sed 's/.*inet \([0-9.]*\) .*/\1/')
        if [ -z "$LINK_LOCAL_IP" ]; then
            echo "Can't find an interface with a link local address?"
            exit 1
        fi
        TEST_LINK_LOCAL_IP=$(printf "$LINK_LOCAL_IP" | tail -n 1)
        if [ "$LINK_LOCAL_IP" != "$TEST_LINK_LOCAL_IP" ]; then
            echo "Multiple interfaces with link local addresses:"
            echo "$LINK_LOCAL_IP"
            echo "Guessing the last one, but YMMV..."
            LINK_LOCAL_IP=$TEST_LINK_LOCAL_IP
        fi

        # If a link local address, then force ssh to bind to the link local IP
        # when connecting. This fixes an issue where the ssh connection is bound
        # to another Ethernet interface. The TCP SYN packet that goes out has no
        # chance of working when this happens.
        SSH_OPTIONS="$SSH_OPTIONS -b $LINK_LOCAL_IP"
    fi
fi

printf "fwup:$FILESIZE,reboot\n" | cat - $FILENAME | ssh -s -p 8989 $SSH_OPTIONS $DESTINATION nerves_firmware_ssh
