# SPDX-FileCopyrightText: 2021 Troels Brødsgaard
# SPDX-FileCopyrightText: 2023 Connor Rigby
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule BlueHeron.ACLTest do
  use ExUnit.Case

  alias BlueHeron.{ACL, ATT, L2Cap}

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

    assert <<64, 2, 7, 0, 3, 0, 4, 0, 2, 185, 0>> == serialized
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
end
