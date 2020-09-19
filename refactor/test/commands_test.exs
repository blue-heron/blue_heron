defmodule CommandsTest do
  use ExUnit.Case
  alias BlueHeron.HCI.Commands

  test "encoding/decoding local name" do
    encoded = Commands.read_local_name()

    assert encoded.name == :HCI_Read_Local_Name
    assert encoded.packet == <<20, 12, 0, 0>>

    return_packet = <<20, 12, 0, "my local name", 0>>
    result = encoded.return_parameters_decoder.(return_packet)

    assert result == %{local_name: "my local name", status: 0, status_name: "Success"}
  end
end
