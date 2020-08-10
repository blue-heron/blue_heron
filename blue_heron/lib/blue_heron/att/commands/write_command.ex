defmodule BlueHeron.ATT.WriteCommand do
  defstruct [:opcode, :handle, :data]

  def deserialize(<<0x52, handle::little-16, data::binary>>) do
    %__MODULE__{opcode: 0x52, handle: handle, data: data}
  end

  def serialize(%{data: %type{} = data} = write_command) do
    serialize(%{write_command | data: type.serialize(data)})
  end

  def serialize(%{handle: handle, data: data}) do
    <<0x52::8, handle::little-16, data::binary>>
  end
end
