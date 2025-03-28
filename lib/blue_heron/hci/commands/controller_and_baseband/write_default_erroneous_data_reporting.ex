# SPDX-FileCopyrightText: 2021 Troels Brødsgaard
# SPDX-FileCopyrightText: 2024 Connor Rigby
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule BlueHeron.HCI.Command.ControllerAndBaseband.WriteDefaultErroneousDataReporting do
  use BlueHeron.HCI.Command.ControllerAndBaseband, ocf: 0x005B

  @moduledoc """
  > This command writes the Erroneous_Data_Reporting parameter. 

  * OGF: `#{inspect(@ogf, base: :hex)}`
  * OCF: `#{inspect(@ocf, base: :hex)}`
  * Opcode: `#{inspect(@opcode)}`

  Bluetooth Spec v5.2, Vol 4, Part E, section 7.3.65
  """

  defparameters enabled: false

  defimpl BlueHeron.HCI.Serializable do
    def serialize(%{opcode: opcode, enabled: enabled?}) do
      val = if enabled?, do: <<0x01>>, else: <<0x00>>
      <<opcode::binary, 1, val::binary>>
    end
  end

  @impl BlueHeron.HCI.Command
  def deserialize(<<@opcode::binary, 1, enabled::binary>>) do
    val = if enabled == <<0x01>>, do: true, else: false
    new(enabled: val)
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
