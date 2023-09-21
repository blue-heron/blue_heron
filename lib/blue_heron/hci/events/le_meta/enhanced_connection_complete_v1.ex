defmodule BlueHeron.HCI.Event.LEMeta.EnhancedConnectionCompleteV1 do
  use BlueHeron.HCI.Event.LEMeta, subevent_code: 0xA

  defparameters [
    :subevent_code,
    :status,
    :connection_handle,
    :role,
    :peer_address_type,
    :peer_address,
    :local_resolvable_private_address,
    :peer_resolvable_private_address,
    :connection_interval,
    :peripheral_latency,
    :supervision_timeout,
    :central_clock_accuracy,
  ]

  defimpl BlueHeron.HCI.Serializable do
    def serialize(cc) do
      <<lower_handle, upper_handle::4>> = <<cc.connection_handle::little-12>>
      connection_handle = <<lower_handle, 0::4, upper_handle::4>>

      bin = <<
        cc.subevent_code,
        cc.status,
        connection_handle::binary,
        cc.role,
        cc.peer_address_type,
        cc.peer_address::little-48,
        cc.connection_interval::little-16,
        cc.connection_latency::little-16,
        cc.supervision_timeout::little-16,
        cc.master_clock_accuracy
      >>

      size = byte_size(bin)

      <<cc.code, size, bin::binary>>
    end
  end

  @impl BlueHeron.HCI.Event
  def deserialize(<<@code, _size, @subevent_code, bin::binary>>) do
    <<
      status,
      lower_handle,
      _::4,
      upper_handle::4,
      role,
      peer_address_type,
      peer_address::little-48,
      local_resolvable_private_address::little-48,
      peer_resolvable_private_address::little-48,
      connection_interval::little-16,
      peripheral_latency::little-16,
      supervision_timeout::little-16,
      central_clock_accuracy
    >> = bin

    <<connection_handle::little-12>> = <<lower_handle, upper_handle::4>>

    %__MODULE__{
      subevent_code: @subevent_code,
      status: status,
      connection_handle: connection_handle,
      role: role,
      peer_address_type: peer_address_type,
      peer_address: peer_address,
      connection_interval: connection_interval,
      peripheral_latency: peripheral_latency,
      supervision_timeout: supervision_timeout,
      central_clock_accuracy: central_clock_accuracy,
      local_resolvable_private_address: local_resolvable_private_address,
      peer_resolvable_private_address: peer_resolvable_private_address,
    }
  end

  def deserialize(bin), do: {:error, bin}
end
