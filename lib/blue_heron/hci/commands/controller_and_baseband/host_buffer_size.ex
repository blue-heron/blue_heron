defmodule BlueHeron.HCI.Command.ControllerAndBaseband.HostBufferSize do
  use BlueHeron.HCI.Command.ControllerAndBaseband, ocf: 0x0033

  @moduledoc """
  > The HCI_Host_Buffer_Size command is used by the Host to notify the
  > Controller about the maximum size of the data portion of HCI ACL and
  > Synchronous Data packets sent from the Controller to the Host.

  * OGF: `#{inspect(@ogf, base: :hex)}`
  * OCF: `#{inspect(@ocf, base: :hex)}`
  * Opcode: `#{inspect(@opcode)}`

  Bluetooth Spec v5.2, Vol 4, Part E, section 7.3.39
  """

  defparameters [
    :host_acl_data_packet_length,
    :host_synchronous_data_packet_length,
    :host_total_num_acl_data_packets,
    :host_total_num_synchronous_data_packets
  ]

  defimpl BlueHeron.HCI.Serializable do
    def serialize(%{
          opcode: opcode,
          host_acl_data_packet_length: host_acl_data_packet_length,
          host_synchronous_data_packet_length: host_synchronous_data_packet_length,
          host_total_num_acl_data_packets: host_total_num_acl_data_packets,
          host_total_num_synchronous_data_packets: host_total_num_synchronous_data_packets
        }) do
      <<opcode::binary, host_acl_data_packet_length::little-size(16),
        host_synchronous_data_packet_length, host_total_num_acl_data_packets::little-size(16),
        host_total_num_synchronous_data_packets::little-size(16)>>
    end
  end

  @impl BlueHeron.HCI.Command
  def deserialize(
        <<@opcode::binary, host_acl_data_packet_length::little-size(16),
          host_synchronous_data_packet_length, host_total_num_acl_data_packets::little-size(16),
          host_total_num_synchronous_data_packets::little-size(16)>>
      ) do
    # This is a pretty useless function because there aren't
    # any parameters to actually parse out of this, but we
    # can at least assert its correct with matching
    %__MODULE__{
      host_acl_data_packet_length: host_acl_data_packet_length,
      host_synchronous_data_packet_length: host_synchronous_data_packet_length,
      host_total_num_acl_data_packets: host_total_num_acl_data_packets,
      host_total_num_synchronous_data_packets: host_total_num_synchronous_data_packets
    }
  end

  @impl BlueHeron.HCI.Command
  def deserialize_return_parameters(<<status>>) do
    %{status: status}
  end

  @impl true
  def serialize_return_parameters(%{status: status}) do
    <<BlueHeron.ErrorCode.to_code!(status)>>
  end
end
