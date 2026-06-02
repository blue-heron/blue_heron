# SPDX-FileCopyrightText: 2024 Connor Rigby
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule BlueHeron.HCI.Command.VendorSpecific.UpdateBaudrateTest do
  use ExUnit.Case

  alias BlueHeron.HCI.Command.VendorSpecific.UpdateBaudrate

  test "serializes with default baudrate" do
    serialized =
      %UpdateBaudrate{}
      |> BlueHeron.HCI.Serializable.serialize()

    # OGF 0x3F, OCF 0x18 -> opcode 0xFC18 -> little-endian <<0x18, 0xFC>>
    # 115_200 = 0x0001C200 -> little-endian <<0x00, 0xC2, 0x01, 0x00>>
    assert <<0x18, 0xFC, 6, 0x00, 0x00, 0x00, 0xC2, 0x01, 0x00>> == serialized
  end

  test "serializes with 921600 baudrate" do
    serialized =
      %UpdateBaudrate{baudrate: 921_600}
      |> BlueHeron.HCI.Serializable.serialize()

    # 921_600 = 0x000E1000 -> little-endian <<0x00, 0x10, 0x0E, 0x00>>
    assert <<0x18, 0xFC, 6, 0x00, 0x00, 0x00, 0x10, 0x0E, 0x00>> == serialized
  end

  test "serde is symmetric" do
    for baudrate <- [115_200, 921_600, 3_000_000] do
      expected = %UpdateBaudrate{baudrate: baudrate}

      assert expected ==
               expected
               |> BlueHeron.HCI.Serializable.serialize()
               |> UpdateBaudrate.deserialize()
    end
  end

  test "deserializes return parameters with success status" do
    assert %{status: 0} == UpdateBaudrate.deserialize_return_parameters(<<0>>)
  end

  test "deserializes return parameters with error status" do
    assert %{status: 0x01} == UpdateBaudrate.deserialize_return_parameters(<<0x01>>)
    assert %{status: 0x12} == UpdateBaudrate.deserialize_return_parameters(<<0x12>>)
  end

  test "has correct opcode" do
    assert <<0x18, 0xFC>> == UpdateBaudrate.__opcode__()
  end

  test "deserialize rejects wrong opcode" do
    assert_raise FunctionClauseError, fn ->
      UpdateBaudrate.deserialize(<<0x2E, 0xFC, 6, 0x00, 0x00, 0x00, 0xC2, 0x01, 0x00>>)
    end
  end
end
