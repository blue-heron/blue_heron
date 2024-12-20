defmodule BlueHeron.ATT.ExchangeMTURequest do
  @moduledoc """
  > The ATT_EXCHANGE_MTU_REQ PDU is used by the client to inform the server of the
  > client’s maximum receive MTU size and request the server to respond with its maximum
  > receive MTU size.

  Bluetooth Spec v5.2, vol 3, Part F, 3.4.2.1
  """

  defstruct [:opcode, :client_rx_mtu]

  @type t() :: %__MODULE__{client_rx_mtu: non_neg_integer()}

  def serialize(emtu) do
    <<0x02, emtu.client_rx_mtu::little-16>>
  end

  def deserialize(<<0x02, client_rx_mtu::little-16>>) do
    %__MODULE__{opcode: 0x02, client_rx_mtu: client_rx_mtu}
  end
end
