defmodule BlueHeron.HCI.Events do
  alias BlueHeron.HCI.Commands.ReturnParameters

  import BlueHeron.HCI.Helpers, only: [decode_status!: 1]

  @type packet :: binary()

  defstruct packet: <<>>, parameters: %{}, type: :unknown

  @doc """
  Decode an event packet into a structure

  Structure:
  * `packet` - original packet before decoding
  * `parameters` - decoded event parameters (if any) as a map
  * `type` - atom representing the type of event. If decoding for a particular
    event has not been implemented, then this will be `:unknown` and you will be
    able to do your own introspection on the original packet from the `:packet`
    key
  """
  @spec decode(packet()) :: %__MODULE__{packet: packet(), parameters: map(), type: atom()}
  def decode(packet) when is_binary(packet) do
    %{do_decode(packet) | packet: packet}
  end

  def encode(%__MODULE__{type: :HCI_Inquiry_Complete} = event) do
    <<0x01, 1, event.parameters.status>>
  end

  defp add_status(event, status) do
    parameters =
      decode_status!(status)
      |> Map.merge(event.parameters)

    %{event | parameters: parameters}
  end

  defp do_decode(<<0x01, _size, status>>) do
    %__MODULE__{type: :HCI_Inquiry_Complete}
    |> add_status(status)
  end

  defp do_decode(<<0x0E, num_hci_command_packets::8, rp_packet::binary>>) do
    <<opcode::binary-2, _rp_bin::binary>> = rp_packet

    parameters = %{
      num_hci_command_packets: num_hci_command_packets,
      opcode: opcode,
      return_parameters: ReturnParameters.decode(rp_packet)
    }

    %__MODULE__{parameters: parameters, type: :HCI_Command_Complete}
  end

  ##
  # Any new event decoding should be added in a do_decode/1 function above this line
  ##

  defp do_decode(_packet), do: %__MODULE__{}
end
