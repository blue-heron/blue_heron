defmodule BlueHeron.HCI.SymmetryTest do
  use ExUnit.Case, async: true

  alias BlueHeron.HCI.{Commands, Events}

  describe "commands" do
    test "read local name" do
      rln = Commands.read_local_name()
      assert rln == Commands.encode(rln) |> Commands.decode()
    end

    test "set event mask" do
      sem = Commands.set_event_mask()
      assert sem == Commands.encode(sem) |> Commands.decode()
    end

    test "create connection" do
      cc = Commands.create_connection(peer_address: 1234)
      assert cc == Commands.encode(cc) |> Commands.decode()
    end
  end

  describe "events" do
    test "HCI_Inquiry_Complete" do
      packet = <<0x01, 1, 0>>
      assert packet == Events.decode(packet) |> Events.encode()
    end
  end
end
