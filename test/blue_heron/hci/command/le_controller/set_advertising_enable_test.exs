# SPDX-FileCopyrightText: 2021 Troels Brødsgaard
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule BlueHeron.HCI.Command.LEController.SetAdvertisingEnableTest do
  use ExUnit.Case

  alias BlueHeron.HCI.Command.LEController.SetAdvertisingEnable

  test "encodes parameters correctly" do
    serialized =
      %SetAdvertisingEnable{advertising_enable: true}
      |> BlueHeron.HCI.Serializable.serialize()

    assert <<0x0A, 0x20, 1, 0x01>> == serialized
  end

  test "serde is symmetric" do
    advertising_enable = Enum.random([true, false])

    expected = %SetAdvertisingEnable{advertising_enable: advertising_enable}

    assert expected ==
             expected
             |> BlueHeron.HCI.Serializable.serialize()
             |> SetAdvertisingEnable.deserialize()
  end
end
