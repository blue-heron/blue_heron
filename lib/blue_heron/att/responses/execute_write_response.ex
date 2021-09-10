defmodule BlueHeron.ATT.ExecuteWriteResponse do
  defstruct [:opcode]

  def serialize(%{}) do
    <<0x19>>
  end

  def deserialize(<<0x19>>) do
    %__MODULE__{opcode: 0x19}
  end
end
