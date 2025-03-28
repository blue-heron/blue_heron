# SPDX-FileCopyrightText: 2020 Connor Rigby
# SPDX-FileCopyrightText: 2020 Frank Hunleth
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule BlueHeron.HCI.Command.ControllerAndBaseband.ReadLocalName do
  use BlueHeron.HCI.Command.ControllerAndBaseband, ocf: 0x0014

  @moduledoc """
  > The HCI_Read_Local_Name command provides the ability to read the stored user-
  > friendly name for the BR/EDR Controller.

  * OGF: `#{inspect(@ogf, base: :hex)}`
  * OCF: `#{inspect(@ocf, base: :hex)}`
  * Opcode: `#{inspect(@opcode)}`

  Bluetooth Spec v5.2, Vol 4, Part E, section 7.3.12
  """

  defparameters []

  defimpl BlueHeron.HCI.Serializable do
    def serialize(%{opcode: opcode}) do
      <<opcode::binary, 0>>
    end
  end

  @impl true
  def deserialize(<<@opcode::binary, 0>>) do
    # This is a pretty useless function because there aren't
    # any parameters to actually parse out of this, but we
    # can at least assert its correct with matching
    %__MODULE__{}
  end

  @impl true
  def deserialize_return_parameters(<<status, local_name::binary>>) do
    %{
      status: status,
      # The local name field will fill any remainder of the
      # 248 bytes with null bytes. So just trim those.
      local_name: String.trim(local_name, <<0>>)
    }
  end

  @impl true
  def serialize_return_parameters(%{status: status, local_name: local_name}) do
    name_length = byte_size(local_name)
    padding = 248 - name_length

    <<BlueHeron.ErrorCode.to_code!(status), local_name::binary-size(name_length),
      0::size(padding)-unit(8)>>
  end
end
