defmodule BlueHeron.TransportTest do
  use ExUnit.Case

  test "basic init" do
    config = %BlueHeron.HCI.Transport.NULL{
      init_commands: [
        Harald.HCI.ControllerAndBaseband.reset()
      ],
      replies: %{
        Harald.HCI.ControllerAndBaseband.reset() => "\x0e\x04\x03\x03\x0c\x00"
      }
    }

    {:ok, pid} = BlueHeron.HCI.Transport.start_link(config)

    assert {:ok,
            %Harald.HCI.Event.CommandComplete{
              num_hci_command_packets: 3,
              opcode: 3075,
              return_parameters: <<0>>
            }} = BlueHeron.HCI.Transport.command(pid, Harald.HCI.ControllerAndBaseband.reset())
  end
end
