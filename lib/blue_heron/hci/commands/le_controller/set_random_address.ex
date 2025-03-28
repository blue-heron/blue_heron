# SPDX-FileCopyrightText: 2021 Troels Brødsgaard
# SPDX-FileCopyrightText: 2024 Connor Rigby
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule BlueHeron.HCI.Command.LEController.SetRandomAddress do
  use BlueHeron.HCI.Command.LEController, ocf: 0x0005

  @moduledoc """
  > The HCI_LE_Set_Random_Address command is used by the Host to set the LE
  > Random Device Address in the Controller

  Bluetooth Core Version 5.2 | Vol 4, Part E, section 7.8.4

  * OGF: `#{inspect(@ogf, base: :hex)}`
  * OCF: `#{inspect(@ocf, base: :hex)}`
  * Opcode: `#{inspect(@opcode)}`
  """

  defparameters random_address: nil

  defimpl BlueHeron.HCI.Serializable do
    def serialize(command) do
      <<command.opcode::binary, 0x06, command.random_address::little-48>>
    end
  end

  @impl BlueHeron.HCI.Command
  def deserialize(<<@opcode::binary, _fields_size, random_address::little-48>>) do
    new(random_address: random_address)
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
