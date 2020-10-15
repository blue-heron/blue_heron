defmodule BlueHeron.HCI.Command.ControllerAndBaseband.WritePageTimeout do
  use BlueHeron.HCI.Command.ControllerAndBaseband, ocf: 0x0018

  @moduledoc """
  This command writes the value for the Page_Timeout configuration parameter.

  * OGF: `#{inspect(@ogf, base: :hex)}`
  * OCF: `#{inspect(@ocf, base: :hex)}`
  * Opcode: `#{inspect(@opcode)}`

  Bluetooth Spec v5.2, Vol 4, Part E, section 7.3.16

  The Page_Timeout configuration parameter defines the maximum time the local
  Link Manager shall wait for a baseband page response from the remote device at
  a locally initiated connection attempt. If this time expires and the remote
  device has not responded to the page at baseband level, the connection attempt
  will be considered to have failed.

  ## Command Parameters
  * `timeout` - N * 0.625 ms (1 Baseband slot)

  ## Return Parameters
  * `:status` - see `BlueHeron.ErrorCode`
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
