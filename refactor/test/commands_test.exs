defmodule CommandsTest do
  use ExUnit.Case
  alias BlueHeron.HCI.{Command, Commands, Commands.SetEventMask, RawMessage, ReturnParameters}

  defp random_meta() do
    %{ts: NaiveDateTime.utc_now()}
  end

  test "encoding/decoding local name" do
    command = %Command{type: :read_local_name, meta: random_meta()}
    encoded = Commands.encode(command)

    assert encoded.data == <<20, 12, 0, 0>>

    return_packet = %RawMessage{data: <<20, 12, 0, "my local name", 0>>, meta: random_meta()}
    {:ok, result} = encoded.decode_response.(return_packet)

    assert result == %ReturnParameters{
             type: :read_local_name,
             args: %{local_name: "my local name"},
             status: 0,
             meta: return_packet.meta
           }

    assert command == Commands.decode(encoded)
  end

  test "encoding/decoding set event mask" do
    command = Commands.set_event_mask(SetEventMask.default(), random_meta())
    encoded = Commands.encode(command)

    assert encoded.data == <<1, 12, 8, 255, 159, 251, 255, 7, 248, 191, 61>>

    return_packet = %RawMessage{data: <<1, 12, 0>>, meta: random_meta()}
    {:ok, result} = encoded.decode_response.(return_packet)

    assert result == %ReturnParameters{
             type: :set_event_mask,
             status: 0,
             meta: return_packet.meta
           }

    assert command == Commands.decode(encoded)
  end

  test "encoding/decoding create connection" do
    command = Commands.create_connection(%{peer_address: 1234}, random_meta())
    encoded = Commands.encode(command)

    assert encoded.data ==
             <<13, 32, 25, 128, 12, 64, 6, 0, 0, 210, 4, 0, 0, 0, 0, 0, 36, 0, 128, 12, 18, 0, 64,
               6, 6, 0, 84, 0>>

    return_packet = %RawMessage{data: <<13, 32, 0>>, meta: random_meta()}
    {:ok, result} = encoded.decode_response.(return_packet)

    # No return parameters
    assert result == nil

    assert command == Commands.decode(encoded)
  end
end
