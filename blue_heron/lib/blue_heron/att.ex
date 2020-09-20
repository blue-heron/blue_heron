defmodule BlueHeron.ATT do
  @moduledoc """
  Functions for serializing and deserializing ATT data
  """

  # this is missing the flags. Opcodes will be wrong. Sorry.
  defstruct [:opcode, :args]

  alias BlueHeron.ATT.{
    ErrorResponse,
    ExchangeMTURequest,
    ExchangeMTUResponse,
    ReadByTypeRequest,
    ReadByTypeResponse,
    ReadByGroupTypeRequest,
    ReadByGroupTypeResponse,
    HandleValueNotification,
    WriteCommand
  }

  @doc "Takes binary data and returns a struct"
  def deserialize(base, <<0x01, _::binary>> = error_response),
    do: %{base | data: ErrorResponse.deserialize(error_response)}

  def deserialize(base, <<0x02, _::binary>> = exchange_mtu_request),
    do: %{base | data: ExchangeMTURequest.deserialize(exchange_mtu_request)}

  def deserialize(base, <<0x03, _::binary>> = exchange_mtu_request),
    do: %{base | data: ExchangeMTUResponse.deserialize(exchange_mtu_request)}

  def deserialize(base, <<0x08, _::binary>> = exchange_mtu_request),
    do: %{base | data: ReadByTypeRequest.deserialize(exchange_mtu_request)}

  def deserialize(base, <<0x09, _::binary>> = exchange_mtu_request),
    do: %{base | data: ReadByTypeResponse.deserialize(exchange_mtu_request)}

  def deserialize(base, <<0x10, _::binary>> = read_by_group_type_request),
    do: %{base | data: ReadByGroupTypeRequest.deserialize(read_by_group_type_request)}

  def deserialize(base, <<0x11, _::binary>> = read_by_group_type_request),
    do: %{base | data: ReadByGroupTypeResponse.deserialize(read_by_group_type_request)}

  def deserialize(base, <<0x1B, _::binary>> = read_by_group_type_request),
    do: %{base | data: HandleValueNotification.deserialize(read_by_group_type_request)}

  def deserialize(base, <<0x52, _::binary>> = read_by_group_type_request),
    do: %{base | data: WriteCommand.deserialize(read_by_group_type_request)}

  def deserialize(base, <<opcode, args::binary>>),
    do: %{base | data: %__MODULE__{opcode: opcode, args: args}}

  @doc "Takes a struct and returns binary data"
  def serialize(%__MODULE__{opcode: opcode, args: args}) do
    <<opcode, args::binary>>
  end

  def serialize(%type{} = data), do: type.serialize(data)
end
