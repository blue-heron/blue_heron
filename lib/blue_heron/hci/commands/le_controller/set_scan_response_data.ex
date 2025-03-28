# SPDX-FileCopyrightText: 2023 Connor Rigby
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule BlueHeron.HCI.Command.LEController.SetScanResponseData do
  use BlueHeron.HCI.Command.LEController, ocf: 0x0009

  @moduledoc """
  > This command is used to provide data used in Scanning Packets that have a data field.

  Bluetooth Core Version 5.2 | Vol 4, Part E, section 7.8.10

  * OGF: `#{inspect(@ogf, base: :hex)}`
  * OCF: `#{inspect(@ocf, base: :hex)}`
  * Opcode: `#{inspect(@opcode)}`
  """

  defparameters scan_response_data: <<>>

  defimpl BlueHeron.HCI.Serializable do
    def serialize(%{opcode: opcode, scan_response_data: scan_response_data})
        when byte_size(scan_response_data) <= 31 do
      length = byte_size(scan_response_data)
      padding_size = (31 - length) * 8

      <<opcode::binary, 32, length, scan_response_data::binary, 0::size(padding_size)>>
    end
  end

  @impl BlueHeron.HCI.Command
  def deserialize(
        <<@opcode::binary, 32, length, scan_response_data::binary-size(length), _rest::binary>>
      ) do
    new(scan_response_data: scan_response_data)
  end

  @impl BlueHeron.HCI.Command
  def deserialize_return_parameters(<<status>>) do
    %{status: status}
  end

  @impl BlueHeron.HCI.Command
  def serialize_return_parameters(%{status: status}) do
    <<BlueHeron.ErrorCode.to_code!(status)>>
  end
end
