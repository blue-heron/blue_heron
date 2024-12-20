defmodule BlueHeron.ATT.HandleValueIndication do
  @moduledoc """
  > A server can send a notification of an attribute’s value at any time.

  Bluetooth Spec v5.2, vol 3, Part F, 3.4.7.2
  """

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
