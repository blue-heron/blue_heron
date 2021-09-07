defmodule BlueHeron.ATT.ReadBlobResponse do
  defstruct [:opcode, :value]

  def serialize(%{value: value}) do
    <<0x0D, value::binary>>
  end

  def deserialize(<<0x0D, value::binary>>) do
    %__MODULE__{opcode: 0x0D, value: value}
  end
end
