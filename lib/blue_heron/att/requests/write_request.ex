defmodule BlueHeron.ATT.WriteRequest do
  defstruct [:opcode, :handle, :value]

  def serialize(%{handle: handle, value: value}) do
    <<0x12, handle::little-16, value::binary>>
  end

  def deserialize(<<0x12, handle::little-16, value::binary>>) do
    %__MODULE__{opcode: 0x12, handle: handle, value: value}
  end
end
