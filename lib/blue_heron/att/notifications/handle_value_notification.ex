defmodule BlueHeron.ATT.HandleValueNotification do
  @moduledoc """
  > A server can send a notification of an attribute’s value at any time.

  Bluetooth Spec v5.2, vol 3, Part F, 3.4.7.1
  """

  defstruct [:opcode, :handle, :data]

  @type t() :: %__MODULE__{handle: non_neg_integer(), data: binary()}

  def deserialize(<<0x1B, handle::little-16, data::binary>>) do
    %__MODULE__{opcode: 0x1B, handle: handle, data: data}
  end

  def serialize(%{data: %type{} = data} = write_command) do
    serialize(%{write_command | data: type.serialize(data)})
  end

  def serialize(%{handle: handle, data: data}) do
    <<0x1B, handle::little-16, data::binary>>
  end
end
