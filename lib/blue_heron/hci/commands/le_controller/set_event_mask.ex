# SPDX-FileCopyrightText: 2021 Troels Brødsgaard
# SPDX-FileCopyrightText: 2023 Connor Rigby
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule BlueHeron.HCI.Command.LEController.SetEventMask do
  use BlueHeron.HCI.Command.LEController, ocf: 0x08

  @moduledoc """
  > The HCI_LE_Set_Event_Mask command is used to control which LE events are
  > generated by the HCI for the Host. If the bit in the LE_Event_Mask is set to a one,
  > then the event associated with that bit will be enabled. The event mask allows the Host
  > to control which events will interrupt it.

  Bluetooth Core Version 5.2 | Vol 4, Part E, section 7.8.1

  * OGF: `#{inspect(@ogf, base: :hex)}`
  * OCF: `#{inspect(@ocf, base: :hex)}`
  * Opcode: `#{inspect(@opcode)}`
  """

  defparameters mask: 0x00

  defimpl BlueHeron.HCI.Serializable do
    def serialize(command) do
      <<command.opcode::binary, 8, command.mask::little-64>>
    end
  end

  @impl BlueHeron.HCI.Command
  def deserialize(<<@opcode::binary, _, mask::little-64>>) do
    new(mask: mask)
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
