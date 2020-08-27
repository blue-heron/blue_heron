defmodule Bluetooth.ATT.ExchageMTUResponse do
  defstruct [:opcode, :server_rx_mtu]

  def serialize(emtu) do
    <<0x03::8, emtu.server_rx_mtu::little-16>>
  end

  def deserialize(<<0x03::8, server_rx_mtu::little-16>>) do
    %__MODULE__{opcode: 0x03, server_rx_mtu: server_rx_mtu}
  end
end
