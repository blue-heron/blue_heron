defmodule BlueHeron.HCI.Event.LEMeta.ConnectionUpdateComplete do
  use BlueHeron.HCI.Event.LEMeta, subevent_code: 0x3

  defparameters [
    :subevent_code,
    :connection_handle,
    :connection_interval,
    :peripheral_latency,
    :supervision_timeout,
    :status
  ]

  defimpl BlueHeron.HCI.Serializable do
    def serialize(cc) do
      raise(RuntimeError, "fixme")
    end
  end

  @impl BlueHeron.HCI.Event
  def deserialize(<<@code, _size, @subevent_code, bin::binary>>) do
    <<
      status,
      connection_handle::little-12,
      _unused::4,
      connection_interval::little-16,
      peripheral_latency::little-16,
      supervision_timeout::little-16
    >> = bin

    %__MODULE__{
      subevent_code: @subevent_code,
      connection_handle: connection_handle,
      connection_interval: connection_interval,
      peripheral_latency: peripheral_latency,
      supervision_timeout: supervision_timeout,
      status: status
    }
  end

  def deserialize(bin), do: {:error, bin}
end
