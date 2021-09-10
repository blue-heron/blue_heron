defmodule BlueHeron.ATT.ExecuteWriteRequest do
  defstruct [:opcode, :flags]

  def serialize(%{flags: flags}) do
    <<0x18, flags>>
  end

  def deserialize(<<0x18, flags>>) do
    %__MODULE__{opcode: 0x18, flags: flags}
  end
end
