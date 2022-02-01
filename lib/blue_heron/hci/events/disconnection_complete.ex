defmodule BlueHeron.HCI.Event.DisconnectionComplete do
  use BlueHeron.HCI.Event, code: 0x05

  @moduledoc """
  The HCI_Disconnection_Complete event occurs when a connection is terminated.

  The status parameter indicates if the disconnection was successful or not. The
  reason parameter indicates the reason for the disconnection if the
  disconnection was successful. If the disconnection was not successful, the
  value of the reason parameter shall be ignored by the Host. For example, this
  can be the case if the Host has issued the HCI_Disconnect command and there
  was a parameter error, or the command was not presently allowed, or a
  Connection_Handle that didn’t correspond to a connection was given.

  Note: When a physical link fails, one HCI_Disconnection_Complete event will be
  returned for each logical channel on the physical link with the corresponding
  Connection_Handle as a parameter.

  Reference: Version 5.2, Vol 4, Part E, 7.7.5
  """

  defparameters [
    :connection_handle,
    :reason,
    :reason_name,
    :status
  ]

  defimpl BlueHeron.HCI.Serializable do
    def serialize(dc) do
      <<lower_handle, upper_handle::4>> = <<dc.connection_handle::little-12>>
      connection_handle = <<lower_handle, 0::4, upper_handle::4>>

      bin = <<
        dc.status,
        connection_handle::binary,
        dc.reason
      >>

      size = byte_size(bin)

      <<dc.code, size, bin::binary>>
    end
  end

  @impl BlueHeron.HCI.Event
  def deserialize(<<@code, _size, status, lower_handle, _::4, upper_handle::4, reason>>) do
    <<connection_handle::little-12>> = <<lower_handle, upper_handle::4>>

    %__MODULE__{
      connection_handle: connection_handle,
      reason: reason,
      status: status
    }
  end

  def deserialize(bin), do: {:error, bin}
end
