# SPDX-FileCopyrightText: 2024 Connor Rigby
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule BlueHeron.HCI.Transport.UART.FirmwareLoaderTest do
  use ExUnit.Case
  alias BlueHeron.HCI.Transport.UART.FirmwareLoader

  describe "parse_hcd/1" do
    test "empty binary returns empty list" do
      assert FirmwareLoader.parse_hcd(<<>>) == []
    end

    test "single record with no parameters" do
      hcd = <<0x2E, 0xFC, 0x00>>
      assert [<<0x2E, 0xFC, 0x00>>] = FirmwareLoader.parse_hcd(hcd)
    end

    test "single record with parameters" do
      hcd = <<0x18, 0xFC, 0x06, 0x00, 0x00, 0x00, 0xC2, 0x01, 0x00>>

      assert [<<0x18, 0xFC, 0x06, 0x00, 0x00, 0x00, 0xC2, 0x01, 0x00>>] =
               FirmwareLoader.parse_hcd(hcd)
    end

    test "multiple records" do
      record1 = <<0x2E, 0xFC, 0x00>>
      record2 = <<0x4C, 0xFC, 0x03, 0xAA, 0xBB, 0xCC>>
      record3 = <<0x4E, 0xFC, 0x00>>
      hcd = record1 <> record2 <> record3

      assert [^record1, ^record2, ^record3] = FirmwareLoader.parse_hcd(hcd)
    end

    test "record with 252-byte payload" do
      params = :binary.copy(<<0xFF>>, 252)
      hcd = <<0x4C, 0xFC, 252>> <> params
      [result] = FirmwareLoader.parse_hcd(hcd)
      assert byte_size(result) == 255
      assert <<0x4C, 0xFC, 252, _rest::binary-252>> = result
    end

    test "preserves exact binary content" do
      params = <<0x01, 0x02, 0x03, 0x04, 0x05>>
      hcd = <<0xAB, 0xCD, 5>> <> params
      [result] = FirmwareLoader.parse_hcd(hcd)
      assert result == hcd
    end

    test "raises on truncated record" do
      # Header says 5 bytes of params but only 3 are present
      truncated = <<0x4C, 0xFC, 0x05, 0xAA, 0xBB, 0xCC>>

      assert_raise FunctionClauseError, fn ->
        FirmwareLoader.parse_hcd(truncated)
      end
    end

    test "raises on incomplete header" do
      # Only 2 bytes, missing length byte
      assert_raise FunctionClauseError, fn ->
        FirmwareLoader.parse_hcd(<<0x4C, 0xFC>>)
      end
    end

    test "raises on single byte" do
      assert_raise FunctionClauseError, fn ->
        FirmwareLoader.parse_hcd(<<0x4C>>)
      end
    end
  end

  describe "firmware_name/1" do
    test "returns BCM43430A1.hcd for CYW43438 (RPi Zero W)" do
      assert FirmwareLoader.firmware_name(0x6106) == "BCM43430A1.hcd"
    end

    test "returns BCM43430B0.hcd for CYW43436S (RPi Zero 2W)" do
      assert FirmwareLoader.firmware_name(0x6107) == "BCM43430B0.hcd"
    end

    test "returns BCM4345C0.hcd for CYW43455 (RPi 3A+/3B+)" do
      assert FirmwareLoader.firmware_name(0x6109) == "BCM4345C0.hcd"
    end

    test "returns BCM4345C0.hcd for CYW43455 (RPi 4 Model B)" do
      assert FirmwareLoader.firmware_name(0x6119) == "BCM4345C0.hcd"
    end

    test "returns nil for unknown subversion" do
      assert FirmwareLoader.firmware_name(0x0000) == nil
    end

    test "returns nil for arbitrary values" do
      assert FirmwareLoader.firmware_name(0xFFFF) == nil
      assert FirmwareLoader.firmware_name(0x1234) == nil
    end
  end
end
