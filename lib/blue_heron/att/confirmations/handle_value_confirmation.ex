defmodule BlueHeron.ATT.HandleValueConfirmation do
  @moduledoc """
  > The ATT_HANDLE_VALUE_CFM PDU is sent in response to a received
  > ATT_HANDLE_VALUE_IND PDU and confirms that the client has received an indication
  > of the given attribute.

  Bluetooth Spec v5.2, vol 3, Part F, 3.4.7.3
  """

  defstruct [:opcode]

  def serialize(%{}) do
    <<0x1E>>
  end

  def deserialize(<<0x1E>>) do
    %__MODULE__{opcode: 0x1E}
  end
end
