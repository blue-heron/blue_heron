defmodule BlueHeron.ATT.ErrorResponse do
  defstruct [:opcode, :request_opcode, :handle, :error]

  def serialize(%{request_opcode: request_opcode, handle: handle, error: error}) do
    <<0x01::8, request_opcode::8, handle::little-16, serialize_error(error)::8>>
  end

  defp serialize_error(:attribute_not_found), do: 0x0A

  def deserialize(<<0x01::8, request_opcode::8, handle::little-16, error::8>>) do
    %__MODULE__{
      opcode: 0x01,
      request_opcode: request_opcode,
      handle: handle,
      error: deserialize_error(error)
    }
  end

  defp deserialize_error(0x0A), do: :attribute_not_found
  defp deserialize_error(code), do: code
end
