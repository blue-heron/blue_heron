# SPDX-FileCopyrightText: 2021 Troels Brødsgaard
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule BlueHeron.HCI.Command.LEController.SetAdvertisingParametersTest do
  use ExUnit.Case

  alias BlueHeron.HCI.Command.LEController.SetAdvertisingParameters

  test "encodes parameters correctly" do
    serialized =
      %SetAdvertisingParameters{
        advertising_interval_min: 0x0801,
        advertising_interval_max: 0x0802,
        advertising_type: 0x00,
        own_address_type: 0x00,
        peer_address_type: 0x00,
        peer_address: 0xAABBCCDDEEFF,
        advertising_channel_map: 0x07,
        advertising_filter_policy: 0x00
      }
      |> BlueHeron.HCI.Serializable.serialize()

    assert <<0x06, 0x20, 15, 0x0801::little-16, 0x0802::little-16, 0x00, 0x00, 0x00, 0xFF, 0xEE,
             0xDD, 0xCC, 0xBB, 0xAA, 0x07, 0x00>> == serialized
  end

  test "serde is symmetric" do
    advertising_interval_min = Enum.random(0x0020..0x4000)
    advertising_interval_max = Enum.random(advertising_interval_min..0x4000)
    advertising_type = Enum.random(0x00..0x04)
    own_address_type = Enum.random(0x00..0x03)
    peer_address_type = Enum.random(0x00..0x01)
    peer_address = Enum.random(0x00..0xFFFFFFFFFFFF)
    advertising_channel_map = Enum.random(0b000..0b111)
    advertising_filter_policy = Enum.random(0x00..0x03)

    expected = %SetAdvertisingParameters{
      advertising_interval_min: advertising_interval_min,
      advertising_interval_max: advertising_interval_max,
      advertising_type: advertising_type,
      own_address_type: own_address_type,
      peer_address_type: peer_address_type,
      peer_address: peer_address,
      advertising_channel_map: advertising_channel_map,
      advertising_filter_policy: advertising_filter_policy
    }

    assert expected ==
             expected
             |> BlueHeron.HCI.Serializable.serialize()
             |> SetAdvertisingParameters.deserialize()
  end
end
