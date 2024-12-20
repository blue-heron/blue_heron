defmodule BlueHeron.HCI.Event.LEMeta.ConnectionUpdateComplete do
  use BlueHeron.HCI.Event.LEMeta, subevent_code: 0x3

  @moduledoc """
  > The HCI_LE_Connection_Update_Complete event is used to indicate that the
  > Connection Update procedure has completed.

  Reference: Version 5.2, Vol 4, Part E, 7.7.65.3
  """

  defparameters [
    :subevent_code,
    :connection_handle,
    :connection_interval,
    :peripheral_latency,
    :supervision_timeout,
    :status
  ]

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
