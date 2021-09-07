defmodule BlueHeron.ATT.WriteResponse do
  defstruct [:opcode]

  def serialize(%{}) do
    <<0x13>>
  end

  def deserialize(<<0x13>>) do
    %__MODULE__{opcode: 0x13}
  end
end
