defmodule BlueHeron.BTSnoop do
  defstruct [:type, :timestamp, :payload, :drops, :direction]

  @hci_uart_type 1002
  def decode_file!(path) do
    case File.read!(path) do
      <<"btsnoop", 0x0, 1::32, @hci_uart_type::32, bin::binary>> ->
        decode_bin(bin, [])

      <<"btsnoop", 0x0, version::32, type::32, _bin::binary>> ->
        # PRS Welcome
        raise "Unsupported version: #{version} or type: #{type}"
    end
  end

  def decode_bin(packets, acc)

  def decode_bin(
        <<_original_length::32, packet_data_length::32, direction::1, type::1, _reserved::30,
          drops::32, micros::signed-64, data::binary-size(packet_data_length), rest::binary>>,
        acc
      ) do
    direction = if direction == 0, do: :sent, else: :received
    type = if type == 0, do: :data, else: :command

    packet = %__MODULE__{
      # TODO
      # In order to avoid leap-day ambiguity in calculations,
      # note that an equivalent epoch may be used of midnight,
      # January 1st 2000 AD, which is represented in this field as 0x00E03AB44A676000.
      timestamp: micros,
      drops: drops,
      direction: direction,
      type: type
    }

    decode_bin(rest, [decode_payload(packet, data) | acc])
  end

  def decode_bin(<<>>, acc), do: Enum.reverse(acc)

  # TODO (draw the rest of the owl)
  def decode_payload(packet, <<0x2, data::binary>>) do
    payload = BlueHeron.ACL.deserialize(data)
    %{packet | payload: payload, type: :HCI_ACL_DATA_PACKET}
  end

  def decode_payload(_packet, <<type, data::binary>>) do
    raise "unknown type: #{type} for data: #{inspect(data, base: :hex, limit: :infinity)}"
  end
end
