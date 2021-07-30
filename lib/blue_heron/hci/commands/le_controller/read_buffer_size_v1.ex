defmodule BlueHeron.HCI.Command.LEController.ReadBufferSizeV1 do
  use BlueHeron.HCI.Command.LEController, ocf: 0x0002

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
