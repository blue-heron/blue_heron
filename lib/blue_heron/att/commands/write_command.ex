defmodule BlueHeron.ATT.WriteCommand do
  @moduledoc """
  > The ATT_WRITE_CMD PDU is used to request the server to write the value of an
  > attribute, typically into a control-point attribute.

  Bluetooth Spec v5.2, vol 3, Part F, 3.4.5.3
  """

  defstruct [:opcode, :handle, :data]

  def deserialize(<<0x52, handle::little-16, data::binary>>) do
    %__MODULE__{opcode: 0x52, handle: handle, data: data}
  end

  def serialize(%{data: %type{} = data} = write_command) do
    serialize(%{write_command | data: type.serialize(data)})
  end

  def serialize(%{handle: handle, data: data}) do
    <<0x52, handle::little-16, data::binary>>
  end
end
