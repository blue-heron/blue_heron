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
    ExecuteWriteRequest,
    ExecuteWriteResponse,
    FindInformationRequest,
    FindInformationResponse,
    PrepareWriteRequest,
    PrepareWriteResponse,
    ReadBlobRequest,
    ReadBlobResponse,
    ReadByTypeRequest,
    ReadByTypeResponse,
    ReadByGroupTypeRequest,
    ReadByGroupTypeResponse,
    ReadRequest,
    ReadResponse,
    HandleValueNotification,
    WriteCommand,
    WriteRequest,
    WriteResponse
  }

  @doc "Takes binary data and returns a struct"
  def deserialize(base, <<0x01, _::binary>> = error_response),
    do: %{base | data: ErrorResponse.deserialize(error_response)}

  def deserialize(base, <<0x02, _::binary>> = exchange_mtu_request),
    do: %{base | data: ExchangeMTURequest.deserialize(exchange_mtu_request)}

  def deserialize(base, <<0x03, _::binary>> = exchange_mtu_request),
    do: %{base | data: ExchangeMTUResponse.deserialize(exchange_mtu_request)}

  def deserialize(base, <<0x04, _::binary>> = find_information_request),
    do: %{base | data: FindInformationRequest.deserialize(find_information_request)}

  def deserialize(base, <<0x05, _::binary>> = find_information_response),
    do: %{base | data: FindInformationResponse.deserialize(find_information_response)}

  def deserialize(base, <<0x08, _::binary>> = exchange_mtu_request),
    do: %{base | data: ReadByTypeRequest.deserialize(exchange_mtu_request)}

  def deserialize(base, <<0x09, _::binary>> = exchange_mtu_request),
    do: %{base | data: ReadByTypeResponse.deserialize(exchange_mtu_request)}

  def deserialize(base, <<0x0A, _::binary>> = read_request),
    do: %{base | data: ReadRequest.deserialize(read_request)}

  def deserialize(base, <<0x0B, _::binary>> = read_response),
    do: %{base | data: ReadResponse.deserialize(read_response)}

  def deserialize(base, <<0x0C, _::binary>> = read_blob_request),
    do: %{base | data: ReadBlobRequest.deserialize(read_blob_request)}

  def deserialize(base, <<0x0D, _::binary>> = read_blob_response),
    do: %{base | data: ReadBlobResponse.deserialize(read_blob_response)}

  def deserialize(base, <<0x10, _::binary>> = read_by_group_type_request),
    do: %{base | data: ReadByGroupTypeRequest.deserialize(read_by_group_type_request)}

  def deserialize(base, <<0x11, _::binary>> = read_by_group_type_request),
    do: %{base | data: ReadByGroupTypeResponse.deserialize(read_by_group_type_request)}

  def deserialize(base, <<0x12, _::binary>> = write_request),
    do: %{base | data: WriteRequest.deserialize(write_request)}

  def deserialize(base, <<0x13, _::binary>> = write_response),
    do: %{base | data: WriteResponse.deserialize(write_response)}

  def deserialize(base, <<0x16, _::binary>> = prepare_write_request),
    do: %{base | data: PrepareWriteRequest.deserialize(prepare_write_request)}

  def deserialize(base, <<0x17, _::binary>> = prepare_write_response),
    do: %{base | data: PrepareWriteResponse.deserialize(prepare_write_response)}

  def deserialize(base, <<0x18, _::binary>> = execute_write_request),
    do: %{base | data: ExecuteWriteRequest.deserialize(execute_write_request)}

  def deserialize(base, <<0x19, _::binary>> = execute_write_response),
    do: %{base | data: ExecuteWriteResponse.deserialize(execute_write_response)}

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
