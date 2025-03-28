# SPDX-FileCopyrightText: 2020 Connor Rigby
# SPDX-FileCopyrightText: 2020 Frank Hunleth
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule BlueHeron.HCI.Command.ControllerAndBaseband.WritePageTimeout do
  use BlueHeron.HCI.Command.ControllerAndBaseband, ocf: 0x0018

  @moduledoc """
  > This command writes the value for the Page_Timeout configuration parameter

  * OGF: `#{inspect(@ogf, base: :hex)}`
  * OCF: `#{inspect(@ocf, base: :hex)}`
  * Opcode: `#{inspect(@opcode)}`

  Bluetooth Spec v5.2, Vol 4, Part E, section 7.3.16
  """

  defparameters timeout: 0x20

  defimpl BlueHeron.HCI.Serializable do
    def serialize(%{opcode: opcode, timeout: timeout}) do
      <<opcode::binary, 2, timeout::16>>
    end
  end

  @impl BlueHeron.HCI.Command
  def deserialize(<<@opcode::binary, 2, timeout::16>>) do
    new(timeout: timeout)
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
