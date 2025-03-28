# SPDX-FileCopyrightText: 2020 Connor Rigby
# SPDX-FileCopyrightText: 2020 Frank Hunleth
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule BlueHeron.HCI.Command.ControllerAndBaseband.WriteClassOfDevice do
  use BlueHeron.HCI.Command.ControllerAndBaseband, ocf: 0x0024

  @moduledoc """
  > This command writes the value for the Class_Of_Device parameter.

  * OGF: `#{inspect(@ogf, base: :hex)}`
  * OCF: `#{inspect(@ocf, base: :hex)}`
  * Opcode: `#{inspect(@opcode)}`

  Bluetooth Spec v5.2, Vol 4, Part E, section 7.3.26
  """

  defparameters class: 0x00

  defimpl BlueHeron.HCI.Serializable do
    def serialize(%{opcode: opcode, class: class}) do
      <<opcode::binary, 3, class::24>>
    end
  end

  @impl BlueHeron.HCI.Command
  def deserialize(<<@opcode::binary, 3, class::24>>) do
    new(class: class)
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
