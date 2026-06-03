# SPDX-FileCopyrightText: 2024 Connor Rigby
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule BlueHeron.HCI.Event.CommandCompleteTest do
  use ExUnit.Case

  alias BlueHeron.HCI.Event.CommandComplete

  test "deserializes known opcode (Reset)" do
    # CommandComplete for Reset: event_code=0x0E, size=4, num_packets=1, opcode=0x0C03, status=0
    bin = <<0x0E, 0x04, 0x01, 0x03, 0x0C, 0x00>>

    assert %CommandComplete{
             num_hci_command_packets: 1,
             opcode: <<0x03, 0x0C>>,
             return_parameters: %{status: 0}
           } = CommandComplete.deserialize(bin)
  end

  test "deserializes known opcode with error status" do
    # CommandComplete for Reset with status=0x12 (Role Not Allowed)
    bin = <<0x0E, 0x04, 0x01, 0x03, 0x0C, 0x12>>

    assert %CommandComplete{
             num_hci_command_packets: 1,
             opcode: <<0x03, 0x0C>>,
             return_parameters: %{status: 0x12}
           } = CommandComplete.deserialize(bin)
  end

  test "deserializes unknown opcode without crashing" do
    # CommandComplete with a fabricated unknown opcode 0xFF01, status byte 0x00
    bin = <<0x0E, 0x04, 0x01, 0x01, 0xFF, 0x00>>

    assert %CommandComplete{
             num_hci_command_packets: 1,
             opcode: <<0x01, 0xFF>>,
             return_parameters: %{status: 0}
           } = CommandComplete.deserialize(bin)
  end

  test "deserializes unknown opcode with extra return data" do
    # Unknown opcode with multiple bytes of return data
    bin = <<0x0E, 0x06, 0x01, 0x01, 0xFF, 0x00, 0xAA, 0xBB>>

    assert %CommandComplete{
             num_hci_command_packets: 1,
             opcode: <<0x01, 0xFF>>
           } = CommandComplete.deserialize(bin)
  end

  test "deserializes vendor-specific DownloadMinidriver response" do
    # CommandComplete for DownloadMinidriver (0xFC2E), status=0
    bin = <<0x0E, 0x04, 0x01, 0x2E, 0xFC, 0x00>>

    assert %CommandComplete{
             num_hci_command_packets: 1,
             opcode: <<0x2E, 0xFC>>,
             return_parameters: %{status: 0}
           } = CommandComplete.deserialize(bin)
  end

  test "deserializes vendor-specific UpdateBaudrate response" do
    # CommandComplete for UpdateBaudrate (0xFC18), status=0
    bin = <<0x0E, 0x04, 0x01, 0x18, 0xFC, 0x00>>

    assert %CommandComplete{
             num_hci_command_packets: 1,
             opcode: <<0x18, 0xFC>>,
             return_parameters: %{status: 0}
           } = CommandComplete.deserialize(bin)
  end

  test "returns error tuple for invalid binary" do
    assert {:error, _} = CommandComplete.deserialize(<<0x0E, 0x00>>)
  end

  test "serde is symmetric for known opcode" do
    command_complete = %CommandComplete{
      num_hci_command_packets: 1,
      opcode: <<0x03, 0x0C>>,
      return_parameters: %{status: 0}
    }

    assert command_complete ==
             command_complete
             |> BlueHeron.HCI.Serializable.serialize()
             |> CommandComplete.deserialize()
  end
end
