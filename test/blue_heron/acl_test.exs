# SPDX-FileCopyrightText: 2021 Troels Brødsgaard
# SPDX-FileCopyrightText: 2023 Connor Rigby
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule BlueHeron.ACLTest do
  use ExUnit.Case

  alias BlueHeron.{ACL, ATT, L2Cap}
  alias BlueHeron.ATT.HandleValueNotification

  test "encodes packet correctly" do
    serialized =
      %ACL{
        data: %L2Cap{
          cid: 4,
          data: %ATT.ExchangeMTURequest{client_rx_mtu: 185, opcode: 2}
        },
        flags: %{bc: 2, pb: 0},
        handle: 64
      }
      |> ACL.serialize()

    assert <<64, 128, 7, 0, 3, 0, 4, 0, 2, 185, 0>> == serialized
  end

  test "serde is symmetric" do
    handle = Enum.random(0x001..0xEFF)
    pb = Enum.random(0b00..0b11)
    bc = Enum.random(0b00..0b11)

    expected = %ACL{
      flags: %{bc: bc, pb: pb},
      handle: handle,
      data: %L2Cap{
        cid: 4,
        data: %ATT.ExchangeMTURequest{client_rx_mtu: 185, opcode: 2}
      }
    }

    assert expected == expected |> ACL.serialize() |> ACL.deserialize()
  end

  test "fragments L2CAP payloads by ACL data packet length" do
    value = :binary.copy(<<0xAA>>, 491)

    acl = %ACL{
      handle: 0x0040,
      flags: %{bc: 0, pb: 0},
      data: %L2Cap{
        cid: 0x0004,
        data: %HandleValueNotification{handle: 0x0025, data: value}
      }
    }

    assert [first, second] = ACL.fragment(acl, 251)

    # PB=0b10 on the first fragment, PB=0b01 on the continuation (BT Core
    # 5.4 Vol 4 Part E §5.4.2 — required on LE links).
    assert first.handle == acl.handle
    assert first.flags == %{bc: 0, pb: 2}
    assert byte_size(first.data) == 251

    assert second.handle == acl.handle
    assert second.flags == %{bc: 0, pb: 1}
    assert byte_size(second.data) == 247

    assert <<494::little-16, 0x0004::little-16, 0x1B, 0x0025::little-16, _::binary>> =
             first.data
  end

  test "keeps L2CAP payloads within ACL data packet length as one packet" do
    value = :binary.copy(<<0xAA>>, 197)

    acl = %ACL{
      handle: 0x0040,
      flags: %{bc: 0, pb: 0},
      data: %L2Cap{
        cid: 0x0004,
        data: %HandleValueNotification{handle: 0x0025, data: value}
      }
    }

    assert [packet] = ACL.fragment(acl, 251)
    assert packet.flags == %{bc: 0, pb: 0}
    assert byte_size(packet.data) == 204
  end
end
