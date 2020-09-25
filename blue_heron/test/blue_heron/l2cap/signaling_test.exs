defmodule BlueHeron.L2Cap.SignalingTest do
  use ExUnit.Case
  alias BlueHeron.{L2Cap, L2Cap.Signaling}

  test "L2CAP_CONNECTION_PARAMETER_UPDATE_REQ" do
    alias Signaling.ConnectionParameterUpdateRequest
    packet = <<0x12, 0xC8, 0x8, 0x0, 0x8, 0x0, 0x10, 0x0, 0x0, 0x0, 0x7D, 0x0>>
    l2cap = Signaling.deserialize(%L2Cap{cid: 5}, packet)

    assert l2cap.data == %ConnectionParameterUpdateRequest{
             code: 18,
             identifier: 200,
             interval_max: 16,
             interval_min: 8,
             slave_latency: 0,
             timeout_multiplier: 125
           }

    assert Signaling.serialize(l2cap.data) == packet
  end
end
