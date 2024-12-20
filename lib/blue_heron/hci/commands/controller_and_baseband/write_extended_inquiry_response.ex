defmodule BlueHeron.HCI.Command.ControllerAndBaseband.WriteExtendedInquiryResponse do
  use BlueHeron.HCI.Command.ControllerAndBaseband, ocf: 0x0052

  @moduledoc """
  > The HCI_Write_Extended_Inquiry_Response command writes the extended inquiry
  > response to be sent during the extended inquiry response procedure.

  * OGF: `#{inspect(@ogf, base: :hex)}`
  * OCF: `#{inspect(@ocf, base: :hex)}`
  * Opcode: `#{inspect(@opcode)}`

  Bluetooth Spec v5.2, Vol 4, Part E, section 7.3.56
  """

  defparameters fec_required?: false, extended_inquiry_response: <<0>>

  defimpl BlueHeron.HCI.Serializable do
    def serialize(data) do
      val = if data.fec_required?, do: <<1>>, else: <<0>>
      rem = 240 - byte_size(data.extended_inquiry_response)

      padded = for _i <- 1..rem, into: data.extended_inquiry_response, do: <<0>>

      <<data.opcode::binary, 241, val::binary, padded::binary>>
    end
  end

  @impl BlueHeron.HCI.Command
  def deserialize(<<@opcode::binary, _size, fec_req, eir::binary>>) do
    val = if fec_req == 1, do: true, else: false
    %__MODULE__{fec_required?: val, extended_inquiry_response: String.trim(eir, <<0>>)}
  end

  @impl BlueHeron.HCI.Command
  def deserialize_return_parameters(<<status>>) do
    %{status: status}
  end

  @impl true
  def serialize_return_parameters(%{status: status}) do
    <<status>>
  end
end
