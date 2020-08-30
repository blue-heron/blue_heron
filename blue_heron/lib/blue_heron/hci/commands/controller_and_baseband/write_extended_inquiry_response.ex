defmodule BlueHeron.HCI.Command.ControllerAndBaseband.WriteExtendedInquiryResponse do
  @moduledoc """
  The HCI_Write_Extended_Inquiry_Response command writes the extended inquiry
  response to be sent during the extended inquiry response procedure.

  * OGF: `0x3`
  * OCF: `0x52`
  * Opcode: `0xc52`

  Bluetooth Spec v5.2, Vol 4, Part E, section 7.3.56

  The FEC_Required command parameter states if FEC encoding is required. The
  extended inquiry response data is not preserved over a reset. The initial
  value of the inquiry response data is all zero octets. The Controller shall
  not interpret the extended inquiry response data.

  ## Command Parameters
  * `fec_required` - boolean to set if FEC required. Default `false`
  * `extended_inquiry_response` - up to 240 bytes

  ## Return Parameters
  * `:status` - see `BlueHeron.ErrorCode`
  * `:status_name` - Friendly status name. see `BlueHeron.ErrorCode`
  """

  @behaviour BlueHeron.HCI.Command
  defstruct fec_required?: false, extended_inquiry_response: <<0>>

  @impl BlueHeron.HCI.Command
  def opcode(), do: 0xC52

  @impl BlueHeron.HCI.Command
  def serialize(data) do
    val = if data.fec_required?, do: 1, else: 0
    rem = 240 - byte_size(data.extended_inquiry_response)
    padded = for _i <- 1..rem, into: data.extended_inquiry_response, do: <<0>>
    <<val::8, padded::binary>>
  end

  @impl BlueHeron.HCI.Command
  def deserialize(<<fec_req::8, eir::binary>>) do
    val = if fec_req == 1, do: true, else: false
    %__MODULE__{fec_required?: val, extended_inquiry_response: String.trim(eir, <<0>>)}
  end

  @impl BlueHeron.HCI.Command
  def deserialize_return_parameters(<<status::8>>) do
    %{status: status, status_name: BlueHeron.ErrorCode.name!(status)}
  end

  @impl true
  def serialize_return_parameters(%{status: status}) do
    <<status::8>>
  end
end
