defmodule BlueHeron.ATT.ErrorResponse do
  @moduledoc """
  > The ATT_ERROR_RSP PDU is used to state that a given request cannot be performed,
  > and to provide the reason.

  Bluetooth Spec v5.2, vol 3, Part F, 3.4.1.1
  """

  defstruct [:opcode, :request_opcode, :handle, :error]

  def serialize(%{request_opcode: request_opcode, handle: handle, error: error}) do
    <<0x01, request_opcode, handle::little-16, serialize_error(error)>>
  end

  defp serialize_error(:insufficient_authentication), do: 0x05
  defp serialize_error(:attribute_not_found), do: 0x0A

  def deserialize(<<0x01, request_opcode, handle::little-16, error>>) do
    %__MODULE__{
      opcode: 0x01,
      request_opcode: request_opcode,
      handle: handle,
      error: deserialize_error(error)
    }
  end

  defp deserialize_error(0x05), do: :insufficient_authentication
  defp deserialize_error(0x0A), do: :attribute_not_found
  defp deserialize_error(code), do: code
end
