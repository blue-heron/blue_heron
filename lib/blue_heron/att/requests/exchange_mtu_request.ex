defmodule BlueHeron.ATT.ExchangeMTURequest do
  defstruct [:opcode, :client_rx_mtu]

  @type t() :: %__MODULE__{client_rx_mtu: non_neg_integer()}

  def serialize(emtu) do
    <<0x02, emtu.client_rx_mtu::little-16>>
  end

  def deserialize(<<0x02, client_rx_mtu::little-16>>) do
    %__MODULE__{opcode: 0x02, client_rx_mtu: client_rx_mtu}
  end
end
