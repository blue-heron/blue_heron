defmodule BlueHeron.L2Cap.Signaling do
  defstruct [:code, :identifier, :data]

  alias BlueHeron.L2Cap

  alias BlueHeron.L2Cap.Signaling.{
    CommandRejectResponse,
    ConnectionParameterUpdateRequest,
    ConnectionParameterUpdateResponse
  }

  # CommandRejectResponse valid for channel 1 and 5
  def deserialize(%L2Cap{} = l2cap, <<0x1, _::binary>> = command_reject_response) do
    %{l2cap | data: CommandRejectResponse.deserialize(command_reject_response)}
  end

  # ConnectionParameterUpdateRequest valid for channel 5
  def deserialize(
        %L2Cap{cid: 0x5} = l2cap,
        <<0x12, _::binary>> = connection_parameter_update_request
      ) do
    %{
      l2cap
      | data: ConnectionParameterUpdateRequest.deserialize(connection_parameter_update_request)
    }
  end

  # ConnectionParameterUpdateResponse valid for channel 5
  def deserialize(
        %L2Cap{cid: 0x5} = l2cap,
        <<0x13, _::binary>> = connection_parameter_update_response
      ) do
    %{
      l2cap
      | data: ConnectionParameterUpdateResponse.deserialize(connection_parameter_update_response)
    }
  end

  def deserialize(
        %L2Cap{cid: 0x1} = l2cap,
        <<code, identifier, length::little-16, data::binary-size(length)>>
      ) do
    %{l2cap | data: %__MODULE__{code: code, identifier: identifier, data: data}}
  end

  def deserialize(
        %L2Cap{cid: 0x5} = l2cap,
        <<code, identifier, length::little-16, data::binary-size(length)>>
      ) do
    %{l2cap | data: %__MODULE__{code: code, identifier: identifier, data: data}}
  end

  @doc "Takes a struct and returns binary data"
  def serialize(%__MODULE__{code: code, identifier: identifier, data: data}) do
    length = byte_size(data)
    <<code, identifier, length::little-16, data::binary-size(length)>>
  end

  def serialize(%type{} = data), do: type.serialize(data)
end
