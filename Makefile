# This Makefile isn't necessary for general usage of BlueHeron. It's intended
# to simplify building and maintaining all projects at once. If this isn't what
# you want, it's probably better to go directly to the project of interest and
# work out of that directory.

EXAMPLES=examples/govee_bulb
LIBRARIES=blue_heron blue_heron_transport_uart blue_heron_transport_usb
EVERYTHING=$(LIBRARIES) $(EXAMPLES)

# Needed for foreach calls
define sep


endef

define foreach_project
	$(foreach project,$(1),cd $(project);$(2)$(sep))
endef

all: deps test docs check_formatted

deps:
	$(call foreach_project,$(EVERYTHING),mix deps.get)

test:
	$(call foreach_project,$(LIBRARIES),mix test)

docs:
	$(call foreach_project,$(LIBRARIES),mix docs)

check_formatted:
	$(call foreach_project,$(EVERYTHING),mix format --check-formatted)

dialyzer:
	$(call foreach_project,$(LIBRARIES),mix dialyzer)

credo:
	$(call foreach_project,$(LIBRARIES),mix credo -a)

.PHONY: all deps test docs check_formatted dialyzer credo

