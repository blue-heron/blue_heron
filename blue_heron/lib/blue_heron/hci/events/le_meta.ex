defmodule BlueHeron.HCI.Event.LEMeta do
  @moduledoc """
  The LE Meta Event is used to encapsulate all LE Controller specific events.

  Reference: Version 5.2, Vol 4, Part E, 7.7.65
  """

  @typedoc """
  > An LE Controller uses subevent codes to transmit LE specific events from the Controller to the
  > Host. Note: The subevent code will always be the first Event Parameter (See Section 7.7.65).

  Reference: Version 5.2, Vol 4, Part E, 5.4.4
  """
  @type subevent_code :: 1..255

  @behaviour BlueHeron.HCI.Event

  defstruct [
    :subevent_code,
    :data
  ]

  alias BlueHeron.HCI.Event.LEMeta.{
    AdvertisingReport,
    ConnectionComplete
  }

  @impl BlueHeron.HCI.Event
  def serialize(%__MODULE__{data: %type{} = data} = event) do
    serialize(%__MODULE__{event | data: type.serialize(data)})
  end

  def serialize(%__MODULE__{subevent_code: subevent_code, data: data}) when is_binary(data) do
    <<subevent_code::8, data::binary>>
  end

  @impl BlueHeron.HCI.Event
  def deserialize(<<0x1, data::binary>>) do
    %__MODULE__{subevent_code: 0x1, data: ConnectionComplete.deserialize(data)}
  end

  def deserialize(<<0x2, data::binary>>) do
    %__MODULE__{subevent_code: 0x2, data: AdvertisingReport.deserialize(data)}
  end

  def deserialize(<<subevent_code::8, data::binary>>) do
    %__MODULE__{subevent_code: subevent_code, data: data}
  end
end
