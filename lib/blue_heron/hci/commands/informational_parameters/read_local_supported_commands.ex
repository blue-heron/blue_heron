# SPDX-FileCopyrightText: 2023 Markus Hutzler
# SPDX-FileCopyrightText: 2024 Connor Rigby
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule BlueHeron.HCI.Command.InformationalParameters.ReadLocalSupportedCommands do
  use BlueHeron.HCI.Command.InformationalParameters, ocf: 0x0002

  @moduledoc """
  > This command reads the list of HCI commands supported for the local Controller.

  * OGF: `#{inspect(@ogf, base: :hex)}`
  * OCF: `#{inspect(@ocf, base: :hex)}`
  * Opcode: `#{inspect(@opcode)}`

  Bluetooth Spec v5.3, Vol 4, Part E, section 7.4.2
  """

  defparameters []

  defimpl BlueHeron.HCI.Serializable do
    def serialize(rlv) do
      <<rlv.opcode::binary, 0>>
    end
  end

  @impl BlueHeron.HCI.Command
  def deserialize(<<@opcode::binary, 0>>) do
    %__MODULE__{}
  end

  @impl BlueHeron.HCI.Command
  def deserialize_return_parameters(<<status, bin::binary>>) do
    %{
      status: status,
      supported_commands: bin
    }
  end

  @impl BlueHeron.HCI.Command
  def serialize_return_parameters(%{status: status} = params) do
    <<status>> <> params.supported_commands
  end
end
