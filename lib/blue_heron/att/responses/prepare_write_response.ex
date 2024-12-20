defmodule BlueHeron.ATT.PrepareWriteResponse do
  @moduledoc """
  > The ATT_PREPARE_WRITE_RSP PDU is sent in response to a received
  > ATT_PREPARE_WRITE_REQ PDU and acknowledges that the value has been
  > successfully received and placed in the prepare write queue.

  Bluetooth Spec v5.2, vol 3, Part F, 3.4.6.2
  """

  defstruct [:opcode, :handle, :offset, :value]

  def serialize(%{handle: handle, offset: offset, value: value}) do
    <<0x17, handle::little-16, offset::little-16, value::binary>>
  end

  def deserialize(<<0x17, handle::little-16, offset::little-16, value::binary>>) do
    %__MODULE__{opcode: 0x17, handle: handle, offset: offset, value: value}
  end
end
