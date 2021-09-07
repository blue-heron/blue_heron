defmodule BlueHeron.ATT.ReadBlobRequest do
  defstruct [:opcode, :handle, :offset]

  def serialize(%{handle: handle, offset: offset}) do
    <<0x0C, handle::little-16, offset::little-16>>
  end

  def deserialize(<<0x0C, handle::little-16, offset::little-16>>) do
    %__MODULE__{
      opcode: 0x0C,
      handle: handle,
      offset: offset
    }
  end
end
