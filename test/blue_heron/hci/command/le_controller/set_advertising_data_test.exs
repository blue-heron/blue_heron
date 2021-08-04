defmodule BlueHeron.HCI.Command.LEController.SetAdvertisingDataTest do
  use ExUnit.Case

  alias BlueHeron.HCI.Command.LEController.SetAdvertisingData

  test "encodes parameters correctly" do
    serialized =
      %SetAdvertisingData{advertising_data: <<0x02, 0x01, 0b00000110>>}
      |> BlueHeron.HCI.Serializable.serialize()

    assert <<0x08, 0x20, 0x20, 0x03, 0x02, 0x01, 0b00000110, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
             0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
             0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00>> == serialized
  end

  test "serde is symmetric" do
    advertising_data = <<0x02, 0x01, Enum.random(0x00..0xFF)>>

    expected = %SetAdvertisingData{advertising_data: advertising_data}

    assert expected ==
             expected
             |> BlueHeron.HCI.Serializable.serialize()
             |> SetAdvertisingData.deserialize()
  end
end
