defmodule BlueHeron.HCI.CommandTest do
  use ExUnit.Case, async: true

  alias BlueHeron.HCI.Commands, as: Command

  test "read_local_name" do
    assert Command.read_local_name() == <<20, 12, 0, 0>>
  end

  test "reset" do
    assert Command.reset() == <<3, 12, 0, 0>>
  end

  test "set_event_mask" do
    assert Command.set_event_mask() ==
             <<1, 12, 8, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF>>
  end

  test "write_class_of_device" do
    assert Command.write_class_of_device(1) == <<36, 12, 3, 0, 0, 1>>
  end

  test "write_extended_query_response" do
    assert Command.write_extended_query_response() == <<82, 12, 241, 0, 0, 0::size(239)-unit(8)>>
  end

  test "write_inquiry_mode" do
    assert Command.write_inquiry_mode(1) == <<69, 12, 1, 1>>
  end

  test "write_local_name" do
    assert Command.write_local_name("Red Leader") ==
             <<19, 12, 248, 82, 101, 100, 32, 76, 101, 97, 100, 101, 114, 0::size(238)-unit(8)>>
  end

  test "write_page_timeout" do
    assert Command.write_page_timeout() == <<24, 12, 2, 0, 32>>
    assert Command.write_page_timeout(0x56) == <<24, 12, 2, 0, 86>>
  end

  test "write_secure_connections_host_support" do
    assert Command.write_secure_connections_host_support() == <<122, 12, 1, 0>>
    assert Command.write_secure_connections_host_support(true) == <<122, 12, 1, 1>>
  end

  test "write_simple_pairing_mode" do
    assert Command.write_simple_pairing_mode() == <<86, 12, 1, 0>>
    assert Command.write_simple_pairing_mode(true) == <<86, 12, 1, 1>>
  end

  test "create_connection" do
    assert Command.create_connection(peer_address: 1234) ==
             <<13, 32, 25, 128, 12, 64, 6, 0, 0, 210, 4, 0, 0, 0, 0, 0, 36, 0, 128, 12, 18, 0, 64,
               6, 6, 0, 84, 0>>
  end

  test "read_local_version_information" do
    assert Command.read_local_version_information() == <<1, 16, 0, 0>>
  end
end
