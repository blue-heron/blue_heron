# SPDX-FileCopyrightText: 2024 Connor Rigby
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule BlueHeron.HCI.Command.VendorSpecific.DownloadMinidriver do
  use BlueHeron.HCI.Command.VendorSpecific, ocf: 0x002E

  @moduledoc """
  Broadcom vendor-specific command to prepare the controller for firmware download.

  * OGF: `#{inspect(@ogf, base: :hex)}`
  * OCF: `#{inspect(@ocf, base: :hex)}`
  * Opcode: `#{inspect(@opcode)}`

  This command must be sent before downloading firmware records from an `.hcd` file.
  """

  defparameters []

  defimpl BlueHeron.HCI.Serializable do
    def serialize(%{opcode: opcode}) do
      <<opcode::binary, 0>>
    end
  end

  @impl BlueHeron.HCI.Command
  def deserialize(<<@opcode::binary, 0>>) do
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
