# SPDX-FileCopyrightText: 2021 Troels Brødsgaard
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule BlueHeron.HCI.Command.ControllerAndBaseband.WriteSynchronousFlowControlEnableTest do
  use ExUnit.Case

  alias BlueHeron.HCI.Command.ControllerAndBaseband.WriteSynchronousFlowControlEnable

  test "serializes parameters correctly" do
    serialized =
      %WriteSynchronousFlowControlEnable{enabled: true}
      |> BlueHeron.HCI.Serializable.serialize()

    assert <<0x2F, 0x0C, 0x01, 0x01>> == serialized
  end

  test "serde is symmetric" do
    for val <- [false, true] do
      assert %WriteSynchronousFlowControlEnable{enabled: val} ==
               %WriteSynchronousFlowControlEnable{enabled: val}
               |> BlueHeron.HCI.Serializable.serialize()
               |> WriteSynchronousFlowControlEnable.deserialize()
    end
  end
end
