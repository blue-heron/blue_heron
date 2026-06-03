# SPDX-FileCopyrightText: 2024 Connor Rigby
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule BlueHeron.HCI.Transport.UART.FirmwareLoader do
  @moduledoc """
  Parses Broadcom `.hcd` firmware files and maps chip identifiers to firmware filenames.

  An `.hcd` file is a sequence of concatenated HCI commands (without the 0x01
  packet type indicator). Each record has the format:

      <<opcode::binary-2, parameter_length::8, parameters::binary-size(parameter_length)>>
  """

  # LMP subversion to firmware filename mapping.
  # Sourced from the Linux kernel's btbcm.c (bcm_uart_subver_table).
  @firmware_table %{
    0x4103 => "BCM4330B1.hcd",
    0x410D => "BCM4334B0.hcd",
    0x410E => "BCM43341B0.hcd",
    0x4204 => "BCM2035.hcd",
    0x4406 => "BCM4345C0.hcd",
    0x4606 => "BCM4345C5.hcd",
    0x6106 => "BCM43430A1.hcd",
    0x6107 => "BCM43430B0.hcd",
    0x6109 => "BCM4345C0.hcd",
    0x620E => "BCM4356A2.hcd",
    0x6611 => "BCM4354A2.hcd"
  }

  @doc """
  Parse an `.hcd` firmware file into a list of raw HCI command binaries.

  Each returned binary includes the opcode and parameters, ready to be sent
  via the UART transport with the 0x01 command packet type prepended.
  """
  @spec parse_hcd(binary()) :: [binary()]
  def parse_hcd(<<>>), do: []

  def parse_hcd(<<opcode::binary-2, len::8, params::binary-size(len), rest::binary>>) do
    [<<opcode::binary, len, params::binary>> | parse_hcd(rest)]
  end

  @doc """
  Determine the firmware filename for a Broadcom chip based on its LMP subversion.

  Returns `nil` if the chip is not recognized.
  """
  @spec firmware_name(non_neg_integer()) :: String.t() | nil
  def firmware_name(lmp_subversion) do
    Map.get(@firmware_table, lmp_subversion)
  end
end
