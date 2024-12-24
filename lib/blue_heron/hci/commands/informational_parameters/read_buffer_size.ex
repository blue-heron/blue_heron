defmodule BlueHeron.HCI.Command.InformationalParameters.ReadBufferSize do
  use BlueHeron.HCI.Command.InformationalParameters, ocf: 0x0005

  @moduledoc """
  > The HCI_Read_Buffer_Size command is used to read the maximum size of the data
  > portion of HCI ACL and Synchronous Data packets sent from the Host to the Controller.

  * OGF: `#{inspect(@ogf, base: :hex)}`
  * OCF: `#{inspect(@ocf, base: :hex)}`
  * Opcode: `#{inspect(@opcode)}`

  Bluetooth Spec v5.3, Vol 4, Part E, section 7.4.5
  """

  defparameters []

  defimpl BlueHeron.HCI.Serializable do
    def serialize(payload) do
      <<payload.opcode::binary, 0>>
    end
  end

  @impl BlueHeron.HCI.Command
  def deserialize(<<@opcode::binary, 0>>) do
    %__MODULE__{}
  end

  @impl BlueHeron.HCI.Command
  def deserialize_return_parameters(
        <<status, acl_packet_length::little-16, syn_packet_length, acl_packet_number::little-16,
          syn_packet_number::little-16>>
      ) do
    %{
      status: status,
      acl_packet_length: acl_packet_length,
      syn_packet_length: syn_packet_length,
      acl_packet_number: acl_packet_number,
      syn_packet_number: syn_packet_number
    }
  end

  @impl BlueHeron.HCI.Command
  def serialize_return_parameters(%{
        status: status,
        acl_packet_length: acl_packet_length,
        syn_packet_length: syn_packet_length,
        acl_packet_number: acl_packet_number,
        syn_packet_number: syn_packet_number
      }) do
    <<status>> <>
      <<acl_packet_length::little-16>> <>
      <<syn_packet_length>> <>
      <<acl_packet_number::little-16>> <>
      <<syn_packet_number::little-16>>
  end
end
