# SPDX-FileCopyrightText: 2021 Troels Brødsgaard
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule BlueHeron.HCI.Command.LEController.SetScanParametersTest do
  use ExUnit.Case

  alias BlueHeron.HCI.Command.LEController.SetScanParameters

  test "encodes parameters correctly" do
    serialized =
      %SetScanParameters{
        le_scan_type: 0x01,
        le_scan_interval: 0x0030,
        le_scan_window: 0x0030
      }
      |> BlueHeron.HCI.Serializable.serialize()

    assert <<0x0B, 0x20, 0x07, 0x01, 0x30, 0x00, 0x30, 0x00, 0x00, 0x00>> == serialized
  end

  test "serde is symmetric" do
    le_scan_type = Enum.random(0x00..0x01)
    le_scan_interval = Enum.random(0x0004..0x4000)
    le_scan_window = Enum.random(0x0004..0x4000)
    own_address_type = Enum.random(0x00..0x03)
    scanning_filter_policy = Enum.random(0x00..0x03)

    expected = %SetScanParameters{
      le_scan_type: le_scan_type,
      le_scan_interval: le_scan_interval,
      le_scan_window: le_scan_window,
      own_address_type: own_address_type,
      scanning_filter_policy: scanning_filter_policy
    }

    assert expected ==
             expected
             |> BlueHeron.HCI.Serializable.serialize()
             |> SetScanParameters.deserialize()
  end
end
