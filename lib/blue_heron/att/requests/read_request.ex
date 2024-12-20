defmodule BlueHeron.ATT.ReadRequest do
  @moduledoc """
  > The ATT_READ_REQ PDU is used to request the server to read the value of an
  > attribute and return its value in an ATT_READ_RSP PDU.

  Bluetooth Spec v5.2, vol 3, Part F, 3.4.4.3
  """

  defstruct [:opcode, :handle]

  def serialize(%{handle: handle}) do
    <<0x0A, handle::little-16>>
  end

  def deserialize(<<0x0A, handle::little-16>>) do
    %__MODULE__{opcode: 0x0A, handle: handle}
  end
end
