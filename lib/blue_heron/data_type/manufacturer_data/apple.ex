defmodule BlueHeron.DataType.ManufacturerData.Apple do
  @moduledoc """
  Serialization module for Apple.

  ## iBeacon

  Reference: https://en.wikipedia.org/wiki/IBeacon#Packet_Structure_Byte_Map
  """

  alias BlueHeron.ManufacturerDataBehaviour

  @behaviour ManufacturerDataBehaviour

  @ibeacon_name "iBeacon"

  @ibeacon_identifier 0x02

  @ibeacon_length 0x15

  @doc """
  Returns the Company Identifier description associated with this module.

      iex> company()
      "Apple, Inc."
  """
  @impl ManufacturerDataBehaviour
  def company, do: "Apple, Inc."

  @doc """
  Returns the iBeacon identifier.

      iex> ibeacon_identifier()
      0x02
  """
  def ibeacon_identifier, do: @ibeacon_identifier

  @doc """
  Returns the length of the data following the length byte.

      iex> ibeacon_length()
      0x15
  """
  def ibeacon_length, do: @ibeacon_length

  @doc """
      iex> serialize({"iBeacon", %{major: 1, minor: 2, tx_power: 3, uuid: 4}})
      {:ok, <<2, 21, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 0, 1, 0, 2, 3>>}

      iex> serialize({"iBeacon", %{major: 1, minor: 2, tx_power: 3}})
      :error

      iex> serialize(false)
      :error
  """
  def serialize(
        {@ibeacon_name,
         %{
           major: major,
           minor: minor,
           tx_power: tx_power,
           uuid: uuid
         }}
      ) do
    binary = <<
      @ibeacon_identifier,
      @ibeacon_length,
      uuid::size(128),
      major::size(16),
      minor::size(16),
      tx_power
    >>

    {:ok, binary}
  end

  def serialize(_), do: :error

  @doc """
      iex> deserialize(<<2, 21, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 0, 1, 0, 2, 3>>)
      {:ok, {"iBeacon", %{major: 1, minor: 2, tx_power: 3, uuid: 4}}}

      iex> deserialize(<<2, 21, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 0, 1, 0, 2>>)
      {:error, <<2, 21, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 0, 1, 0, 2>>}
  """
  def deserialize(<<@ibeacon_identifier, @ibeacon_length, binary::binary-size(21)>>) do
    <<
      uuid::size(128),
      major::size(16),
      minor::size(16),
      tx_power
    >> = binary

    data = %{
      major: major,
      minor: minor,
      tx_power: tx_power,
      uuid: uuid
    }

    {:ok, {"iBeacon", data}}
  end

  def deserialize(bin) when is_binary(bin), do: {:error, bin}
end
