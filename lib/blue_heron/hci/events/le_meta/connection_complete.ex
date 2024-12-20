defmodule BlueHeron.HCI.Event.LEMeta.ConnectionComplete do
  use BlueHeron.HCI.Event.LEMeta, subevent_code: 0x01

  @moduledoc """
  > The HCI_LE_Connection_Complete event indicates to both of the Hosts forming
  > the connection that a new connection has been created.

  Reference: Version 5.2, Vol 4, Part E, 7.7.65.1
  """

  defparameters [
    :status,
    :connection_handle,
    :role,
    :peer_address_type,
    :peer_address,
    :connection_interval,
    :connection_latency,
    :supervision_timeout,
    :master_clock_accuracy,
    :subevent_code
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
      connection_handle::little-12,
      0x00::4,
      role,
      peer_address_type,
      peer_address::little-48,
      connection_interval::little-16,
      connection_latency::little-16,
      supervision_timeout::little-16,
      master_clock_accuracy
    >> = bin

    %__MODULE__{
      subevent_code: @subevent_code,
      status: status,
      connection_handle: connection_handle,
      role: role,
      peer_address_type: peer_address_type,
      peer_address: peer_address,
      connection_interval: connection_interval,
      connection_latency: connection_latency,
      supervision_timeout: supervision_timeout,
      master_clock_accuracy: master_clock_accuracy
    }
  end

  def deserialize(bin), do: {:error, bin}
end
