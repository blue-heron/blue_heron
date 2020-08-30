defmodule BlueHeron.HCI.Command.ControllerAndBaseband.WriteInquiryMode do
  @moduledoc """
  This command writes the Inquiry_Mode configuration parameter of the local BR/EDR Controller. See Section 6.5.

  * OGF: `0x3`
  * OCF: `0x45`
  * Opcode: `0xc45`

  Bluetooth Spec v5.2, Vol 4, Part E, section 7.3.50

  ## Command Parameters
  * `inquiry_mode` - can be 0, 1, or 2. Default: 0

  ## Return Parameters
  * `:status` - see `BlueHeron.ErrorCode`
  * `:status_name` - Friendly status name. see `BlueHeron.ErrorCode`
  """

  @behaviour BlueHeron.HCI.Command
  defstruct inquiry_mode: 0

  @impl BlueHeron.HCI.Command
  def opcode(), do: 0xC45

  @impl BlueHeron.HCI.Command
  def serialize(data) do
    <<data.inquiry_mode>>
  end

  @impl BlueHeron.HCI.Command
  def deserialize(<<mode>>) do
    %__MODULE__{inquiry_mode: mode}
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
