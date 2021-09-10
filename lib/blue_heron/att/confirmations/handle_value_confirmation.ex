defmodule BlueHeron.ATT.HandleValueConfirmation do
  defstruct [:opcode]

  def serialize(%{}) do
    <<0x1E>>
  end

  def deserialize(<<0x1E>>) do
    %__MODULE__{opcode: 0x1E}
  end
end
