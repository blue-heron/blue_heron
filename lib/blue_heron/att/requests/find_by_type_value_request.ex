defmodule BlueHeron.ATT.FindByTypeValueRequest do
  defstruct [:opcode, :starting_handle, :ending_handle, :attribute_type, :attribute_value]

  def serialize(%{
        starting_handle: starting_handle,
        ending_handle: ending_handle,
        attribute_type: attribute_type,
        attribute_value: attribute_value
      }) do
    <<0x06, starting_handle::little-16, ending_handle::little-16, attribute_type::little-16,
      attribute_value::binary>>
  end

  def deserialize(
        <<0x06, starting_handle::little-16, ending_handle::little-16, attribute_type::little-16,
          attribute_value::binary>>
      ) do
    %__MODULE__{
      opcode: 0x06,
      starting_handle: starting_handle,
      ending_handle: ending_handle,
      attribute_type: attribute_type,
      attribute_value: attribute_value
    }
  end
end
