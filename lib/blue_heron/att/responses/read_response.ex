defmodule BlueHeron.ATT.ReadResponse do
  defstruct [:opcode, :value]

  def serialize(%{value: value}) do
    <<0x0B, value::binary>>
  end

  def deserialize(<<0x0B, value::binary>>) do
    %__MODULE__{opcode: 0x0B, value: value}
  end
end
