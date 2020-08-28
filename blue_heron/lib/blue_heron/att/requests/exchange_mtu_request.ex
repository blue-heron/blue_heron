defmodule BlueHeron.ATT.ExchageMTURequest do
  defstruct [:opcode, :client_rx_mtu]

  def serialize(emtu) do
    <<0x02::8, emtu.client_rx_mtu::little-16>>
  end

  def deserialize(<<0x02::8, client_rx_mtu::little-16>>) do
    %__MODULE__{opcode: 0x02, client_rx_mtu: client_rx_mtu}
  end
end
