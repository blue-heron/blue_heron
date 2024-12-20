defmodule BlueHeron.HCI.Command.LEController.ReadBufferSizeV1 do
  use BlueHeron.HCI.Command.LEController, ocf: 0x0002

  @moduledoc """
  > This command is used to read the maximum size of the data portion of ACL data
  > packets and isochronous data packets sent from the Host to the Controller. The Host
  > shall fragment the data transmitted to the Controller according to these values so that
  > the HCI ACL Data packets and HCI ISO Data packets will contain data up to this size
  > (“data” includes optional fields in the HCI ISO Data packet, such as ISO_SDU_Length).


  Bluetooth Core Version 5.2 | Vol 4, Part E, section 7.8.2

  * OGF: `#{inspect(@ogf, base: :hex)}`
  * OCF: `#{inspect(@ocf, base: :hex)}`
  * Opcode: `#{inspect(@opcode)}`
  """

  defparameters []

  defimpl BlueHeron.HCI.Serializable do
    def serialize(%{opcode: opcode}) do
      <<opcode::binary, 0x00>>
    end
  end

  @impl BlueHeron.HCI.Command
  def deserialize(<<@opcode::binary, 0x00>>) do
    new()
  end

  @impl BlueHeron.HCI.Command
  def deserialize_return_parameters(
        <<status, acl_data_packet_length::little-16, total_num_acl_data_packets>>
      ) do
    %{
      status: status,
      acl_data_packet_length: acl_data_packet_length,
      total_num_acl_data_packets: total_num_acl_data_packets
    }
  end

  @impl BlueHeron.HCI.Command
  def serialize_return_parameters(%{
        status: status,
        acl_data_packet_length: acl_data_packet_length,
        total_num_acl_data_packets: total_num_acl_data_packets
      }) do
    <<
      BlueHeron.ErrorCode.to_code!(status),
      acl_data_packet_length::little-16,
      total_num_acl_data_packets
    >>
  end
end
