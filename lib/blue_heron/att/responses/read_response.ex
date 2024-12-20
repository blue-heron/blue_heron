defmodule BlueHeron.ATT.ReadResponse do
  @moduledoc """
  > The ATT_READ_RSP PDU is sent in reply to a received Read Request and contains
  > the value of the attribute that has been read.

  Bluetooth Spec v5.2, vol 3, Part F, 3.4.4.4
  """

  defstruct [:opcode, :value]

  def serialize(%{value: value}) do
    <<0x0B, value::binary>>
  end

  def deserialize(<<0x0B, value::binary>>) do
    %__MODULE__{opcode: 0x0B, value: value}
  end
end
