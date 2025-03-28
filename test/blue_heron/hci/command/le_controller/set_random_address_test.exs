# SPDX-FileCopyrightText: 2021 Troels Brødsgaard
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule BlueHeron.HCI.Command.LEController.SetRandomAddressTest do
  use ExUnit.Case

  alias BlueHeron.HCI.Command.LEController.SetRandomAddress

  test "encodes parameters correctly" do
    serialized =
      %SetRandomAddress{
        random_address: 0x112233445566
      }
      |> BlueHeron.HCI.Serializable.serialize()

    assert <<0x05, 0x20, 0x06, 0x66, 0x55, 0x44, 0x33, 0x22, 0x11>> == serialized
  end

  test "serde is symmetric" do
    random_address = Enum.random(0x000000000000..0xFFFFFFFFFFFF)

    expected = %SetRandomAddress{
      random_address: random_address
    }

    assert expected ==
             expected
             |> BlueHeron.HCI.Serializable.serialize()
             |> SetRandomAddress.deserialize()
  end
end
