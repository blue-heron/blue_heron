defmodule BlueHeron.HCI.Event do
  @callback deserialize(binary()) :: struct() | binary()
  @callback serialize(struct()) :: binary()

  alias BlueHeron.HCI.Event.{
    CommandComplete,
    CommandStatus,
    DisconnectionComplete,
    InquiryComplete,
    LEMeta
  }

  defstruct [:event_code, :data]

  def deserialize(<<0x01, data_length::8, data::binary-size(data_length)>>) do
    %__MODULE__{event_code: 0x01, data: InquiryComplete.deserialize(data)}
  end

  def deserialize(<<0x05, data_length::8, data::binary-size(data_length)>>) do
    %__MODULE__{event_code: 0x05, data: DisconnectionComplete.deserialize(data)}
  end

  def deserialize(<<0x0E, data_length::8, data::binary-size(data_length)>>) do
    %__MODULE__{event_code: 0x0E, data: CommandComplete.deserialize(data)}
  end

  def deserialize(<<0x0F, data_length::8, data::binary-size(data_length)>>) do
    %__MODULE__{event_code: 0x0F, data: CommandStatus.deserialize(data)}
  end

  def deserialize(<<0x3E, data_length::8, data::binary-size(data_length)>>) do
    %__MODULE__{event_code: 0x3E, data: LEMeta.deserialize(data)}
  end

  def deserialize(<<event_code::8, data_length::8, data::binary-size(data_length)>>) do
    %__MODULE__{event_code: event_code, data: data}
  end

  def serialize(%__MODULE__{data: %type{} = data} = event) do
    serialize(%__MODULE__{event | data: type.serialize(data)})
  end

  def serialize(%__MODULE__{event_code: event_code, data: data}) when is_binary(data) do
    data_length = byte_size(data)
    <<event_code::8, data_length::8, data::binary-size(data_length)>>
  end
end
