defmodule BlueHeron.HCI.Command.ControllerAndBaseband.WriteLEHostSupportTest do
  use ExUnit.Case

  alias BlueHeron.HCI.Command.ControllerAndBaseband.WriteLEHostSupport

  test "serializes parameters correctly" do
    serialized =
      %WriteLEHostSupport{le_supported_host_enabled: true}
      |> BlueHeron.HCI.Serializable.serialize()

    assert <<0x6D, 0x0C, 0x02, 0x01, 0x00>> == serialized
  end

  test "serde is symmetric" do
    for val <- [false, true] do
      assert %WriteLEHostSupport{le_supported_host_enabled: val} ==
               %WriteLEHostSupport{le_supported_host_enabled: val}
               |> BlueHeron.HCI.Serializable.serialize()
               |> WriteLEHostSupport.deserialize()
    end
  end
end
