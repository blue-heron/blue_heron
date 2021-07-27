defmodule BlueHeron.HCI.Command.ControllerAndBaseband.WriteDefaultErroneousDataReportingTest do
  use ExUnit.Case

  alias BlueHeron.HCI.Command.ControllerAndBaseband.WriteDefaultErroneousDataReporting

  test "serializes parameters correctly" do
    serialized =
      %WriteDefaultErroneousDataReporting{enabled: true}
      |> BlueHeron.HCI.Serializable.serialize()

    assert <<0x5B, 0x0C, 0x01, 0x01>> == serialized
  end

  test "serde is symmetric" do
    for val <- [false, true] do
      assert %WriteDefaultErroneousDataReporting{enabled: val} ==
               %WriteDefaultErroneousDataReporting{enabled: val}
               |> BlueHeron.HCI.Serializable.serialize()
               |> WriteDefaultErroneousDataReporting.deserialize()
    end
  end
end
