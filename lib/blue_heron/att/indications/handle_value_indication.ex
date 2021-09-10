defmodule BlueHeron.ATT.HandleValueIndication do
  defstruct [:opcode, :handle, :value]

  def serialize(%{handle: handle, value: value}) do
    <<0x1D, handle::little-16, value::binary>>
  end

  def deserialize(<<0x1D, handle::little-16, value::binary>>) do
    %__MODULE__{
      opcode: 0x1D,
      handle: handle,
      value: value
    }
  end
end
