defmodule BlueHeron.HCI.Command.ControllerAndBaseband.WriteScanEnableTest do
  use ExUnit.Case

  alias BlueHeron.HCI.Command.ControllerAndBaseband.WriteScanEnable

  test "serializes scan_enable parameter correctly" do
    val = Enum.random(0x00..0x03)

    serialized =
      %WriteScanEnable{scan_enable: val}
      |> BlueHeron.HCI.Serializable.serialize()

    assert <<0x1A, 0x0C, 0x01, val>> == serialized
  end

  test "serde is symmetric" do
    for val <- 0x00..0x03 do
      assert %WriteScanEnable{scan_enable: val} ==
               %WriteScanEnable{scan_enable: val}
               |> BlueHeron.HCI.Serializable.serialize()
               |> WriteScanEnable.deserialize()
    end
  end
end
