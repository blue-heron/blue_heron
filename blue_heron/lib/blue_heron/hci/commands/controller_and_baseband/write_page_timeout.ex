defmodule BlueHeron.HCI.Command.ControllerAndBaseband.WritePageTimeout do
  @moduledoc """
  This command writes the value for the Page_Timeout configuration parameter.

  * OGF: `0x3`
  * OCF: `0x18`
  * Opcode: `0xc18`

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
  @behaviour BlueHeron.HCI.Command
  defstruct timeout: 0x20

  @impl BlueHeron.HCI.Command
  def opcode, do: 0xC18

  @impl BlueHeron.HCI.Command
  def serialize(%__MODULE__{timeout: timeout}) do
    <<timeout::16>>
  end

  @impl BlueHeron.HCI.Command
  def deserialize(<<timeout::16>>) do
    %__MODULE__{timeout: timeout}
  end

  @impl BlueHeron.HCI.Command
  def deserialize_return_parameters(<<status::8>>) do
    %{status: status, status_name: BlueHeron.ErrorCode.name!(status)}
  end

  @impl BlueHeron.HCI.Command
  def serialize_return_parameters(%{status: status}) do
    <<status::8>>
  end
end
