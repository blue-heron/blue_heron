defmodule BlueHeron.HCI.EventTest do
  use ExUnit.Case, async: true

  alias BlueHeron.HCI.Events, as: Event

  test "unknown event includes packet" do
    assert Event.decode("wat?!") == %Event{
             type: :unknown,
             packet: "wat?!",
             parameters: %{}
           }
  end

  test "HCI_Inquiry_Complete" do
    packet = <<1, 1, 0>>

    assert Event.decode(packet) == %Event{
             type: :HCI_Inquiry_Complete,
             parameters: %{status: 0, status_name: "Success"},
             packet: packet
           }
  end

  test "HCI_Command_Complete" do
    packet = <<0x0E, 1, 0, 0, "wat">>

    assert Event.decode(packet) == %Event{
             type: :HCI_Command_Complete,
             packet: packet,
             parameters: %{num_hci_command_packets: 1, opcode: <<0, 0>>, return_parameters: "wat"}
           }
  end
end
