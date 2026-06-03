# SPDX-FileCopyrightText: 2024 Connor Rigby
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule BlueHeron.HCI.Command.VendorSpecific.DownloadMinidriverTest do
  use ExUnit.Case

  alias BlueHeron.HCI.Command.VendorSpecific.DownloadMinidriver

  test "serializes correctly" do
    serialized =
      %DownloadMinidriver{}
      |> BlueHeron.HCI.Serializable.serialize()

    # OGF 0x3F, OCF 0x2E -> opcode 0xFC2E -> little-endian <<0x2E, 0xFC>>
    assert <<0x2E, 0xFC, 0>> == serialized
  end

  test "serde is symmetric" do
    assert %DownloadMinidriver{} ==
             %DownloadMinidriver{}
             |> BlueHeron.HCI.Serializable.serialize()
             |> DownloadMinidriver.deserialize()
  end

  test "deserializes return parameters with success status" do
    assert %{status: 0} == DownloadMinidriver.deserialize_return_parameters(<<0>>)
  end

  test "deserializes return parameters with error status" do
    assert %{status: 0x01} == DownloadMinidriver.deserialize_return_parameters(<<0x01>>)
    assert %{status: 0x12} == DownloadMinidriver.deserialize_return_parameters(<<0x12>>)
  end

  test "serializes return parameters" do
    assert <<0>> == DownloadMinidriver.serialize_return_parameters(%{status: 0})
  end

  test "has correct opcode" do
    assert <<0x2E, 0xFC>> == DownloadMinidriver.__opcode__()
  end

  test "deserialize rejects wrong opcode" do
    assert_raise FunctionClauseError, fn ->
      DownloadMinidriver.deserialize(<<0x18, 0xFC, 0>>)
    end
  end
end
