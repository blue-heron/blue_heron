# SPDX-FileCopyrightText: 2019 Very
#
# SPDX-License-Identifier: MIT
#
defmodule BlueHeron.AssignedNumbers.GenericAccessProfile do
  @moduledoc """
  > Assigned numbers are used in GAP for inquiry response, EIR data type values,
  > manufacturer-specific data, advertising data, low energy UUIDs and appearance characteristics,
  > and class of device.

  Reference: https://www.bluetooth.com/specifications/assigned-numbers/generic-access-profile
  """

  @definitions %{
    0x01 => "Flags",
    0x02 => "Incomplete List of 16-bit Service Class UUIDs",
    0x03 => "Complete List of 16-bit Service Class UUIDs",
    0x04 => "Incomplete List of 32-bit Service Class UUIDs",
    0x05 => "Complete List of 32-bit Service Class UUIDs",
    0x06 => "Incomplete List of 128-bit Service Class UUIDs",
    0x07 => "Complete List of 128-bit Service Class UUIDs",
    0x08 => "Shortened Local Name",
    0x09 => "Complete Local Name",
    0x0A => "Tx Power Level",
    0x0D => "Class of Device",
    0x0E => "Simple Pairing Hash C-192",
    0x0F => "Simple Pairing Randomizer R-192",
    0x10 => "Device ID",
    0x11 => "Security Manager Out of Band Flags",
    0x12 => "Slave Connection Interval Range",
    0x14 => "List of 16-bit Service Solicitation UUIDs",
    0x15 => "List of 128-bit Service Solicitation UUIDs",
    0x16 => "Service Data - 16-bit UUID",
    0x17 => "Public Target Address",
    0x18 => "Random Target Address",
    0x19 => "Appearance",
    0x1A => "Advertising Interval",
    0x1B => "LE Bluetooth Device Address",
    0x1C => "LE Role",
    0x1D => "Simple Pairing Hash C-256",
    0x1E => "Simple Pairing Randomizer R-256",
    0x1F => "List of 32-bit Service Solicitation UUIDs",
    0x20 => "Service Data - 32-bit UUID",
    0x21 => "Service Data - 128-bit UUID",
    0x22 => "LE Secure Connections Confirmation Value",
    0x23 => "LE Secure Connections Random Value",
    0x24 => "URI",
    0x25 => "Indoor Positioning",
    0x26 => "Transport Discovery Data",
    0x27 => "LE Supported Features",
    0x28 => "Channel Map Update Indication",
    0x29 => "PB-ADV",
    0x2A => "Mesh Message",
    0x2B => "Mesh Beacon",
    0x3D => "3D Information Data",
    0xFF => "Manufacturer Specific Data"
  }

  @doc """
  Returns the description associated with `id`.
  """
  defmacro description(id)

  @doc """
  Returns the ID associated with `description`.
  """
  defmacro id(description)

  # handle a redundant GAP definition
  defmacro id("Simple Pairing Hash C"), do: 0x0E

  Enum.each(@definitions, fn
    {id, description} ->
      defmacro description(unquote(id)), do: unquote(description)

      defmacro id(unquote(description)), do: unquote(id)
  end)

  @doc """
  Returns a list of all Generic Access Profile Data Type Values.
  """
  defmacro ids, do: unquote(for {id, _} <- @definitions, do: id)
end
