defmodule BlueHeron.ATT.FindInformationRequest do
  defstruct [:opcode, :starting_handle, :ending_handle]

  def serialize(%{starting_handle: starting_handle, ending_handle: ending_handle}) do
    <<0x04, starting_handle::little-16, ending_handle::little-16>>
  end

  def deserialize(<<0x04, starting_handle::little-16, ending_handle::little-16>>) do
    %__MODULE__{opcode: 0x04, starting_handle: starting_handle, ending_handle: ending_handle}
  end
end
