defmodule BlueHeron.HCI.Command.ControllerAndBaseband.WriteInquiryMode do
  use BlueHeron.HCI.Command.ControllerAndBaseband, ocf: 0x0045

  @moduledoc """
  > This command writes the Inquiry_Mode configuration parameter of the local BR/EDR
  > Controller

  * OGF: `#{inspect(@ogf, base: :hex)}`
  * OCF: `#{inspect(@ocf, base: :hex)}`
  * Opcode: `#{inspect(@opcode)}`

  Bluetooth Spec v5.2, Vol 4, Part E, section 7.3.50
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
  def deserialize_return_parameters(<<status>>) do
    %{status: status}
  end

  @impl BlueHeron.HCI.Command
  def serialize_return_parameters(%{status: status}) do
    <<status>>
  end
end
