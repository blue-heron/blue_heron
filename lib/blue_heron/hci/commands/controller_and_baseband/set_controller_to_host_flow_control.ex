# SPDX-FileCopyrightText: 2020 Connor Rigby
# SPDX-FileCopyrightText: 2020 Frank Hunleth
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule BlueHeron.HCI.Command.ControllerAndBaseband.SetControllerToHostFlowControl do
  use BlueHeron.HCI.Command.ControllerAndBaseband, ocf: 0x0031

  @moduledoc """
  > This command is used by the Host to turn flow control on or off for data and/or
  > voice sent in the direction from the Controller to the Host. 

  * OGF: `#{inspect(@ogf, base: :hex)}`
  * OCF: `#{inspect(@ocf, base: :hex)}`
  * Opcode: `#{inspect(@opcode)}`

  Bluetooth Spec v5.2, Vol 4, Part E, section 7.3.38
  """

  defparameters flow_control_enable: 0

  defimpl BlueHeron.HCI.Serializable do
    def serialize(%{opcode: opcode, flow_control_enable: flow_control_enable}) do
      <<opcode::binary, 1, flow_control_enable>>
    end
  end

  @impl BlueHeron.HCI.Command
  def deserialize(<<@opcode::binary, 0>>) do
    # This is a pretty useless function because there aren't
    # any parameters to actually parse out of this, but we
    # can at least assert its correct with matching
    %__MODULE__{}
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
