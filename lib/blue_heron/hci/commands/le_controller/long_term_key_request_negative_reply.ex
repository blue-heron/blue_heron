# SPDX-FileCopyrightText: 2023 Markus Hutzler
# SPDX-FileCopyrightText: 2024 Connor Rigby
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule BlueHeron.HCI.Command.LEController.LongTermKeyRequestNegativeReply do
  use BlueHeron.HCI.Command.LEController, ocf: 0x001B

  @moduledoc """
  > The HCI_LE_Long_Term_Key_Request_Negative_Reply command is used to reply to
  > an HCI_LE_Long_Term_Key_Request event from the Controller if the Host cannot
  > provide a Long Term Key for this Connection_Handle.
  > This command shall only be used when the local device’s role is Peripheral.

  Bluetooth Core Version 5.2 | Vol 4, Part E, section 7.8.26

  * OGF: `#{inspect(@ogf, base: :hex)}`
  * OCF: `#{inspect(@ocf, base: :hex)}`
  * Opcode: `#{inspect(@opcode)}`
  """

  defparameters [
    :status,
    :connection_handle
  ]

  defimpl BlueHeron.HCI.Serializable do
    def serialize(%{opcode: opcode, connection_handle: handle}) do
      <<opcode::binary, 2, handle::little-16>>
    end
  end

  @impl BlueHeron.HCI.Command
  def deserialize(<<@opcode::binary, 2, lower_handle, _::4, upper_handle::4>>) do
    <<handle::little-12>> = <<lower_handle, upper_handle::4>>

    %__MODULE__{
      opcode: @opcode,
      connection_handle: handle
    }
  end

  @impl BlueHeron.HCI.Command
  def deserialize_return_parameters(<<status, lower_handle, _::4, upper_handle::4>>) do
    <<handle::little-12>> = <<lower_handle, upper_handle::4>>
    %{status: status, connection_handle: handle}
  end

  @impl BlueHeron.HCI.Command
  def serialize_return_parameters(%{status: status, connection_handle: handle}) do
    <<BlueHeron.ErrorCode.to_code!(status), handle::little-16>>
  end
end
