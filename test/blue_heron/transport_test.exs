# SPDX-FileCopyrightText: 2020 Connor Rigby
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule BlueHeron.TransportTest do
  use ExUnit.Case

  # @reset %BlueHeron.HCI.Command.ControllerAndBaseband.Reset{}
  # |> BlueHeron.HCI.Serializable.serialize()

  # test "basic init" do
  #   config = %BlueHeron.HCI.Transport.NULL{
  #     init_commands: [
  #       @reset
  #     ],
  #     replies: %{
  #       @reset => "\x0e\x04\x03\x03\x0c\x00"
  #     }
  #   }

  #   {:ok, pid} = BlueHeron.HCI.Transport.start_link(config)

  #   assert {:ok,
  #           %BlueHeron.HCI.Event.CommandComplete{
  #             num_hci_command_packets: 3,
  #             opcode: <<3, 12>>,
  #             return_parameters: <<0>>
  #           }} = BlueHeron.HCI.Transport.command(pid, @reset)
  # end
end
