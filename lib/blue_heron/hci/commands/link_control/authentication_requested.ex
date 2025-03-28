# SPDX-FileCopyrightText: 2023 Markus Hutzler
# SPDX-FileCopyrightText: 2024 Connor Rigby
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule BlueHeron.HCI.Command.LinkControl.AuthenticationRequested do
  use BlueHeron.HCI.Command.LinkControl, ocf: 0x0011

  @moduledoc """
  > This command is used to try to authenticate the remote device associated with
  > the specified Connection_Handle.

  * OGF: `#{inspect(@ogf, base: :hex)}`
  * OCF: `#{inspect(@ocf, base: :hex)}`
  * Opcode: `#{inspect(@opcode)}`

  Bluetooth Spec v5.3, Vol 4, Part E, section 7.1.15
  """

  defparameters handle: 0

  defimpl BlueHeron.HCI.Serializable do
    def serialize(%{opcode: opcode, handle: handle}) do
      bin = <<handle::little-16>>
      size = byte_size(bin)
      <<opcode::binary, size, bin::binary>>
    end
  end

  @impl BlueHeron.HCI.Command
  def deserialize(<<@opcode::binary, 0>>) do
    %__MODULE__{}
  end

  @impl BlueHeron.HCI.Command
  def deserialize_return_parameters(<<>>) do
    %{}
  end

  @impl true
  def serialize_return_parameters(%{}) do
    <<>>
  end
end
