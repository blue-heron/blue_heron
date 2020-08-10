# Makefile for building the PORT
#
# Makefile targets:
#
# all/install   build and install the PORT
# clean         clean build products and intermediates
#
# Variables to override:
#
# MIX_APP_PATH  path to the build directory
#
# CC            C compiler
# CROSSCOMPILE	crosscompiler prefix, if any
# CFLAGS	compiler flags for compiling all C files
# ERL_CFLAGS	additional compiler flags for files using Erlang header files
# ERL_EI_INCLUDE_DIR include path to ei.h (Required for crosscompile)
# ERL_EI_LIBDIR path to libei.a (Required for crosscompile)
# LDFLAGS	linker flags for linking all binaries
# ERL_LDFLAGS	additional linker flags for projects referencing Erlang libraries

PREFIX = $(MIX_APP_PATH)/priv
BUILD  = $(MIX_APP_PATH)/obj

PORT = $(PREFIX)/hci_transport

CFLAGS ?= -O2 -Wno-unused-parameter -pedantic -Wall
CFLAGS += $(TARGET_CFLAGS) -Wall -pedantic

LDFLAGS += $(shell pkg-config libusb-1.0 --libs)
CFLAGS +=  $(shell pkg-config libusb-1.0 --cflags)

# # Set Erlang-specific compile and linker flags
# ERL_CFLAGS ?= -I$(ERL_EI_INCLUDE_DIR)
# ERL_LDFLAGS ?= -L$(ERL_EI_LIBDIR) -lei

SRC = src/hci_transport.c src/erlcmd.c src/btusb.c src/btusb_scan.c
HEADERS =$(wildcard src/*.h)
OBJ = $(SRC:src/%.c=$(BUILD)/%.o)

calling_from_make:
	mix compile

all: install

install: $(PREFIX) $(BUILD) $(PORT)

$(OBJ): $(HEADERS) Makefile

$(BUILD)/%.o: src/%.c
	$(CC) -c $(CFLAGS) -o $@ $<

$(PORT): $(OBJ)
	$(CC) -o $@ $^ $(LDFLAGS)

$(PREFIX) $(BUILD):
	mkdir -p $@

format:
	astyle --style=kr --indent=spaces=4 --align-pointer=name \
	    --align-reference=name --convert-tabs --attach-namespaces \
	    --max-code-length=100 --max-instatement-indent=120 --pad-header \
	    --pad-oper \
	    src/hci_transport.c

clean:
	$(RM) $(PORT) $(OBJ)

.PHONY: all clean calling_from_make install format
