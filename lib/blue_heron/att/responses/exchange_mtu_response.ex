# SPDX-FileCopyrightText: 2020 Connor Rigby
# SPDX-FileCopyrightText: 2020 Frank Hunleth
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule BlueHeron.ATT.ExchangeMTUResponse do
  @moduledoc """
  > The ATT_EXCHANGE_MTU_RSP PDU is sent in reply to a received
  > ATT_EXCHANGE_MTU_REQ PDU.

  Bluetooth Spec v5.2, vol 3, Part F, 3.4.2.2
  """

  defstruct [:opcode, :server_rx_mtu]

  def serialize(emtu) do
    <<0x03, emtu.server_rx_mtu::little-16>>
  end

  def deserialize(<<0x03, server_rx_mtu::little-16>>) do
    %__MODULE__{opcode: 0x03, server_rx_mtu: server_rx_mtu}
  end
end
