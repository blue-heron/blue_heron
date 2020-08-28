defmodule BlueHeron.HCIDumpTest do
  use ExUnit.Case
  alias BlueHeron.{HCIDump, HCIDump.PKTLOG}

  test "encode/decode" do
    packet = %PKTLOG{
      tv_sec: 1_597_101_555,
      tv_us: 500,
      type: :LOG_MESSAGE_PACKET,
      payload: "hello, world!"
    }

    assert [^packet] = HCIDump.encode(packet, :out) |> HCIDump.decode_bin([])
  end
end
