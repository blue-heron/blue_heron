defmodule BlueHeron.ATT.PrepareWriteRequest do
  defstruct [:opcode, :handle, :offset, :value]

  def serialize(%{handle: handle, offset: offset, value: value}) do
    <<0x16, handle::little-16, offset::little-16, value::binary>>
  end

  def deserialize(<<0x16, handle::little-16, offset::little-16, value::binary>>) do
    %__MODULE__{opcode: 0x16, handle: handle, offset: offset, value: value}
  end
end
