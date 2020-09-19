defmodule CommandsTest do
  use ExUnit.Case
  alias BlueHeron.HCI.{Command, Commands, RawMessage, ReturnParameters}

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
end
