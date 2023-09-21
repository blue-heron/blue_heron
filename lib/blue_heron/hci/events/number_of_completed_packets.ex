defmodule BlueHeron.HCI.Event.NumberOfCompletedPackets do
  use BlueHeron.HCI.Event, code: 0x13

  defparameters [:number_of_handles, :connection_handle, :number_of_completed_packets]

  defimpl BlueHeron.HCI.Serializable do
    def serialize(data) do
      # TODO: param total length: 5 bytes
      <<lower_handle, upper_handle::4>> = <<data.connection_handle::little-12>>
      connection_handle = <<lower_handle, 0::4, upper_handle::4>>

      # TODO: array serde
      <<data.code, 5, data.number_of_handles, connection_handle::binary,
        data.number_of_completed_packets::little-16>>
    end
  end

  @impl BlueHeron.HCI.Event
  def deserialize(
        <<@code, 5, number_of_handles, lower_handle, _::4, upper_handle::4,
          number_of_completed_packets::little-16>>
      ) do
    <<connection_handle::little-12>> = <<lower_handle, upper_handle::4>>

    %__MODULE__{
      number_of_handles: number_of_handles,
      connection_handle: connection_handle,
      number_of_completed_packets: number_of_completed_packets
    }
  end

  def deserialize(bin), do: {:error, bin}
end
