defmodule BlueHeron.ATT.ReadRequest do
  defstruct [:opcode, :handle]

  def serialize(%{handle: handle}) do
    <<0x0A, handle::little-16>>
  end

  def deserialize(<<0x0A, handle::little-16>>) do
    %__MODULE__{opcode: 0x0A, handle: handle}
  end
end
