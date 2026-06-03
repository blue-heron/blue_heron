# SPDX-FileCopyrightText: 2024 Connor Rigby
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule BlueHeron.HCI.Command.VendorSpecific.UpdateBaudrate do
  use BlueHeron.HCI.Command.VendorSpecific, ocf: 0x0018

  @moduledoc """
  Broadcom vendor-specific command to change the UART baud rate on the controller.

  * OGF: `#{inspect(@ogf, base: :hex)}`
  * OCF: `#{inspect(@ocf, base: :hex)}`
  * Opcode: `#{inspect(@opcode)}`

  After sending this command and receiving a successful response, the host
  must also reconfigure its own UART to the new baud rate.
  """

  defparameters baudrate: 115_200

  defimpl BlueHeron.HCI.Serializable do
    def serialize(%{opcode: opcode, baudrate: baudrate}) do
      <<opcode::binary, 6, 0x00, 0x00, baudrate::little-32>>
    end
  end

  @impl BlueHeron.HCI.Command
  def deserialize(<<@opcode::binary, 6, 0x00, 0x00, baudrate::little-32>>) do
    %__MODULE__{baudrate: baudrate}
  end

  @impl BlueHeron.HCI.Command
  def deserialize_return_parameters(<<status>>) do
    %{status: status}
  end

  @impl true
  def serialize_return_parameters(%{status: status}) do
    <<BlueHeron.ErrorCode.to_code!(status)>>
  end
end
