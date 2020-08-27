defmodule BlueHeron.HCI.Command.ControllerAndBaseband.WriteInquiryMode do
  use BlueHeron.HCI.Command.ControllerAndBaseband, ocf: 0x0045

  @moduledoc """
  This command writes the Inquiry_Mode configuration parameter of the local BR/EDR Controller. See Section 6.5.

  * OGF: `#{inspect(@ogf, base: :hex)}`
  * OCF: `#{inspect(@ocf, base: :hex)}`
  * Opcode: `#{inspect(@opcode)}`

  Bluetooth Spec v5.2, Vol 4, Part E, section 7.3.50

  ## Command Parameters
  * `inquiry_mode` - can be 0, 1, or 2. Default: 0

  ## Return Parameters
  * `:status` - see `BlueHeron.ErrorCode`
  * `:status_name` - Friendly status name. see `BlueHeron.ErrorCode`
  """

  defparameters inquiry_mode: 0

  defimpl BlueHeron.HCI.Serializable do
    def serialize(data) do
      <<data.opcode::binary, 1, data.inquiry_mode>>
    end
  end

  @impl BlueHeron.HCI.Command
  def deserialize(<<@opcode::binary, _size, mode>>) do
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
