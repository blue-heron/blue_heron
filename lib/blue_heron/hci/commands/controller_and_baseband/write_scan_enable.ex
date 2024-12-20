defmodule BlueHeron.HCI.Command.ControllerAndBaseband.WriteScanEnable do
  use BlueHeron.HCI.Command.ControllerAndBaseband, ocf: 0x001A

  @moduledoc """
  > The Scan_Enable parameter controls whether or not the BR/EDR Controller will
  > periodically scan for page attempts and/or inquiry requests from other BR/EDR
  > Controllers. 

  * OGF: `#{inspect(@ogf, base: :hex)}`
  * OCF: `#{inspect(@ocf, base: :hex)}`
  * Opcode: `#{inspect(@opcode)}`

  Bluetooth Spec v5.2, Vol 4, Part E, section 7.3.18
  """

  defparameters scan_enable: 0x00

  defimpl BlueHeron.HCI.Serializable do
    def serialize(%{opcode: opcode, scan_enable: scan_enable}) do
      <<opcode::binary, 1, scan_enable>>
    end
  end

  @impl BlueHeron.HCI.Command
  def deserialize(<<@opcode::binary, 1, scan_enable>>) do
    new(scan_enable: scan_enable)
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
